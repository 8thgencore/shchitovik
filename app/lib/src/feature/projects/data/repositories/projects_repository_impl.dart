import 'dart:convert';

import 'package:common_database/common_database.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:shchitovik/src/feature/projects/domain/repositories/projects_repository.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document_codec.dart';

/// [ProjectsRepository] backed by the drift database.
final class ProjectsRepositoryImpl implements ProjectsRepository {
  const ProjectsRepositoryImpl({required this.database});

  /// Database.
  final AppDatabase database;

  @override
  Stream<List<ProjectSummary>> watchProjects() => database.watchProjects().map(
    (rows) => [
      for (final row in rows)
        ProjectSummary(
          id: row.id,
          name: row.name,
          objectType: _objectType(row.inputJson),
          updatedAt: row.updatedAt,
        ),
    ],
  );

  @override
  Stream<ProjectDocument?> watchProject(String id) =>
      database.watchProject(id).map((row) => row == null ? null : _decode(row));

  @override
  Future<ProjectDocument?> getProject(String id) async {
    final row = await database.getProject(id);
    return row == null || row.isDeleted ? null : _decode(row);
  }

  @override
  Future<void> save(ProjectDocument document) {
    final json = ProjectDocumentCodec.encode(document);
    return database.upsertProject(
      ProjectsCompanion.insert(
        id: document.id,
        name: document.name,
        note: Value(document.note),
        schemaVersion: ProjectDocumentCodec.currentSchemaVersion,
        inputJson: jsonEncode(json['input']),
        estimateJson: jsonEncode(json['estimate']),
        createdAt: document.createdAt.toUtc(),
        updatedAt: document.updatedAt.toUtc(),
        isDeleted: const Value(false),
      ),
    );
  }

  @override
  Future<void> delete(String id, {required DateTime at}) =>
      database.softDeleteProject(id, at.toUtc());

  ProjectDocument _decode(ProjectRow row) => ProjectDocumentCodec.decode({
    'schema_version': row.schemaVersion,
    'id': row.id,
    'name': row.name,
    'note': row.note,
    'created_at': row.createdAt.toUtc().toIso8601String(),
    'updated_at': row.updatedAt.toUtc().toIso8601String(),
    'input': jsonDecode(row.inputJson),
    'estimate': jsonDecode(row.estimateJson),
  });

  static ObjectType _objectType(String inputJson) {
    final json = jsonDecode(inputJson) as Map<String, Object?>;
    return ObjectType.values.asNameMap()[json['object_type']] ?? ObjectType.apartment;
  }
}
