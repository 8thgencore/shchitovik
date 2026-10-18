import 'dart:math' as math;

import 'package:electrical_core/src/calc/tolerance.dart';
import 'package:electrical_core/src/model/enums.dart';
import 'package:electrical_core/src/model/project_result.dart';
import 'package:norms_data/norms_data.dart';

/// Voltage factor for the minimum short-circuit current in LV networks (ГОСТ Р 52735 / IEC 60909-0: cmin = 0,95).
const double minimumVoltageFactor = 0.95;

/// Everything needed to evaluate a cable line except the cross-section.
final class const CableLineSpec({
  /// 1 or 3.
  required final int phases,

  /// Lighting circuit (stricter voltage drop limit).
  required final bool lighting,

  /// The circuit feeds socket-outlets.
  required final bool socketCircuit,

  /// IB, A.
  required final double designCurrentA,

  /// In, A.
  required final double breakerA,

  /// Power factor of the load.
  required final double cosPhi,

  /// Conductor material.
  required final ConductorMaterial material,

  /// Insulation.
  required final Insulation insulation,

  /// Installation method.
  required final InstallationMethod method,

  /// Ambient temperature, °C.
  required final double ambientTemperatureC,

  /// Number of grouped circuits.
  required final int groupedCircuits,

  /// Soil resistivity, К·м/Вт.
  required final double soilResistivityKMPerW,

  /// Normative minimum section, mm².
  required final double minSectionMm2,

  /// U0, В.
  required final double phaseVoltageV,

  /// Loop impedance at the start of the line, Ом.
  required final double upstreamLoopImpedanceOhm,

  /// Voltage drop upstream of the line (incomer cable), %.
  required final double upstreamVoltageDropPercent,

  /// Length, m; `null` — voltage drop and fault loop are not evaluated.
  final double? lengthM,

  /// Group network of a building (aluminium restrictions of СП 256 табл. 15.3 apply).
  final bool isGroupNetwork = true,
});

/// Cable evaluated for one cross-section and breaker curve.
final class CableEvaluation({
  /// Result for the report.
  required final CableResult result,

  /// All mandatory checks passed (not-evaluated counts as passed).
  required final bool mandatoryPassed,
}) {
  /// Check by code.
  Check check(CheckCode code) => result.checks.firstWhere((c) => c.code == code);
}

