import 'dart:math' as math;

import 'package:electrical_core/src/algorithm_version.dart';
import 'package:electrical_core/src/calc/cable_calculator.dart';
import 'package:electrical_core/src/calc/circuit_builder.dart';
import 'package:electrical_core/src/calc/currents.dart';
import 'package:electrical_core/src/calc/demand_calculator.dart';
import 'package:electrical_core/src/calc/phase_balancer.dart';
import 'package:electrical_core/src/calc/protection_selector.dart';
import 'package:electrical_core/src/calc/tolerance.dart';
import 'package:electrical_core/src/model/enums.dart';
import 'package:electrical_core/src/model/project_input.dart';
import 'package:electrical_core/src/model/project_result.dart';
import 'package:norms_data/norms_data.dart';

/// Assumed loop impedance upstream of the panel when it is not measured, Ом.
///
/// Engineering assumption (typical maximum external loop impedance of urban TN-C-S and of
/// rural/overhead supplies); the result is marked «requires review» until a measured or
/// network-operator value is entered.
const Map<ObjectType, double> assumedExternalLoopImpedanceOhm = {
  ObjectType.apartment: 0.5,
  ObjectType.commercial: 0.5,
  ObjectType.house: 0.8,
  ObjectType.garageWorkshop: 0.8,
};

/// Rated residual current of the RCD for additional protection, mA.
const double additionalProtectionResidualMa = 30;

/// Fire-protection RCD at the input, mA (ПУЭ 7.1.84 recommendation; СП 256 А.4.2 selectivity).
const double fireRcdResidualMa = 300;

/// Leakage estimate, СП 256 А.1.2: 0,4 мА на 1 А тока нагрузки + 10 мкА на 1 м фазного проводника.
double leakageMa({required double designCurrentA, required double? lengthM}) =>
    0.4 * designCurrentA + 0.01 * (lengthM ?? 0);

/// Calculates the whole project. Pure and deterministic: the same input and data always give
/// the same result.
ProjectResult calculateProject(ProjectInput input, {NormsData? norms}) =>
    _ProjectCalculation(input, norms ?? NormsData.embedded).run();

final class _CircuitState(final CircuitDraft draft) {
  late double designA;
  late double demandA;
  late double cosPhi;
  late double startA;
  late double powerW;
  Phase? phase;
  ValueSource phaseSource = ValueSource.automatic;
  late ProtectionDevice device;
  late List<String> rcdReasons;
  late BreakerChoice breaker;
  late BreakerCurve curve;
  late CableEvaluation cable;
  String? rcdGroupId;
  final checks = <Check>[];
}

final class _ProjectCalculation(final ProjectInput input, final NormsData norms) {
  final CableCalculator cables = CableCalculator(norms);
  final issues = <Issue>[];
  final assumptions = <Assumption>[];
  late double u0;
  late double ul;

  ProjectResult run() {
    _resolveVoltage();
    final List<DeviceInput> devices = _validDevices();
    final List<CircuitDraft> drafts = buildCircuits(
      devices: devices,
      rooms: input.rooms,
      phaseVoltageV: u0,
      lineVoltageV: ul,
    );
    final List<_CircuitState> states = [for (final d in drafts) _currents(_CircuitState(d))];

    final PhaseBalanceResult? phaseBalance = _balance(states);
    final _Incomer incomer = _incomer(devices, states, phaseBalance);
    final _Panel panel = _panelUpstream(incomer);

    for (final s in states) {
      _protectionAndCable(s, panel);
    }
    final List<SharedRcdResult> sharedRcds = _groupRcds(states);
    final SharedRcdResult? fireRcd = _fireRcd(incomer, states);

    final List<CircuitResult> circuits = [
      for (var i = 0; i < states.length; i++) _circuitResult(states[i], i + 1, panel.assumedZext),
    ];
    final IncomerResult incomerResult = incomer.result(panel);

    return ProjectResult(
      algorithmVersion: algorithmVersion,
      datasetVersions: norms.datasetVersions,
      phaseVoltageV: u0,
      lineVoltageV: ul,
      circuits: circuits,
      sharedRcds: sharedRcds,
      fireRcd: fireRcd,
      phaseBalance: phaseBalance,
      incomer: incomerResult,
      issues: issues,
      assumptions: assumptions,
      status: _projectStatus(circuits, incomerResult),
    );
  }

