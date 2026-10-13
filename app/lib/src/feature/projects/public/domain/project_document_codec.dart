import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';

/// Thrown when stored or imported project data cannot be read.
final class ProjectFormatException implements Exception {
  const ProjectFormatException(this.message);

  /// Russian message for the user.
  final String message;

  @override
  String toString() => 'ProjectFormatException: $message';
}

/// Serialization of [ProjectDocument] with schema versioning.
///
/// The same document schema is used in the database and inside `.shchitovik` files.
/// When `ProjectInput` or `EstimateInput` change incompatibly, bump [currentSchemaVersion]
/// and add a migration `vN → vN+1` to [_migrations]; older data is upgraded on read.
abstract final class ProjectDocumentCodec {
  /// Current schema version.
  static const currentSchemaVersion = 1;

  /// Migrations by source version: each converts a document JSON of version N to N + 1.
  static final Map<int, Map<String, Object?> Function(Map<String, Object?>)> _migrations = {};

  /// Encodes [document] with the current schema version.
  static Map<String, Object?> encode(ProjectDocument document) => {
    'schema_version': currentSchemaVersion,
    'id': document.id,
    'name': document.name,
    'note': document.note,
    'created_at': document.createdAt.toUtc().toIso8601String(),
    'updated_at': document.updatedAt.toUtc().toIso8601String(),
    'input': document.input.toJson(),
    'estimate': document.estimate.toJson(),
  };

  /// Decodes [json] of any supported version, migrating it to the current one.
  static ProjectDocument decode(Map<String, Object?> json) {
    final migrated = migrate(json);
    try {
      return ProjectDocument(
        id: migrated['id']! as String,
        name: migrated['name']! as String,
        note: migrated['note'] as String? ?? '',
        createdAt: DateTime.parse(migrated['created_at']! as String).toUtc(),
        updatedAt: DateTime.parse(migrated['updated_at']! as String).toUtc(),
        input: ProjectInput.fromJson(migrated['input']! as Map<String, Object?>),
        estimate: EstimateInput.fromJson(migrated['estimate'] as Map<String, Object?>? ?? const {}),
      );
    } on Object {
      throw const ProjectFormatException('Данные проекта повреждены или записаны не полностью');
    }
  }

  /// Upgrades [json] to [currentSchemaVersion].
  static Map<String, Object?> migrate(Map<String, Object?> json) {
    final version = json['schema_version'];
    if (version is! int || version < 1) {
      throw const ProjectFormatException('Неизвестная версия формата проекта');
    }
    if (version > currentSchemaVersion) {
      throw const ProjectFormatException(
        'Проект сохранён более новой версией приложения. Обновите приложение.',
      );
    }
    var result = json;
    for (var v = version; v < currentSchemaVersion; v++) {
      result = {..._migrations[v]!(result), 'schema_version': v + 1};
    }
    return result;
  }
}
