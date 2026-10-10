import 'package:electrical_core/src/model/enums.dart';
import 'package:electrical_core/src/model/json.dart';
import 'package:meta/meta.dart';
import 'package:norms_data/norms_data.dart';

/// Code of a circuit or incomer check.
enum CheckCode {
  /// IB ≤ In (ГОСТ Р 50571.4.43, 433.1).
  loadVsBreaker,

  /// In ≤ Iz (ГОСТ Р 50571.4.43, 433.1; I2 = 1,45 In для автоматов).
  breakerVsAmpacity,

  /// Section not below the normative minimum (СП 256 табл. 15.3, п. 10.2).
  minimumSection,

  /// Voltage drop within the limit (СП 256 п. 8.23; ГОСТ Р 50571.5.52 прил. G).
  voltageDrop,

  /// Fault current guarantees instantaneous tripping (ГОСТ Р 50571.4.41, 411.4.4).
  faultDisconnection,

  /// Protective conductor section (ГОСТ Р 50571.5.54 табл. 54.2).
  protectiveConductor,

  /// Starting current does not trip the breaker.
  startingCurrent,

  /// Socket-outlets protected by a breaker of at most 16 A.
  socketRating,

  /// Leakage current within 1/3 of IΔn (СП 256 А.1.2).
  rcdLeakage,

  /// Tabulated data exist for the chosen conditions.
  datasetCoverage,

  /// Aluminium conductors are allowed for this circuit (СП 256 табл. 15.3, п. 15.3).
  conductorMaterial,

  /// Thermal withstand of conductors under short circuit (ГОСТ Р 50571.4.43, 434.5.2).
  shortCircuitThermal,

  /// Demand within allowed power / incomer breaker.
  allowedPower,
}

/// Result of one check.
@immutable
final class Check {
  const Check({
    required this.code,
    required this.status,
    required this.message,
    this.value,
    this.limit,
    this.reference,
  });

  /// Check code.
  final CheckCode code;

  /// Outcome.
  final CheckStatus status;

  /// Russian explanation for the user and the report.
  final String message;

  /// Checked value (current, %, A …), if numeric.
  final double? value;

  /// Limit the value is compared against.
  final double? limit;

  /// Clause of the norm.
  final String? reference;

  /// Serializes to JSON.
  Json toJson() => compact({
    'code': code.name,
    'status': status.name,
    'message': message,
    'value': value,
    'limit': limit,
    'reference': reference,
  });
}

/// Issue that is not tied to a single check.
@immutable
final class Issue {
  const Issue({
    required this.severity,
    required this.code,
    required this.message,
    this.circuitId,
    this.deviceId,
  });

  /// Severity.
  final IssueSeverity severity;

  /// Stable code for tests and UI.
  final String code;

  /// Russian message.
  final String message;

  /// Related circuit.
  final String? circuitId;

  /// Related device.
  final String? deviceId;

  /// Serializes to JSON.
  Json toJson() => compact({
    'severity': severity.name,
    'code': code,
    'message': message,
    'circuit_id': circuitId,
    'device_id': deviceId,
  });
}

/// Assumption the calculation relied on; listed in the report.
@immutable
final class Assumption {
  const Assumption({required this.code, required this.message});

  /// Stable code.
  final String code;

  /// Russian text.
  final String message;

  /// Serializes to JSON.
  Json toJson() => {'code': code, 'message': message};
}

/// Residual current protection of a circuit.
@immutable
final class RcdResult {
  const RcdResult({
    required this.residualMa,
    required this.type,
    required this.reasons,
    this.ratedA,
    this.groupId,
  });

  /// Rated residual operating current IΔn, mA.
  final double residualMa;

  /// RCD type (`A`).
  final String type;

  /// Why the RCD is required (Russian, with references).
  final List<String> reasons;

  /// Rated current of a separate RCD, A; `null` for RCBO or grouped RCD.
  final double? ratedA;

  /// Id of the shared RCD for the grouped strategy.
  final String? groupId;

  /// Serializes to JSON.
  Json toJson() => compact({
    'residual_ma': residualMa,
    'type': type,
    'reasons': reasons,
    'rated_a': ratedA,
    'group_id': groupId,
  });
}