  void _resolveVoltage() {
    NominalVoltage? voltage = norms.constants.voltageOptions
        .where((v) => v.id == input.nominalVoltageId)
        .firstOrNull;
    if (voltage == null) {
      voltage = norms.constants.voltage(ProjectInput.defaultNominalVoltageId);
      issues.add(
        Issue(
          severity: IssueSeverity.warning,
          code: 'unknown_voltage',
          message: 'Неизвестный вариант напряжения «${input.nominalVoltageId}», принято 220/380 В',
        ),
      );
    }
    u0 = voltage.phaseV;
    ul = voltage.lineV;
    assumptions.add(
      Assumption(
        code: 'nominal_voltage',
        message: 'Номинальное напряжение ${fmt(u0, 0)}/${fmt(ul, 0)} В (СП 256, п. 8.23)',
      ),
    );
  }

  List<DeviceInput> _validDevices() {
    final Set<String> roomIds = {for (final r in input.rooms) r.id};
    final seen = <String>{};
    final valid = <DeviceInput>[];
    void reject(DeviceInput d, String code, String message) => issues.add(
      Issue(
        severity: IssueSeverity.error,
        code: code,
        message: '${d.name}: $message',
        deviceId: d.id,
      ),
    );
    for (final DeviceInput d in input.devices) {
      if (!seen.add(d.id)) {
        reject(d, 'duplicate_device_id', 'повторяющийся идентификатор прибора');
      } else if (!roomIds.contains(d.roomId)) {
        reject(d, 'unknown_room', 'прибор не привязан к существующему помещению');
      } else if (d.powerW <= 0 || d.quantity < 1) {
        reject(d, 'invalid_power', 'мощность и количество должны быть больше нуля');
      } else if (d.phases != 1 && d.phases != 3) {
        reject(d, 'invalid_phases', 'число фаз должно быть 1 или 3');
      } else if (d.cosPhi < 0.1 ||
          d.cosPhi > 1 ||
          d.usageFactor < 0 ||
          d.usageFactor > 1 ||
          d.inrushMultiple < 1) {
        reject(
          d,
          'invalid_parameters',
          'cos φ должен быть в пределах 0,1…1, ku — 0…1, кратность пуска — не менее 1',
        );
      } else if (d.phases == 3 && input.supplyPhases == SupplyPhases.single) {
        reject(
          d,
          'three_phase_device_on_single_phase_supply',
          'трёхфазный приёмник нельзя подключить к однофазному вводу',
        );
      } else {
        valid.add(d);
      }
    }
    return valid;
  }

  _CircuitState _currents(_CircuitState s) {
    CurrentVector design = CurrentVector.zero;
    CurrentVector demand = CurrentVector.zero;
    var extraStart = 0.0;
    for (final DeviceInput d in s.draft.devices) {
      final CurrentVector i = deviceCurrent(d, phaseVoltageV: u0, lineVoltageV: ul);
      design += i;
      demand += deviceCurrent(d, phaseVoltageV: u0, lineVoltageV: ul, demand: true);
      extraStart = math.max(extraStart, (d.inrushMultiple - 1) * i.magnitudeA);
    }
    s
      ..designA = design.magnitudeA
      ..demandA = demand.magnitudeA
      ..cosPhi = design.cosPhi
      ..startA = design.magnitudeA + extraStart
      ..powerW = s.draft.devices.fold<double>(0, (sum, d) => sum + d.totalPowerW);
    return s;
  }

