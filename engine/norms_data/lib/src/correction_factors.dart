import 'package:norms_data/src/enums.dart';
import 'package:norms_data/src/json_reading.dart';
import 'package:norms_data/src/table_lookup.dart';

/// Ambient temperature correction factors, ГОСТ Р 50571.5.52, табл. B.52.14 (air) and
/// B.52.15 (ground, cables in ducts; also applied to D2).
final class TemperatureFactors._(final _Steps _air, final _Steps _ground) {
  /// Parses the `temperature_factors` dataset.
  factory fromJson(JsonMap json) => TemperatureFactors._(
    _Steps.fromJson(object(json['air'])),
    _Steps.fromJson(object(json['ground'])),
  );

  /// Correction factor for [temperatureC], or `null` if the table has no value (too hot).
  ///
  /// Between steps the next higher temperature is used (conservative); below the first step
  /// the first step's factor is used.
  double? factor(CableEnvironment environment, Insulation insulation, double temperatureC) {
    final _Steps steps = environment == CableEnvironment.air ? _air : _ground;
    final int? index = indexOfStepAtOrAbove(steps.temperatures, temperatureC);
    if (index == null) return null;
    return steps.values[insulation]![index];
  }
}

final class _Steps(final List<double> temperatures, final Map<Insulation, List<double?>> values) {
  factory fromJson(JsonMap json) => _Steps(doubles(json['steps_c']), {
    for (final insulation in Insulation.values) insulation: nullableDoubles(json[insulation.key]),
  });
}

/// Soil thermal resistivity correction, ГОСТ Р 50571.5.52, табл. B.52.16 (methods D1, D2).
final class SoilResistivityFactors._(
  final List<double> _resistivity,
  final List<double> _inDuct,
  final List<double> _direct,
) {
  /// Parses the `soil_resistivity_factors` dataset.
  factory fromJson(JsonMap json) => SoilResistivityFactors._(
    doubles(json['resistivity_k_m_per_w']),
    doubles(json['in_duct']),
    doubles(json['direct_in_ground']),
  );

  /// Correction factor for soil resistivity [kMPerW], К·м/Вт; `null` above the table range.
  ///
  /// Between steps the next higher resistivity is used (conservative).
  double? factor(ReferenceMethod method, double kMPerW) {
    assert(method.isInGround, 'Soil correction applies to D1/D2 only');
    final int? index = indexOfStepAtOrAbove(_resistivity, kMPerW);
    if (index == null) return null;
    return (method == ReferenceMethod.d1 ? _inDuct : _direct)[index];
  }
}

/// Arrangement of grouped circuits in air, rows 1–5 of ГОСТ Р 50571.5.52, табл. B.52.17.
enum AirGroupingArrangement(
  /// Key used in the datasets.
  final String key,
) {
  /// Bunched in air, on a surface, embedded or enclosed (row 1, methods A–F).
  bunched('bunched'),

  /// Single layer on a wall, floor or unperforated tray (row 2).
  singleLayerOnWall('single_layer_on_wall'),

  /// Single layer fixed directly under a wooden ceiling (row 3).
  singleLayerUnderCeiling('single_layer_under_ceiling'),

  /// Single layer on a perforated tray (row 4).
  singleLayerPerforatedTray('single_layer_perforated_tray'),

  /// Single layer on a ladder support or cleats (row 5).
  singleLayerLadder('single_layer_ladder');

  /// Parses a dataset key.
  static AirGroupingArrangement fromKey(String key) => values.firstWhere((a) => a.key == key);
}

/// Spacing between cables laid in the ground, ГОСТ Р 50571.5.52, табл. B.52.18–B.52.19.
enum GroundSpacing() {
  touching,
  oneDiameter,
  m0125,
  m025,
  m05,
  m1,
}

/// Reduction factors for groups of circuits, ГОСТ Р 50571.5.52, табл. B.52.17–B.52.19.
final class GroupingFactors._(
  final List<double> _airCounts,
  final Map<AirGroupingArrangement, List<double?>> _air,
  final _GroundTable _direct,
  final _GroundTable _ducts,
) {
  /// Parses the `grouping_factors` dataset.
  factory fromJson(JsonMap json) {
    final JsonMap air = object(json['air']);
    return GroupingFactors._(
      doubles(air['counts']),
      {
        for (final row in objects(air['arrangements']))
          AirGroupingArrangement.fromKey(row['arrangement']! as String): nullableDoubles(
            row['factors'],
          ),
      },
      _GroundTable.fromJson(object(json['direct_in_ground']), const {
        'touching': GroundSpacing.touching,
        'one_diameter': GroundSpacing.oneDiameter,
        '0.125m': GroundSpacing.m0125,
        '0.25m': GroundSpacing.m025,
        '0.5m': GroundSpacing.m05,
      }),
      _GroundTable.fromJson(object(json['in_ducts_multicore']), const {
        'touching': GroundSpacing.touching,
        '0.25m': GroundSpacing.m025,
        '0.5m': GroundSpacing.m05,
        '1.0m': GroundSpacing.m1,
      }),
    );
  }

  /// Factor for [circuits] grouped circuits in air; `null` if the table gives none
  /// (rows 2–5 end at 9 circuits — the caller should fall back to [AirGroupingArrangement.bunched]).
  ///
  /// Between columns the next larger number of circuits is used (conservative).
  double? air(AirGroupingArrangement arrangement, int circuits) {
    if (circuits <= 1 && arrangement != AirGroupingArrangement.singleLayerUnderCeiling) return 1;
    final int? index = indexOfStepAtOrAbove(_airCounts, circuits);
    if (index == null) return null;
    return _air[arrangement]![index];
  }

  /// Factor for [circuits] cables laid directly in the ground (D2), табл. B.52.18.
  double? directInGround(int circuits, GroundSpacing spacing) => _direct.factor(circuits, spacing);

  /// Factor for [circuits] multicore cables in ducts in the ground (D1), табл. B.52.19 A.
  double? inDucts(int circuits, GroundSpacing spacing) => _ducts.factor(circuits, spacing);
}

final class _GroundTable(
  final List<double> counts,
  final List<GroundSpacing> spacings,
  final List<List<double?>> factors,
) {
  factory fromJson(JsonMap json, Map<String, GroundSpacing> spacingKeys) => _GroundTable(
    doubles(json['counts']),
    [for (final s in strings(json['spacing'])) spacingKeys[s]!],
    [for (final row in json['factors']! as List<Object?>) nullableDoubles(row)],
  );

  double? factor(int circuits, GroundSpacing spacing) {
    if (circuits <= 1) return 1;
    final int column = spacings.indexOf(spacing);
    final int? row = indexOfStepAtOrAbove(counts, circuits);
    if (column < 0 || row == null) return null;
    return factors[row][column];
  }
}
