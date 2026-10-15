import 'package:norms_data/src/correction_factors.dart';
import 'package:norms_data/src/enums.dart';
import 'package:norms_data/src/json_reading.dart';

/// User-facing way of laying a multicore cable, mapped to a reference method of
/// ГОСТ Р 50571.5.52 (табл. A.52.3, B.52.1).
final class const InstallationMethod({
  /// Stable identifier stored in projects.
  required final String id,

  /// Russian title for the UI.
  required final String title,

  /// Reference method for the ampacity tables.
  required final ReferenceMethod referenceMethod,

  /// Air or ground: selects temperature and grouping tables.
  required final CableEnvironment environment,

  /// Grouping table row: an [AirGroupingArrangement] key, `direct_in_ground` or `in_ducts_multicore`.
  required final String groupingKey,

  /// Items of табл. A.52.3 this method corresponds to.
  required final List<int> a523Items,
}) {
  /// Parses one entry of the `installation_methods` dataset.
  factory fromJson(JsonMap json) => InstallationMethod(
    id: json['id']! as String,
    title: json['title']! as String,
    referenceMethod: ReferenceMethod.fromKey(json['reference_method']! as String),
    environment: json['environment'] == 'ground' ? CableEnvironment.ground : CableEnvironment.air,
    groupingKey: json['grouping']! as String,
    a523Items: [for (final i in json['a52_3_items']! as List<Object?>) i! as int],
  );

  /// Arrangement for the air grouping table, or `null` for cables in the ground.
  AirGroupingArrangement? get airArrangement =>
      environment == CableEnvironment.air ? AirGroupingArrangement.fromKey(groupingKey) : null;
}