  PhaseBalanceResult? _balance(List<_CircuitState> states) {
    if (input.supplyPhases == SupplyPhases.single) {
      for (final s in states) {
        s.phase = Phase.l1;
        if (input.circuitSettings[s.draft.id]?.phase != null) {
          issues.add(
            Issue(
              severity: IssueSeverity.info,
              code: 'phase_ignored',
              message: '${s.draft.name}: выбор фазы не применяется при однофазном вводе',
              circuitId: s.draft.id,
            ),
          );
        }
      }
      return null;
    }
    final base = <Phase, double>{for (final p in Phase.values) p: 0};
    final loads = <PhaseLoad>[];
    for (final s in states) {
      if (s.draft.phases == 3) {
        for (final Phase p in Phase.values) {
          base[p] = base[p]! + s.demandA;
        }
      } else {
        final Phase? manual = input.circuitSettings[s.draft.id]?.phase;
        loads.add(PhaseLoad(id: s.draft.id, currentA: s.demandA, fixedPhase: manual));
        if (manual != null) {
          s.phaseSource = ValueSource.manual;
        }
      }
    }
    final Map<String, Phase> assignment = balancePhases(loads, base: base);
    final Map<Phase, double> totals = {...base};
    for (final _CircuitState s in states.where((s) => s.draft.phases == 1)) {
      s.phase = assignment[s.draft.id];
      totals[s.phase!] = totals[s.phase!]! + s.demandA;
    }
    const limit = 30.0;
    final double imbalance = imbalancePercent(totals);
    if (imbalance > limit + epsilon) {
      issues.add(
        Issue(
          severity: IssueSeverity.warning,
          code: 'phase_imbalance',
          message: 'Разница токов фаз ${fmt(imbalance, 0)} % превышает 30 % (СП 256, п. 10.5)',
        ),
      );
    }
    return PhaseBalanceResult(loadsA: totals, imbalancePercent: imbalance, limitPercent: limit);
  }