/// Protection of a circuit.
@immutable
final class ProtectionResult {
  const ProtectionResult({
    required this.device,
    required this.breakerA,
    required this.curve,
    required this.poles,
    required this.breakerSource,
    this.rcd,
  });

  /// Device type.
  final ProtectionDevice device;

  /// Rated current In, A.
  final double breakerA;

  /// Tripping curve.
  final BreakerCurve curve;

  /// Number of protected poles (1 or 3; RCBO 1P+N counts as 1).
  final int poles;

  /// Whether rating/curve were set manually.
  final ValueSource breakerSource;

  /// Residual current protection, if any.
  final RcdResult? rcd;

  /// Short label like `C16`.
  String get label => '${curve.name.toUpperCase()}${_trim(breakerA)}';

  /// Serializes to JSON.
  Json toJson() => compact({
    'device': device.name,
    'breaker_a': breakerA,
    'curve': curve.name,
    'poles': poles,
    'breaker_source': breakerSource.name,
    'rcd': rcd?.toJson(),
  });
}

/// Cable of a circuit (or of the incomer).
@immutable
final class CableResult {
  const CableResult({
    required this.material,
    required this.insulation,
    required this.installationMethodId,
    required this.referenceMethod,
    required this.cores,
    required this.sectionMm2,
    required this.peSectionMm2,
    required this.sectionSource,
    required this.voltageDropLimitPercent,
    required this.checks,
    this.lengthM,
    this.tabulatedA,
    this.temperatureFactor,
    this.groupingFactor,
    this.soilFactor,
    this.ampacityA,
    this.voltageDropPercent,
    this.loopImpedanceOhm,
    this.faultCurrentMinA,
    this.instantaneousTripA,
  });

  /// Conductor material.
  final ConductorMaterial material;

  /// Insulation.
  final Insulation insulation;

  /// Installation method id.
  final String installationMethodId;

  /// Reference method of ГОСТ Р 50571.5.52.
  final ReferenceMethod referenceMethod;

  /// Number of cores (3 or 5).
  final int cores;

  /// Line conductor section, mm².
  final double sectionMm2;

  /// Protective conductor section, mm².
  final double peSectionMm2;

  /// Automatic or manual section.
  final ValueSource sectionSource;

  /// Length, m.
  final double? lengthM;

  /// Tabulated current Iтабл, A.
  final double? tabulatedA;

  /// Ambient temperature factor.
  final double? temperatureFactor;

  /// Grouping factor.
  final double? groupingFactor;

  /// Soil resistivity factor (cables in the ground).
  final double? soilFactor;

  /// Corrected current-carrying capacity Iz, A.
  final double? ampacityA;

  /// Voltage drop including the incomer cable, %.
  final double? voltageDropPercent;

  /// Voltage drop limit, %.
  final double voltageDropLimitPercent;

  /// Phase–PE loop impedance at the end of the line, Ом.
  final double? loopImpedanceOhm;

  /// Minimum prospective fault current at the end of the line, A.
  final double? faultCurrentMinA;

  /// Current guaranteeing instantaneous tripping of the breaker, A.
  final double? instantaneousTripA;

  /// Checks.
  final List<Check> checks;

  /// Label like `3×2,5`.
  String get label => '$cores×${_trimComma(sectionMm2)}';

  /// Serializes to JSON.
  Json toJson() => compact({
    'material': material.name,
    'insulation': insulation.name,
    'installation_method_id': installationMethodId,
    'reference_method': referenceMethod.key,
    'cores': cores,
    'section_mm2': sectionMm2,
    'pe_section_mm2': peSectionMm2,
    'section_source': sectionSource.name,
    'length_m': lengthM,
    'tabulated_a': tabulatedA,
    'temperature_factor': temperatureFactor,
    'grouping_factor': groupingFactor,
    'soil_factor': soilFactor,
    'ampacity_a': ampacityA,
    'voltage_drop_percent': voltageDropPercent,
    'voltage_drop_limit_percent': voltageDropLimitPercent,
    'loop_impedance_ohm': loopImpedanceOhm,
    'fault_current_min_a': faultCurrentMinA,
    'instantaneous_trip_a': instantaneousTripA,
    'checks': [for (final c in checks) c.toJson()],
  });
}

