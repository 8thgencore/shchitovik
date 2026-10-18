import 'package:norms_data/src/enums.dart';
import 'package:norms_data/src/json_reading.dart';

/// Continuous current-carrying capacity of a single circuit, ГОСТ Р 50571.5.52,
/// табл. B.52.2–B.52.5 (methods A1–D2) and B.52.10–B.52.13 (method E, multicore).
///
/// Reference conditions: 30 °C in air, 20 °C in ground, soil 2,5 К·м/Вт.
final class AmpacityTable._(
  /// Dataset version, stored with calculation results.
  final String datasetVersion,

  /// Cross-sections covered by the tables, mm², ascending.
  final List<double> sections,
  final Map<_ColumnKey, List<double?>> _columns,
) {
  /// Parses the `ampacity` dataset.
  factory fromJson(JsonMap json) {
    final List<double> sections = doubles(json['sections_mm2']);
    final columns = <_ColumnKey, List<double?>>{};
    for (final JsonMap c in objects(json['columns'])) {
      final ({
        Insulation insulation,
        int loadedConductors,
        ConductorMaterial material,
        ReferenceMethod method,
      })
      key = (
        insulation: Insulation.values.firstWhere((i) => i.key == c['insulation']),
        material: ConductorMaterial.values.firstWhere((m) => m.key == c['material']),
        loadedConductors: c['loaded_conductors']! as int,
        method: ReferenceMethod.fromKey(c['method']! as String),
      );
      columns[key] = nullableDoubles(c['values_a']);
    }
    return AmpacityTable._(json['dataset_version']! as String, sections, columns);
  }

  /// Tabulated current, A, or `null` when the table has no value for this combination.
  ///
  /// [loadedConductors] is 2 for single-phase and 3 for three-phase circuits.
  double? currentA({
    required Insulation insulation,
    required ConductorMaterial material,
    required int loadedConductors,
    required ReferenceMethod method,
    required double sectionMm2,
  }) {
    final List<double?>? column =
        _columns[(
          insulation: insulation,
          material: material,
          loadedConductors: loadedConductors,
          method: method,
        )];
    final int index = sections.indexOf(sectionMm2);
    if (column == null || index < 0) {
      return null;
    }
    return column[index];
  }
}

typedef _ColumnKey = ({
  Insulation insulation,
  ConductorMaterial material,
  int loadedConductors,
  ReferenceMethod method,
});