  _Incomer _incomer(
    List<DeviceInput> devices,
    List<_CircuitState> states,
    PhaseBalanceResult? balance,
  ) {
    final double installed = devices.fold<double>(0, (s, d) => s + d.totalPowerW);
    final double byDevices = devices.fold<double>(0, (s, d) => s + d.totalPowerW * d.usageFactor);
    final NormativeDemand normative = normativeDemand(input, devices, norms);
    final bool residential =
        input.objectType == ObjectType.apartment || input.objectType == ObjectType.house;
    if (residential && input.supply.allowedPowerKw == null) {
      assumptions.add(
        const Assumption(
          code: 'declared_power_from_installed',
          message:
              'Разрешённая (заявленная) мощность не задана: коэффициент спроса по табл. 7.2 СП 256 '
              'применён к установленной мощности приборов, расчётная нагрузка ввода завышена.',
        ),
      );
    }
    final three = input.supplyPhases == SupplyPhases.three;

    double design = three
        ? normative.powerW / (math.sqrt(3) * ul * normative.cosPhi)
        : normative.powerW / (u0 * normative.cosPhi);
    if (three && balance != null) {
      final Iterable<double> loads = balance.loadsA.values;
      final double average = loads.fold<double>(0, (s, v) => s + v) / 3;
      if (average > epsilon) {
        // Design current of the most loaded phase: the normative load is distributed in
        // proportion to the expected phase loads (СП 256 табл. 7.1 assumes ≤ 15 % imbalance).
        design *= math.max(1, loads.reduce(math.max) / average);
      }
    }

    // The incomer must carry the largest single circuit (cf. СП 256 табл. 7.8, примечание 1).
    final double largestCircuit = states.isEmpty
        ? 0.0
        : states.map((s) => s.designA).reduce(math.max);
    if (largestCircuit > design) {
      design = largestCircuit;
    }

    final checks = <Check>[];
    final double? existing = input.supply.incomerBreakerA;
    final double? breaker = existing ?? norms.breakers.ratedCurrentAtOrAbove(design);
    if (breaker == null) {
      issues.add(
        Issue(
          severity: IssueSeverity.error,
          code: 'incomer_out_of_range',
          message:
              'Расчётный ток ввода ${fmt(design)} А больше максимального модульного автомата: '
              'нужен автомат в литом корпусе (вне рамок приложения)',
        ),
      );
    } else {
      final bool ok = lessOrEqual(design, breaker);
      checks.add(
        Check(
          code: CheckCode.loadVsBreaker,
          status: ok ? CheckStatus.passed : CheckStatus.failed,
          message: ok
              ? 'Iр = ${fmt(design)} А ≤ In = ${fmt(breaker, 0)} А'
              : 'Расчётный ток ввода ${fmt(design)} А больше номинала вводного автомата ${fmt(breaker, 0)} А',
          value: design,
          limit: breaker,
          reference: 'ГОСТ Р 50571.4.43, 433.1',
        ),
      );
      if (largestCircuit > breaker + epsilon) {
        issues.add(
          Issue(
            severity: IssueSeverity.warning,
            code: 'incomer_below_group',
            message: 'Вводной автомат ${fmt(breaker, 0)} А меньше расчётного тока одной из групп',
          ),
        );
      }
    }

    final double? allowed = input.supply.allowedPowerKw;
    if (allowed != null) {
      final bool ok = lessOrEqual(normative.powerW, allowed * 1000);
      checks.add(
        Check(
          code: CheckCode.allowedPower,
          status: ok ? CheckStatus.passed : CheckStatus.failed,
          message: ok
              ? 'Расчётная мощность ${fmt(normative.powerW / 1000, 2)} кВт ≤ разрешённой ${fmt(allowed, 2)} кВт'
              : 'Расчётная мощность ${fmt(normative.powerW / 1000, 2)} кВт больше разрешённой ${fmt(allowed, 2)} кВт',
          value: normative.powerW / 1000,
          limit: allowed,
          reference: 'технические условия на присоединение',
        ),
      );
      if (byDevices > allowed * 1000 + epsilon && ok) {
        issues.add(
          Issue(
            severity: IssueSeverity.info,
            code: 'demand_by_devices_exceeds_allowed',
            message:
                'Нагрузка «по приборам» ${fmt(byDevices / 1000, 2)} кВт больше разрешённой мощности: '
                'при одновременном включении сработает вводной автомат',
          ),
        );
      }
    }

    return _Incomer(
      installedW: installed,
      byDevicesW: byDevices,
      normative: normative,
      designA: design,
      breakerA: breaker,
      breakerSource: existing != null ? ValueSource.manual : ValueSource.automatic,
      checks: checks,
    );
  }