/// Evaluates cable lines against ГОСТ Р 50571.4.43, 4.41, 5.52, 5.54 and СП 256.
final class CableCalculator(
  /// Normative data.
  final NormsData norms,
) {
  /// Evaluates [spec] with [sectionMm2] and breaker [curve].
  CableEvaluation evaluate(
    CableLineSpec spec, {
    required double sectionMm2,
    required BreakerCurve curve,
    ValueSource sectionSource = ValueSource.automatic,
  }) {
    final checks = <Check>[];
    final loaded = spec.phases == 3 ? 3 : 2;
    final ReferenceMethod method = spec.method.referenceMethod;

    // Current-carrying capacity: ГОСТ Р 50571.5.52, 523 and приложение B.
    final double? tabulated = norms.ampacity.currentA(
      insulation: spec.insulation,
      material: spec.material,
      loadedConductors: loaded,
      method: method,
      sectionMm2: sectionMm2,
    );
    final double? kt = norms.temperatureFactors.factor(
      spec.method.environment,
      spec.insulation,
      spec.ambientTemperatureC,
    );
    final double? kg = _groupingFactor(spec);
    final double? ks = method.isInGround
        ? norms.soilFactors.factor(method, spec.soilResistivityKMPerW)
        : 1.0;
    final bool covered = tabulated != null && kt != null && kg != null && ks != null;
    final double? iz = covered ? tabulated * kt * kg * ks : null;

    checks
      ..add(
        covered
            ? Check(
                code: CheckCode.datasetCoverage,
                status: CheckStatus.passed,
                message:
                    'Iтабл = ${fmt(tabulated)} А (метод ${method.key}), kt = ${fmt(kt, 2)}, '
                    'kгр = ${fmt(kg, 2)}${method.isInGround ? ', kгрунт = ${fmt(ks, 2)}' : ''}',
                reference: 'ГОСТ Р 50571.5.52, табл. B.52.2–B.52.19',
              )
            : Check(
                code: CheckCode.datasetCoverage,
                status: CheckStatus.failed,
                message: _coverageMessage(tabulated, kt, kg, ks, sectionMm2),
                reference: 'ГОСТ Р 50571.5.52, приложение B',
              ),
      )
      ..add(
        iz == null
            ? const Check(
                code: CheckCode.breakerVsAmpacity,
                status: CheckStatus.notEvaluated,
                message: 'Допустимый ток не определён',
                reference: 'ГОСТ Р 50571.4.43, 433.1',
              )
            : Check(
                code: CheckCode.breakerVsAmpacity,
                status: lessOrEqual(spec.breakerA, iz) ? CheckStatus.passed : CheckStatus.failed,
                message: lessOrEqual(spec.breakerA, iz)
                    ? 'In = ${fmt(spec.breakerA, 0)} А ≤ Iz = ${fmt(iz)} А'
                    : 'Автомат ${fmt(spec.breakerA, 0)} А не защищает кабель: Iz = ${fmt(iz)} А',
                value: spec.breakerA,
                limit: iz,
                reference: 'ГОСТ Р 50571.4.43, 433.1 (I2 = 1,45 In)',
              ),
      );

    final bool minOk = sectionMm2 + epsilon >= spec.minSectionMm2;
    checks.add(
      Check(
        code: CheckCode.minimumSection,
        status: minOk ? CheckStatus.passed : CheckStatus.failed,
        message: minOk
            ? 'Сечение не меньше нормативного ${fmt(spec.minSectionMm2)} мм²'
            : 'Сечение ${fmt(sectionMm2)} мм² меньше нормативного ${fmt(spec.minSectionMm2)} мм²',
        value: sectionMm2,
        limit: spec.minSectionMm2,
        reference: 'СП 256, табл. 15.3, п. 10.2',
      ),
    );

    // Voltage drop: ГОСТ Р 50571.5.52, приложение G; limits СП 256 п. 8.23.
    final double? length = spec.lengthM;
    final double vdLimit = norms.voltageDropLimits.limitPercent(
      lighting: spec.lighting,
      lengthM: length ?? 0,
    );
    double? vd;
    if (length == null) {
      checks.add(
        const Check(
          code: CheckCode.voltageDrop,
          status: CheckStatus.notEvaluated,
          message: 'Не задана длина линии',
          reference: 'СП 256, п. 8.23',
        ),
      );
    } else {
      vd = spec.upstreamVoltageDropPercent + voltageDropPercent(spec, sectionMm2, length);
      final bool ok = lessOrEqual(vd, vdLimit);
      checks.add(
        Check(
          code: CheckCode.voltageDrop,
          status: ok ? CheckStatus.passed : CheckStatus.failed,
          message: ok
              ? 'ΔU = ${fmt(vd, 2)} % ≤ ${fmt(vdLimit, 2)} %'
              : 'Потери напряжения ${fmt(vd, 2)} % превышают ${fmt(vdLimit, 2)} %',
          value: vd,
          limit: vdLimit,
          reference: 'СП 256, п. 8.23; ГОСТ Р 50571.5.52, прил. G',
        ),
      );
    }

    // Protective conductor: ГОСТ Р 50571.5.54, табл. 54.2.
    final double pe = _standardAtOrAbove(norms.protectiveConductors.minSectionMm2(sectionMm2));
    checks.add(
      Check(
        code: CheckCode.protectiveConductor,
        status: CheckStatus.passed,
        message: 'PE ${fmt(pe)} мм² по табл. 54.2',
        value: pe,
        reference: 'ГОСТ Р 50571.5.54, табл. 54.2',
      ),
    );

    // Automatic disconnection: ГОСТ Р 50571.4.41, 411.4.4: Zs·Ia ≤ U0.
    final double ia = norms.breakers.guaranteedInstantaneousTripA(curve, spec.breakerA);
    double? zs;
    double? ik;
    final double? lineLoop = length == null ? null : loopImpedanceOhm(spec, sectionMm2, pe, length);
    if (length == null || lineLoop == null) {
      checks.add(
        Check(
          code: CheckCode.faultDisconnection,
          status: CheckStatus.notEvaluated,
          message: length == null
              ? 'Не задана длина линии'
              : 'Нет данных о сопротивлении жил этого сечения',
          reference: 'ГОСТ Р 50571.4.41, 411.4.4',
        ),
      );
    } else {
      zs = spec.upstreamLoopImpedanceOhm + lineLoop;
      ik = minimumVoltageFactor * spec.phaseVoltageV / zs;
      final bool ok = ik + epsilon >= ia;
      checks.add(
        Check(
          code: CheckCode.faultDisconnection,
          status: ok ? CheckStatus.passed : CheckStatus.failed,
          message: ok
              ? 'Iк.мин = ${fmt(ik, 0)} А ≥ Ia = ${fmt(ia, 0)} А (${curve.name.toUpperCase()}${fmt(spec.breakerA, 0)})'
              : 'Ток КЗ в конце линии ${fmt(ik, 0)} А меньше тока мгновенного расцепления '
                    '${fmt(ia, 0)} А: автомат не отключит замыкание за нормированное время',
          value: ik,
          limit: ia,
          reference: 'ГОСТ Р 50571.4.41, 411.4.4, табл. 41.1',
        ),
      );
    }

    checks.add(
      const Check(
        code: CheckCode.shortCircuitThermal,
        status: CheckStatus.notEvaluated,
        message: 'Нужна характеристика I²t автомата',
        reference: 'ГОСТ Р 50571.4.43, 434.5.2',
      ),
    );

    if (spec.material == ConductorMaterial.aluminium && spec.isGroupNetwork) {
      checks.add(
        const Check(
          code: CheckCode.conductorMaterial,
          status: CheckStatus.warning,
          message:
              'В групповых сетях допускаются только жилы из алюминиевых сплавов марок 8030 и 8176',
          reference: 'СП 256, табл. 15.3',
        ),
      );
    }

    final bool mandatoryPassed = checks.every((c) => c.status != CheckStatus.failed);
    return CableEvaluation(
      mandatoryPassed: mandatoryPassed,
      result: CableResult(
        material: spec.material,
        insulation: spec.insulation,
        installationMethodId: spec.method.id,
        referenceMethod: method,
        cores: spec.phases == 3 ? 5 : 3,
        sectionMm2: sectionMm2,
        peSectionMm2: pe,
        sectionSource: sectionSource,
        lengthM: length,
        tabulatedA: tabulated,
        temperatureFactor: kt,
        groupingFactor: kg,
        soilFactor: method.isInGround ? ks : null,
        ampacityA: iz,
        voltageDropPercent: vd,
        voltageDropLimitPercent: vdLimit,
        loopImpedanceOhm: zs,
        faultCurrentMinA: ik,
        instantaneousTripA: ia,
        checks: checks,
      ),
    );
  }

  /// Selects the smallest section (and the first suitable curve from [curves]) passing all
  /// mandatory checks. Returns the evaluation with the preferred curve at the smallest
  /// section satisfying In ≤ Iz if nothing passes, or at the largest tabulated section.
  ({CableEvaluation evaluation, BreakerCurve curve}) select(
    CableLineSpec spec,
    List<BreakerCurve> curves,
  ) {
    ({CableEvaluation evaluation, BreakerCurve curve})? fallback;
    for (final double section in norms.constants.standardSections) {
      if (section + epsilon < spec.minSectionMm2) {
        continue;
      }
      for (final curve in curves) {
        final CableEvaluation evaluation = evaluate(spec, sectionMm2: section, curve: curve);
        if (evaluation.mandatoryPassed) {
          return (evaluation: evaluation, curve: curve);
        }
        final coverage = evaluation.check(CheckCode.datasetCoverage).status == CheckStatus.passed;
        final ampacityOk =
            evaluation.check(CheckCode.breakerVsAmpacity).status == CheckStatus.passed;
        if (curve == curves.first && coverage && ampacityOk && fallback == null) {
          fallback = (evaluation: evaluation, curve: curve);
        }
      }
    }
    if (fallback != null) {
      return fallback;
    }
    final double largest = norms.constants.standardSections.lastWhere(
      (s) =>
          norms.ampacity.currentA(
            insulation: spec.insulation,
            material: spec.material,
            loadedConductors: spec.phases == 3 ? 3 : 2,
            method: spec.method.referenceMethod,
            sectionMm2: s,
          ) !=
          null,
    );
    return (
      evaluation: evaluate(spec, sectionMm2: largest, curve: curves.first),
      curve: curves.first,
    );
  }

  /// Voltage drop of the line itself, % of U0 (ГОСТ Р 50571.5.52, прил. G):
  /// u = b·(ρ1·L/S·cos φ + λ·L·sin φ)·IB; b = 2 single-phase, 1 three-phase.
  double voltageDropPercent(CableLineSpec spec, double sectionMm2, double lengthM) {
    final VoltageDropLimits limits = norms.voltageDropLimits;
    final b = spec.phases == 3 ? 1.0 : 2.0;
    final double cos = spec.cosPhi;
    final double sin = math.sqrt(math.max(0, 1 - cos * cos));
    final double rho1 = limits.formulaRho1[spec.material]!;
    final double u =
        b *
        (rho1 * lengthM / sectionMm2 * cos + limits.formulaLambdaOhmPerM * lengthM * sin) *
        spec.designCurrentA;
    return 100 * u / spec.phaseVoltageV;
  }

  /// Phase–PE loop impedance of the line, Ом.
  ///
  /// Conductors at the maximum operating temperature of the insulation (conservative);
  /// reactance 0,08 Ом/км per conductor; the line impedance is added arithmetically to
  /// the upstream impedance.
  /// `null` when the conductor resistance is not tabulated for this section.
  double? loopImpedanceOhm(CableLineSpec spec, double sectionMm2, double peMm2, double lengthM) {
    final ConductorData c = norms.conductors;
    final double temperature = c.maxOperatingTemperatureC(spec.insulation);
    final double? rPhase = c.resistanceOhmPerKm(spec.material, sectionMm2, temperature);
    final double? rPe = c.resistanceOhmPerKm(spec.material, peMm2, temperature);
    if (rPhase == null || rPe == null) {
      return null;
    }
    final double r = (rPhase + rPe) * lengthM / 1000;
    final double x = 2 * c.reactanceOhmPerKm * lengthM / 1000;
    return math.sqrt(r * r + x * x);
  }

  double? _groupingFactor(CableLineSpec spec) {
    final int n = spec.groupedCircuits;
    final GroupingFactors g = norms.grouping;
    return switch (spec.method.groupingKey) {
      'direct_in_ground' => g.directInGround(n, GroundSpacing.touching),
      'in_ducts_multicore' => g.inDucts(n, GroundSpacing.touching),
      _ =>
        g.air(spec.method.airArrangement!, n) ??
            // Single-layer rows end at 9 circuits; bunched is more conservative.
            g.air(AirGroupingArrangement.bunched, n),
    };
  }

  double _standardAtOrAbove(double section) =>
      norms.constants.standardSections.firstWhere((s) => s + epsilon >= section);

  String _coverageMessage(double? tabulated, double? kt, double? kg, double? ks, double section) {
    if (tabulated == null) {
      return 'В таблицах нет допустимого тока для сечения ${fmt(section)} мм²';
    }
    if (kt == null) {
      return 'Температура среды вне диапазона таблицы поправочных коэффициентов';
    }
    if (kg == null) {
      return 'Число совместно проложенных цепей вне диапазона таблицы';
    }
    return 'Тепловое сопротивление грунта вне диапазона таблицы';
  }
}