/// Calculated circuit.
@immutable
final class CircuitResult {
  const CircuitResult({
    required this.id,
    required this.number,
    required this.name,
    required this.purpose,
    required this.roomIds,
    required this.deviceIds,
    required this.phases,
    required this.phase,
    required this.phaseSource,
    required this.installedPowerW,
    required this.designCurrentA,
    required this.demandCurrentA,
    required this.cosPhi,
    required this.startingCurrentA,
    required this.protection,
    required this.cable,
    required this.checks,
    required this.status,
  });

  /// Stable id (key of `CircuitSettings`).
  final String id;

  /// Number in the panel, from 1.
  final int number;

  /// Name for the user.
  final String name;

  /// Purpose.
  final CircuitPurpose purpose;

  /// Rooms served.
  final List<String> roomIds;

  /// Devices served.
  final List<String> deviceIds;

  /// 1 or 3.
  final int phases;

  /// Phase of a single-phase circuit; `null` for three-phase circuits.
  final Phase? phase;

  /// Automatic or manual phase.
  final ValueSource phaseSource;

  /// Sum of rated powers, Вт.
  final double installedPowerW;

  /// Design current IB with Kс = 1 (СП 256, 7.2.2), A.
  final double designCurrentA;

  /// Expected current with usage factors, A (phase balancing, input estimate).
  final double demandCurrentA;

  /// Resulting power factor.
  final double cosPhi;

  /// Peak starting current of the circuit, A.
  final double startingCurrentA;

  /// Protection.
  final ProtectionResult protection;

  /// Cable.
  final CableResult cable;

  /// Circuit-level checks (protection); cable checks are in [cable].
  final List<Check> checks;

  /// Overall status.
  final CalculationStatus status;

  /// All checks of the circuit.
  Iterable<Check> get allChecks => [...checks, ...cable.checks];

  /// Serializes to JSON.
  Json toJson() => compact({
    'id': id,
    'number': number,
    'name': name,
    'purpose': purpose.name,
    'room_ids': roomIds,
    'device_ids': deviceIds,
    'phases': phases,
    'phase': phase?.name,
    'phase_source': phaseSource.name,
    'installed_power_w': installedPowerW,
    'design_current_a': designCurrentA,
    'demand_current_a': demandCurrentA,
    'cos_phi': cosPhi,
    'starting_current_a': startingCurrentA,
    'protection': protection.toJson(),
    'cable': cable.toJson(),
    'checks': [for (final c in checks) c.toJson()],
    'status': status.name,
  });
}

/// Shared RCD (grouped strategy) or fire-protection RCD.
@immutable
final class SharedRcdResult {
  const SharedRcdResult({
    required this.id,
    required this.ratedA,
    required this.residualMa,
    required this.type,
    required this.poles,
    required this.circuitIds,
    required this.leakageMa,
    this.selective = false,
  });

  /// Id.
  final String id;

  /// Rated current, A.
  final double ratedA;

  /// IΔn, mA.
  final double residualMa;

  /// Type (`A`).
  final String type;

  /// 2 or 4.
  final int poles;

  /// Circuits behind the RCD (empty for the incomer RCD: all circuits).
  final List<String> circuitIds;

  /// Estimated leakage current, mA (СП 256 А.1.2).
  final double leakageMa;

  /// Time-delayed (S) for selectivity.
  final bool selective;

  /// Serializes to JSON.
  Json toJson() => {
    'id': id,
    'rated_a': ratedA,
    'residual_ma': residualMa,
    'type': type,
    'poles': poles,
    'circuit_ids': circuitIds,
    'leakage_ma': leakageMa,
    'selective': selective,
  };
}

/// Phase loads after balancing.
@immutable
final class PhaseBalanceResult {
  const PhaseBalanceResult({
    required this.loadsA,
    required this.imbalancePercent,
    required this.limitPercent,
  });

  /// Demand current per phase, A.
  final Map<Phase, double> loadsA;

