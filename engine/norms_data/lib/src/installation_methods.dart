import 'package:norms_data/src/correction_factors.dart';
import 'package:norms_data/src/enums.dart';
import 'package:norms_data/src/json_reading.dart';

/// User-facing way of laying a multicore cable, mapped to a reference method of
/// ГОСТ Р 50571.5.52 (табл. A.52.3, B.52.1).
final class InstallationMethod {
  const InstallationMethod({
    required this.id,
    required this.title,
    required this.referenceMethod,
    required this.environment,
    required this.groupingKey,
    required this.a523Items,
  });

  /// Parses one entry of the `installation_methods` dataset.
  factory InstallationMethod.fromJson(JsonMap json) => InstallationMethod(
    id: json['id']! as String,
    title: json['title']! as String,
    referenceMethod: ReferenceMethod.fromKey(json['reference_method']! as String),
    environment: json['environment'] == 'ground' ? CableEnvironment.ground : CableEnvironment.air,
    groupingKey: json['grouping']! as String,
    a523Items: [for (final i in json['a52_3_items']! as List<Object?>) i! as int],
  );

  /// Stable identifier stored in projects.
  final String id;

  /// Russian title for the UI.
  final String title;

  /// Reference method for the ampacity tables.
  final ReferenceMethod referenceMethod;

  /// Air or ground: selects temperature and grouping tables.
  final CableEnvironment environment;

  /// Grouping table row: an [AirGroupingArrangement] key, `direct_in_ground` or `in_ducts_multicore`.
  final String groupingKey;

  /// Items of табл. A.52.3 this method corresponds to.
  final List<int> a523Items;

  /// Arrangement for the air grouping table, or `null` for cables in the ground.
  AirGroupingArrangement? get airArrangement =>
      environment == CableEnvironment.air ? AirGroupingArrangement.fromKey(groupingKey) : null;
}