  _Panel _panelUpstream(_Incomer incomer) {
    final double? measured = input.supply.externalLoopImpedanceOhm;
    final double zExt = measured ?? assumedExternalLoopImpedanceOhm[input.objectType]!;
    if (measured == null) {
      assumptions.add(
        Assumption(
          code: 'assumed_external_loop_impedance',
          message:
              'Сопротивление петли «фаза — PE» до щита не задано, принято ${fmt(zExt, 2)} Ом. '
              'Проверка отключения при КЗ требует подтверждения замером или данными сетевой организации.',
        ),
      );
    }
    final CircuitSettings? cableSettings = input.supply.incomerCable;
    if (cableSettings == null || incomer.breakerA == null) {
      return _Panel(loopImpedanceOhm: zExt, voltageDropPercent: 0, assumedZext: measured == null);
    }
    final CableDefaults defaults = input.cableDefaults;
    final ConductorMaterial material = cableSettings.material ?? defaults.material;
    final InstallationMethod method = _method(
      cableSettings.installationMethodId ?? defaults.installationMethodId,
      null,
    );
    final spec = CableLineSpec(
      phases: input.supplyPhases == SupplyPhases.three ? 3 : 1,
      lighting: false,
      socketCircuit: false,
      designCurrentA: incomer.designA,
      breakerA: incomer.breakerA!,
      cosPhi: incomer.normative.cosPhi,
      material: material,
      insulation: cableSettings.insulation ?? defaults.insulation,
      method: method,
      ambientTemperatureC: cableSettings.ambientTemperatureC ?? defaults.ambientTemperatureC,
      groupedCircuits: cableSettings.groupedCircuits ?? 1,
      soilResistivityKMPerW: defaults.soilResistivityKMPerW,
      minSectionMm2: material == ConductorMaterial.aluminium
          ? norms.minCrossSections.aluminiumFeederMin
          : norms.minCrossSections.socketsCopper,
      phaseVoltageV: u0,
      upstreamLoopImpedanceOhm: zExt,
      upstreamVoltageDropPercent: 0,
      lengthM: cableSettings.lengthM,
      isGroupNetwork: false,
    );
    final CableEvaluation evaluation = cableSettings.sectionMm2 != null
        ? cables.evaluate(
            spec,
            sectionMm2: cableSettings.sectionMm2!,
            curve: BreakerCurve.c,
            sectionSource: ValueSource.manual,
          )
        : cables.select(spec, const [BreakerCurve.c]).evaluation;
    incomer.cable = evaluation.result;
    final double? length = cableSettings.lengthM;
    return _Panel(
      loopImpedanceOhm: length == null
          ? zExt
          : zExt +
                (cables.loopImpedanceOhm(
                      spec,
                      evaluation.result.sectionMm2,
                      evaluation.result.peSectionMm2,
                      length,
                    ) ??
                    0),
      voltageDropPercent: length == null
          ? 0
          : cables.voltageDropPercent(spec, evaluation.result.sectionMm2, length),
      assumedZext: measured == null,
    );
  }

  InstallationMethod _method(String id, String? circuitId) {
    final InstallationMethod? method = norms.installationMethods
        .where((m) => m.id == id)
        .firstOrNull;
    if (method != null) {
      return method;
    }
    issues.add(
      Issue(
        severity: IssueSeverity.warning,
        code: 'unknown_installation_method',
        message: 'Неизвестный способ прокладки «$id», принят «скрыто под штукатуркой»',
        circuitId: circuitId,
      ),
    );
    return norms.installationMethod('plaster_direct');
  }

