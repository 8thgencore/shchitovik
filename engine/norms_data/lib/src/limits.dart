import 'package:norms_data/src/enums.dart';
import 'package:norms_data/src/json_reading.dart';

/// Permissible voltage drop from the building input (СП 256, п. 8.23).
final class VoltageDropLimits._({
  /// Limit for lighting, %.
  required final double lightingPercent,

  /// Limit for other loads, %.
  required final double otherPercent,

  /// Wiring length above which the allowance applies, m.
  required final double longLineThresholdM,

  /// Allowance per metre above the threshold, %.
  required final double longLinePercentPerM,

  /// Maximum allowance, %.
  required final double longLineMaxExtraPercent,

  /// Resistivity ρ1 in normal service, Ом·мм²/м (ГОСТ Р 50571.5.52, прил. G: 1,25·ρ20).
  required final Map<ConductorMaterial, double> formulaRho1,

  /// Reactance per unit length λ, Ом/м (прил. G: 0,08 мОм/м).
  required final double formulaLambdaOhmPerM,

  /// Power factor to use when it is unknown (прил. G: 0,8).
  required final double formulaDefaultCosPhi,
}) {
  /// Parses the `voltage_drop_limits` dataset.
  factory fromJson(JsonMap json) {
    final JsonMap base = object(json['from_building_input']);
    final JsonMap long = object(json['long_line_allowance']);
    final JsonMap formula = object(json['formula_g']);
    final JsonMap rho1 = object(formula['rho1_ohm_mm2_per_m']);
    return VoltageDropLimits._(
      formulaRho1: {for (final m in ConductorMaterial.values) m: toDouble(rho1[m.key])},
      formulaLambdaOhmPerM: toDouble(formula['lambda_mohm_per_m']) / 1000,
      formulaDefaultCosPhi: toDouble(formula['default_cos_phi']),
      lightingPercent: toDouble(base['lighting_percent']),
      otherPercent: toDouble(base['other_percent']),
      longLineThresholdM: toDouble(long['length_threshold_m']),
      longLinePercentPerM: toDouble(long['percent_per_m']),
      longLineMaxExtraPercent: toDouble(long['max_extra_percent']),
    );
  }

  /// Limit for a wiring of [lengthM] from the building input, %.
  double limitPercent({required bool lighting, required double lengthM}) {
    final double base = lighting ? lightingPercent : otherPercent;
    if (lengthM <= longLineThresholdM) return base;
    final double extra = (lengthM - longLineThresholdM) * longLinePercentPerM;
    return base + (extra > longLineMaxExtraPercent ? longLineMaxExtraPercent : extra);
  }
}

/// Minimum cross-sections (СП 256 табл. 15.3, п. 10.2, п. 15.3).
final class MinCrossSections._({
  /// Lighting group lines, copper, mm².
  required final double lightingCopper,

  /// Lighting group lines, aluminium alloys 8030/8176, mm².
  required final double lightingAluminiumAlloy,

  /// Socket group lines, copper, mm².
  required final double socketsCopper,

  /// Socket group lines, aluminium alloys 8030/8176, mm².
  required final double socketsAluminiumAlloy,

  /// Electric stove line, copper, mm² (п. 10.2).
  required final double electricStoveCopper,

  /// Electric stove line, aluminium alloys 8030/8176, mm² (п. 10.2).
  required final double electricStoveAluminiumAlloy,

  /// Aluminium conductors in feeders and distribution networks, mm² (п. 15.3).
  required final double aluminiumFeederMin,

  /// Aluminium conductors to individual engineering equipment, mm² (п. 15.3).
  required final double aluminiumEngineeringEquipmentMin,
}) {
  /// Parses the `min_cross_sections` dataset.
  factory fromJson(JsonMap json) {
    final List<JsonMap> rows = objects(json['table_15_3']);
    JsonMap row(String prefix) => rows.firstWhere((r) => (r['line']! as String).startsWith(prefix));
    final JsonMap lighting = row('Линии групповых сетей освещения');
    final JsonMap sockets = row('Линии групповых сетей розеток');
    final JsonMap stove = object(json['electric_stove_line']);
    final JsonMap al = object(json['aluminium_rules']);
    return MinCrossSections._(
      lightingCopper: toDouble(lighting['copper_mm2']),
      lightingAluminiumAlloy: toDouble(lighting['aluminium_alloy_8030_8176_mm2']),
      socketsCopper: toDouble(sockets['copper_mm2']),
      socketsAluminiumAlloy: toDouble(sockets['aluminium_alloy_8030_8176_mm2']),
      electricStoveCopper: toDouble(stove['copper_mm2']),
      electricStoveAluminiumAlloy: toDouble(stove['aluminium_alloy_8030_8176_mm2']),
      aluminiumFeederMin: toDouble(al['feeder_min_mm2']),
      aluminiumEngineeringEquipmentMin: toDouble(al['engineering_equipment_min_mm2']),
    );
  }

  /// Minimum for a group line by purpose and [material].
  double groupLine({required bool lighting, required ConductorMaterial material}) => switch ((
    lighting,
    material,
  )) {
    (true, ConductorMaterial.copper) => lightingCopper,
    (true, ConductorMaterial.aluminium) => lightingAluminiumAlloy,
    (false, ConductorMaterial.copper) => socketsCopper,
    (false, ConductorMaterial.aluminium) => socketsAluminiumAlloy,
  };
}

/// Nominal voltage option of the network.
final class const NominalVoltage({
  /// Identifier stored in projects (`u220_380`, `u230_400`).
  required final String id,

  /// Phase-to-neutral voltage U0, В.
  required final double phaseV,

  /// Line-to-line voltage, В.
  required final double lineV,

  /// Document defining this option.
  required final String document,
});

/// Standard series and nominal voltages.
final class ElectricalConstants._(
  /// Nominal voltage options (СП 256, п. 8.23).
  final List<NominalVoltage> voltageOptions,

  /// Standard cross-sections, mm², ascending.
  final List<double> standardSections,
) {
  /// Parses the `electrical_constants` dataset.
  factory fromJson(JsonMap json) => ElectricalConstants._(
    [
      for (final o in objects(json['nominal_voltage_options_v']))
        NominalVoltage(
          id: o['id']! as String,
          phaseV: toDouble(o['phase_v']),
          lineV: toDouble(o['line_v']),
          document: o['document']! as String,
        ),
    ],
    doubles(json['standard_sections_mm2']),
  );

  /// Option by [id].
  NominalVoltage voltage(String id) => voltageOptions.firstWhere((v) => v.id == id);
}
