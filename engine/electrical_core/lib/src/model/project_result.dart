import 'package:electrical_core/src/model/enums.dart';
import 'package:electrical_core/src/model/json.dart';
import 'package:meta/meta.dart';
import 'package:norms_data/norms_data.dart';

/// Code of a circuit or incomer check.
enum CheckCode() {
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
final class const Check({
  /// Check code.
  required final CheckCode code,

  /// Outcome.
  required final CheckStatus status,

  /// Russian explanation for the user and the report.
  required final String message,

  /// Checked value (current, %, A …), if numeric.
  final double? value,

  /// Limit the value is compared against.
  final double? limit,

  /// Clause of the norm.
  final String? reference,
}) {
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
final class const Issue({
  /// Severity.
  required final IssueSeverity severity,

  /// Stable code for tests and UI.
  required final String code,

  /// Russian message.
  required final String message,

  /// Related circuit.
  final String? circuitId,

  /// Related device.
  final String? deviceId,
}) {
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
final class const Assumption({
  /// Stable code.
  required final String code,

  /// Russian text.
  required final String message,
}) {
  /// Serializes to JSON.
  Json toJson() => {'code': code, 'message': message};
}

/// Residual current protection of a circuit.
@immutable
final class const RcdResult({
  /// Rated residual operating current IΔn, mA.
  required final double residualMa,

  /// RCD type (`A`).
  required final String type,

  /// Why the RCD is required (Russian, with references).
  required final List<String> reasons,

  /// Rated current of a separate RCD, A; `null` for RCBO or grouped RCD.
  final double? ratedA,

  /// Id of the shared RCD for the grouped strategy.
  final String? groupId,
}) {
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
final class const ProtectionResult({
  /// Device type.
  required final ProtectionDevice device,

  /// Rated current In, A.
  required final double breakerA,

  /// Tripping curve.
  required final BreakerCurve curve,

  /// Number of protected poles (1 or 3; RCBO 1P+N counts as 1).
  required final int poles,

  /// Whether rating/curve were set manually.
  required final ValueSource breakerSource,

  /// Residual current protection, if any.
  final RcdResult? rcd,
}) {
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
final class const CableResult({
  /// Conductor material.
  required final ConductorMaterial material,

  /// Insulation.
  required final Insulation insulation,

  /// Installation method id.
  required final String installationMethodId,

  /// Reference method of ГОСТ Р 50571.5.52.
  required final ReferenceMethod referenceMethod,

  /// Number of cores (3 or 5).
  required final int cores,

  /// Line conductor section, mm².
  required final double sectionMm2,

  /// Protective conductor section, mm².
  required final double peSectionMm2,

  /// Automatic or manual section.
  required final ValueSource sectionSource,

  /// Voltage drop limit, %.
  required final double voltageDropLimitPercent,

  /// Checks.
  required final List<Check> checks,

  /// Length, m.
  final double? lengthM,

  /// Tabulated current Iтабл, A.
  final double? tabulatedA,

  /// Ambient temperature factor.
  final double? temperatureFactor,

  /// Grouping factor.
  final double? groupingFactor,

  /// Soil resistivity factor (cables in the ground).
  final double? soilFactor,

  /// Corrected current-carrying capacity Iz, A.
  final double? ampacityA,

  /// Voltage drop including the incomer cable, %.
  final double? voltageDropPercent,

  /// Phase–PE loop impedance at the end of the line, Ом.
  final double? loopImpedanceOhm,

  /// Minimum prospective fault current at the end of the line, A.
  final double? faultCurrentMinA,

  /// Current guaranteeing instantaneous tripping of the breaker, A.
  final double? instantaneousTripA,
}) {
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
final class const CircuitResult({
  /// Stable id (key of `CircuitSettings`).
  required final String id,

  /// Number in the panel, from 1.
  required final int number,

  /// Name for the user.
  required final String name,

  /// Purpose.
  required final CircuitPurpose purpose,

  /// Rooms served.
  required final List<String> roomIds,

  /// Devices served.
  required final List<String> deviceIds,

  /// 1 or 3.
  required final int phases,

  /// Phase of a single-phase circuit; `null` for three-phase circuits.
  required final Phase? phase,

  /// Automatic or manual phase.
  required final ValueSource phaseSource,

  /// Sum of rated powers, Вт.
  required final double installedPowerW,

  /// Design current IB with Kс = 1 (СП 256, 7.2.2), A.
  required final double designCurrentA,

  /// Expected current with usage factors, A (phase balancing, input estimate).
  required final double demandCurrentA,

  /// Resulting power factor.
  required final double cosPhi,

  /// Peak starting current of the circuit, A.
  required final double startingCurrentA,

  /// Protection.
  required final ProtectionResult protection,

  /// Cable.
  required final CableResult cable,

  /// Circuit-level checks (protection); cable checks are in [cable].
  required final List<Check> checks,

  /// Overall status.
  required final CalculationStatus status,
}) {
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
final class const SharedRcdResult({
  /// Id.
  required final String id,

  /// Rated current, A.
  required final double ratedA,

  /// IΔn, mA.
  required final double residualMa,

  /// Type (`A`).
  required final String type,

  /// 2 or 4.
  required final int poles,

  /// Circuits behind the RCD (empty for the incomer RCD: all circuits).
  required final List<String> circuitIds,

  /// Estimated leakage current, mA (СП 256 А.1.2).
  required final double leakageMa,

  /// Time-delayed (S) for selectivity.
  final bool selective = false,
}) {
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
final class const PhaseBalanceResult({
  /// Demand current per phase, A.
  required final Map<Phase, double> loadsA,

  /// (max − min) / max · 100.
  required final double imbalancePercent,

  /// Limit used for the warning, % (СП 256 п. 10.5).
  required final double limitPercent,
}) {
  /// Serializes to JSON.
  Json toJson() => {
    'loads_a': {for (final e in loadsA.entries) e.key.name: e.value},
    'imbalance_percent': imbalancePercent,
    'limit_percent': limitPercent,
  };
}

/// Input (incomer) calculation.
@immutable
final class const IncomerResult({
  /// Sum of rated powers, Вт.
  required final double installedPowerW,

  /// Σ P·ku, Вт (upper estimate).
  required final double demandByDevicesW,

  /// Design load by СП 256, Вт; used to select the incomer.
  required final double demandNormativeW,

  /// How [demandNormativeW] was obtained (Russian, with references).
  required final String normativeMethod,

  /// Power factor of the input.
  required final double cosPhi,

  /// Design current of the most loaded phase, A.
  required final double designCurrentA,

  /// Incomer breaker rating, A.
  required final double? breakerA,

  /// Existing (manual) or selected.
  required final ValueSource breakerSource,

  /// Checks.
  required final List<Check> checks,

  /// Incomer cable, if requested.
  final CableResult? cable,
}) {
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
final class const ProjectResult({
  /// Algorithm version.
  required final String algorithmVersion,

  /// Versions of the normative datasets.
  required final Map<String, String> datasetVersions,

  /// U0, В.
  required final double phaseVoltageV,

  /// Line voltage, В.
  required final double lineVoltageV,

  /// Circuits ordered by number.
  required final List<CircuitResult> circuits,

  /// Shared RCDs of the grouped strategy.
  required final List<SharedRcdResult> sharedRcds,

  /// Input.
  required final IncomerResult incomer,

  /// Issues.
  required final List<Issue> issues,

  /// Assumptions.
  required final List<Assumption> assumptions,

  /// Overall status (worst of all circuits and the incomer).
  required final CalculationStatus status,

  /// Fire-protection RCD at the input.
  final SharedRcdResult? fireRcd,

  /// Phase balance (three-phase supply).
  final PhaseBalanceResult? phaseBalance,
}) {
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