  /// (max − min) / max · 100.
  final double imbalancePercent;

  /// Limit used for the warning, % (СП 256 п. 10.5).
  final double limitPercent;

  /// Serializes to JSON.
  Json toJson() => {
    'loads_a': {for (final e in loadsA.entries) e.key.name: e.value},
    'imbalance_percent': imbalancePercent,
    'limit_percent': limitPercent,
  };
}

/// Input (incomer) calculation.
@immutable
final class IncomerResult {
  const IncomerResult({
    required this.installedPowerW,
    required this.demandByDevicesW,
    required this.demandNormativeW,
    required this.normativeMethod,
    required this.cosPhi,
    required this.designCurrentA,
    required this.breakerA,
    required this.breakerSource,
    required this.checks,
    this.cable,
  });

  /// Sum of rated powers, Вт.
  final double installedPowerW;

  /// Σ P·ku, Вт (upper estimate).
  final double demandByDevicesW;

  /// Design load by СП 256, Вт; used to select the incomer.
  final double demandNormativeW;

  /// How [demandNormativeW] was obtained (Russian, with references).
  final String normativeMethod;

  /// Power factor of the input.
  final double cosPhi;

  /// Design current of the most loaded phase, A.
  final double designCurrentA;

  /// Incomer breaker rating, A.
  final double? breakerA;

  /// Existing (manual) or selected.
  final ValueSource breakerSource;

  /// Incomer cable, if requested.
  final CableResult? cable;

  /// Checks.
  final List<Check> checks;

  /// Serializes to JSON.
  Json toJson() => compact({
    'installed_power_w': installedPowerW,
    'demand_by_devices_w': demandByDevicesW,
    'demand_normative_w': demandNormativeW,
    'normative_method': normativeMethod,
    'cos_phi': cosPhi,
    'design_current_a': designCurrentA,
    'breaker_a': breakerA,
    'breaker_source': breakerSource.name,
    'cable': cable?.toJson(),
    'checks': [for (final c in checks) c.toJson()],
  });
}

/// Complete calculation result; never persisted, always recomputed from `ProjectInput`.
@immutable
final class ProjectResult {
  const ProjectResult({
    required this.algorithmVersion,
    required this.datasetVersions,
    required this.phaseVoltageV,
    required this.lineVoltageV,
    required this.circuits,
    required this.sharedRcds,
    required this.incomer,
    required this.issues,
    required this.assumptions,
    required this.status,
    this.fireRcd,
    this.phaseBalance,
  });

  /// Algorithm version.
  final String algorithmVersion;

  /// Versions of the normative datasets.
  final Map<String, String> datasetVersions;

  /// U0, В.
  final double phaseVoltageV;

  /// Line voltage, В.
  final double lineVoltageV;

  /// Circuits ordered by number.
  final List<CircuitResult> circuits;

  /// Shared RCDs of the grouped strategy.
  final List<SharedRcdResult> sharedRcds;

  /// Fire-protection RCD at the input.
  final SharedRcdResult? fireRcd;

  /// Phase balance (three-phase supply).
  final PhaseBalanceResult? phaseBalance;

  /// Input.
  final IncomerResult incomer;

  /// Issues.
  final List<Issue> issues;

  /// Assumptions.
  final List<Assumption> assumptions;

  /// Overall status (worst of all circuits and the incomer).
  final CalculationStatus status;

  /// Serializes to JSON.
  Json toJson() => compact({
    'algorithm_version': algorithmVersion,
    'dataset_versions': datasetVersions,
    'phase_voltage_v': phaseVoltageV,
    'line_voltage_v': lineVoltageV,
    'circuits': [for (final c in circuits) c.toJson()],
    'shared_rcds': [for (final r in sharedRcds) r.toJson()],
    'fire_rcd': fireRcd?.toJson(),
    'phase_balance': phaseBalance?.toJson(),
    'incomer': incomer.toJson(),
    'issues': [for (final i in issues) i.toJson()],
    'assumptions': [for (final a in assumptions) a.toJson()],
    'status': status.name,
  });
}

String _trim(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

String _trimComma(double v) => _trim(v).replaceAll('.', ',');