  void _protectionAndCable(_CircuitState s, _Panel panel) {
    final CircuitDraft draft = s.draft;
    final CircuitSettings settings = input.circuitSettings[draft.id] ?? const CircuitSettings();
    final CableDefaults defaults = input.cableDefaults;
    final bool socketCircuit = draft.devices.any((d) => d.connection == DeviceConnection.socket);

    s.breaker = selectBreaker(
      norms: norms,
      purpose: draft.purpose,
      socketCircuit: socketCircuit,
      designCurrentA: s.designA,
      startingCurrentA: s.startA,
      manualRatedA: settings.breakerA,
      manualCurve: settings.curve,
    );
    s.checks.addAll(s.breaker.checks);

    s.rcdReasons = rcdReasons(devices: draft.devices, rooms: draft.rooms);
    final ProtectionDevice automaticDevice = s.rcdReasons.isEmpty
        ? ProtectionDevice.mcb
        : switch (input.rcdStrategy) {
            RcdStrategy.rcboPerCircuit => ProtectionDevice.rcbo,
            RcdStrategy.rcdPerCircuit => ProtectionDevice.mcbAndRcd,
            RcdStrategy.groupedRcd => ProtectionDevice.mcbUnderGroupRcd,
          };
    s.device = settings.protection ?? automaticDevice;
    if (s.device == ProtectionDevice.mcb && s.rcdReasons.isNotEmpty) {
      issues.add(
        Issue(
          severity: IssueSeverity.warning,
          code: 'rcd_removed_manually',
          message: '${draft.name}: требуется УЗО 30 мА — ${s.rcdReasons.join('; ')}',
          circuitId: draft.id,
        ),
      );
    }

    final ConductorMaterial material = settings.material ?? defaults.material;
    final spec = CableLineSpec(
      phases: draft.phases,
      lighting: draft.purpose == CircuitPurpose.lighting,
      socketCircuit: socketCircuit,
      designCurrentA: s.designA,
      breakerA: s.breaker.ratedA,
      cosPhi: s.cosPhi,
      material: material,
      insulation: settings.insulation ?? defaults.insulation,
      method: _method(settings.installationMethodId ?? defaults.installationMethodId, draft.id),
      ambientTemperatureC: settings.ambientTemperatureC ?? defaults.ambientTemperatureC,
      groupedCircuits: settings.groupedCircuits ?? defaults.groupedCircuits,
      soilResistivityKMPerW: defaults.soilResistivityKMPerW,
      minSectionMm2: _minSection(draft, socketCircuit, material),
      phaseVoltageV: u0,
      upstreamLoopImpedanceOhm: panel.loopImpedanceOhm,
      upstreamVoltageDropPercent: panel.voltageDropPercent,
      lengthM: settings.lengthM ?? defaults.lengthM,
    );
    if (settings.sectionMm2 != null) {
      s
        ..curve = s.breaker.curves.first
        ..cable = cables.evaluate(
          spec,
          sectionMm2: settings.sectionMm2!,
          curve: s.breaker.curves.first,
          sectionSource: ValueSource.manual,
        );
    } else {
      final ({BreakerCurve curve, CableEvaluation evaluation}) selected = cables.select(
        spec,
        s.breaker.curves,
      );
      s
        ..curve = selected.curve
        ..cable = selected.evaluation;
    }

    if (s.device != ProtectionDevice.mcb) {
      final double leak = leakageMa(designCurrentA: s.designA, lengthM: spec.lengthM);
      const double limit = additionalProtectionResidualMa / 3;
      final bool ok = lessOrEqual(leak, limit);
      s.checks.add(
        Check(
          code: CheckCode.rcdLeakage,
          status: ok ? CheckStatus.passed : CheckStatus.warning,
          message: ok
              ? 'Ток утечки ≈ ${fmt(leak)} мА ≤ ${fmt(limit)} мА'
              : 'Ток утечки ≈ ${fmt(leak)} мА больше 1/3 уставки УЗО: возможны ложные срабатывания',
          value: leak,
          limit: limit,
          reference: 'СП 256, А.1.2',
        ),
      );
    }
  }

  double _minSection(CircuitDraft draft, bool socketCircuit, ConductorMaterial material) {
    final MinCrossSections m = norms.minCrossSections;
    final aluminium = material == ConductorMaterial.aluminium;
    if (draft.devices.any((d) => electricCookingKinds.contains(d.kind))) {
      return aluminium ? m.electricStoveAluminiumAlloy : m.electricStoveCopper;
    }
    if (draft.purpose == CircuitPurpose.lighting) {
      return m.groupLine(lighting: true, material: material);
    }
    if (socketCircuit || draft.purpose == CircuitPurpose.power) {
      return m.groupLine(lighting: false, material: material);
    }
    // Fixed equipment on its own line: ГОСТ Р 50571.5.52 табл. 52.2 (Cu 1,5);
    // aluminium to engineering equipment ≥ 2,5 (СП 256 п. 15.3).
    return aluminium
        ? m.aluminiumEngineeringEquipmentMin
        : m.groupLine(lighting: true, material: material);
  }

  List<SharedRcdResult> _groupRcds(List<_CircuitState> states) {
    final List<_CircuitState> grouped = states
        .where((s) => s.device == ProtectionDevice.mcbUnderGroupRcd)
        .toList();
    if (grouped.isEmpty) {
      return const [];
    }
    const double limitMa = additionalProtectionResidualMa / 3;
    const maxRatedA = 63.0;
    final buckets = <String, List<_CircuitState>>{};
    for (final s in grouped) {
      final key = s.draft.phases == 3 ? '3ph-${s.draft.id}' : '1ph-${s.phase!.name}';
      buckets.putIfAbsent(key, () => []).add(s);
    }
    final result = <SharedRcdResult>[];
    for (final String key in buckets.keys.toList()..sort()) {
      final bins = <List<_CircuitState>>[];
      for (final _CircuitState s in buckets[key]!) {
        final double leak = leakageMa(designCurrentA: s.designA, lengthM: s.cable.result.lengthM);
        final int index = bins.indexWhere((b) {
          final double sumLeak = b.fold<double>(
            0,
            (t, x) => t + leakageMa(designCurrentA: x.designA, lengthM: x.cable.result.lengthM),
          );
          final double sumA = b.fold<double>(0, (t, x) => t + x.designA);
          return lessOrEqual(sumLeak + leak, limitMa) && lessOrEqual(sumA + s.designA, maxRatedA);
        });
        if (index >= 0) {
          bins[index].add(s);
        } else {
          bins.add([s]);
        }
      }
      for (final bin in bins) {
        final id = 'rcd-${result.length + 1}';
        final double sumA = bin.fold<double>(0, (t, x) => t + x.designA);
        final double maxIn = bin.map((x) => x.breaker.ratedA).reduce(math.max);
        final double rated = norms.breakers.rcdRatedCurrents.firstWhere(
          (r) => r + epsilon >= math.max(sumA, maxIn),
          orElse: () => norms.breakers.rcdRatedCurrents.last,
        );
        for (final s in bin) {
          s.rcdGroupId = id;
        }
        result.add(
          SharedRcdResult(
            id: id,
            ratedA: rated,
            residualMa: additionalProtectionResidualMa,
            type: 'A',
            poles: bin.first.draft.phases == 3 ? 4 : 2,
            circuitIds: [for (final s in bin) s.draft.id],
            leakageMa: bin.fold<double>(
              0,
              (t, x) => t + leakageMa(designCurrentA: x.designA, lengthM: x.cable.result.lengthM),
            ),
          ),
        );
      }
    }
    return result;
  }

  SharedRcdResult? _fireRcd(_Incomer incomer, List<_CircuitState> states) {
    final bool enabled =
        input.fireRcdAtInput ??
        (input.objectType == ObjectType.house || input.objectType == ObjectType.garageWorkshop);
    if (!enabled || incomer.breakerA == null) {
      return null;
    }
    final double rated = norms.breakers.rcdRatedCurrents.firstWhere(
      (r) => r + epsilon >= incomer.breakerA!,
      orElse: () => norms.breakers.rcdRatedCurrents.last,
    );
    return SharedRcdResult(
      id: 'rcd-input',
      ratedA: rated,
      residualMa: fireRcdResidualMa,
      type: 'A',
      poles: input.supplyPhases == SupplyPhases.three ? 4 : 2,
      circuitIds: const [],
      leakageMa: states.fold<double>(
        0,
        (t, s) => t + leakageMa(designCurrentA: s.demandA, lengthM: s.cable.result.lengthM),
      ),
      selective: true,
    );
  }

  CircuitResult _circuitResult(_CircuitState s, int number, bool assumedZext) {
    final CircuitDraft draft = s.draft;
    final CircuitSettings? settings = input.circuitSettings[draft.id];
    final RcdResult? rcd = s.device == ProtectionDevice.mcb
        ? null
        : RcdResult(
            residualMa: additionalProtectionResidualMa,
            type: 'A',
            reasons: s.rcdReasons.isEmpty ? const ['установлено вручную'] : s.rcdReasons,
            ratedA: s.device == ProtectionDevice.mcbAndRcd
                ? norms.breakers.rcdRatedCurrents.firstWhere(
                    (r) => r + epsilon >= s.breaker.ratedA,
                    orElse: () => norms.breakers.rcdRatedCurrents.last,
                  )
                : null,
            groupId: s.rcdGroupId,
          );
    final List<Check> all = [...s.checks, ...s.cable.result.checks];
    return CircuitResult(
      id: draft.id,
      number: number,
      name: draft.name,
      purpose: draft.purpose,
      roomIds: [for (final r in draft.rooms) r.id],
      deviceIds: [for (final d in draft.devices) d.id],
      phases: draft.phases,
      phase: draft.phases == 3 ? null : s.phase,
      phaseSource: s.phaseSource,
      installedPowerW: s.powerW,
      designCurrentA: s.designA,
      demandCurrentA: s.demandA,
      cosPhi: s.cosPhi,
      startingCurrentA: s.startA,
      protection: ProtectionResult(
        device: s.device,
        breakerA: s.breaker.ratedA,
        curve: s.curve,
        poles: draft.phases == 3 ? 3 : 1,
        breakerSource: settings?.breakerA != null || settings?.curve != null
            ? ValueSource.manual
            : ValueSource.automatic,
        rcd: rcd,
      ),
      cable: s.cable.result,
      checks: s.checks,
      status: statusOf(all, assumedZext: assumedZext),
    );
  }

  CalculationStatus _projectStatus(List<CircuitResult> circuits, IncomerResult incomer) {
    final List<CalculationStatus> statuses = [
      ...circuits.map((c) => c.status),
      statusOf([...incomer.checks, ...?incomer.cable?.checks], assumedZext: false),
      if (issues.any((i) => i.severity == IssueSeverity.error)) CalculationStatus.failed,
      if (issues.any((i) => i.severity == IssueSeverity.warning)) CalculationStatus.warning,
    ];
    return statuses.fold(CalculationStatus.passed, worst);
  }
}

/// Status of a set of checks.
///
/// Any failed → failed; voltage drop or fault loop not evaluated (no length) → preliminary;
/// assumed upstream impedance → requires review; any warning → warning; otherwise passed.
CalculationStatus statusOf(Iterable<Check> checks, {required bool assumedZext}) {
  if (checks.any((c) => c.status == CheckStatus.failed)) {
    return CalculationStatus.failed;
  }
  final bool lengthMissing = checks.any(
    (c) =>
        (c.code == CheckCode.voltageDrop || c.code == CheckCode.faultDisconnection) &&
        c.status == CheckStatus.notEvaluated,
  );
  if (lengthMissing) {
    return CalculationStatus.preliminary;
  }
  if (assumedZext && checks.any((c) => c.code == CheckCode.faultDisconnection)) {
    return CalculationStatus.requiresReview;
  }
  if (checks.any((c) => c.status == CheckStatus.warning)) {
    return CalculationStatus.warning;
  }
  return CalculationStatus.passed;
}

/// The less favourable of two statuses.
CalculationStatus worst(CalculationStatus a, CalculationStatus b) =>
    _severity.indexOf(a) >= _severity.indexOf(b) ? a : b;

const List<CalculationStatus> _severity = [
  CalculationStatus.passed,
  CalculationStatus.warning,
  CalculationStatus.requiresReview,
  CalculationStatus.preliminary,
  CalculationStatus.failed,
];

final class const _Panel({
  required final double loopImpedanceOhm,
  required final double voltageDropPercent,
  required final bool assumedZext,
});

final class _Incomer({
  required final double installedW,
  required final double byDevicesW,
  required final NormativeDemand normative,
  required final double designA,
  required final double? breakerA,
  required final ValueSource breakerSource,
  required final List<Check> checks,
}) {
  CableResult? cable;

  IncomerResult result(_Panel panel) => IncomerResult(
    installedPowerW: installedW,
    demandByDevicesW: byDevicesW,
    demandNormativeW: normative.powerW,
    normativeMethod: normative.method,
    cosPhi: normative.cosPhi,
    designCurrentA: designA,
    breakerA: breakerA,
    breakerSource: breakerSource,
    checks: checks,
    cable: cable,
  );
}
