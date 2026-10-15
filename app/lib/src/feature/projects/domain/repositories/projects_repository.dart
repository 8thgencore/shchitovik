import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';

/// Persistent storage of projects.
abstract interface class ProjectsRepository() {
  /// Live list of projects, most recently updated first.
  Stream<List<ProjectSummary>> watchProjects();

  /// Live project; emits `null` when it is missing or deleted.
  Stream<ProjectDocument?> watchProject(String id);

  /// Project by [id]; `null` if missing or deleted.
  Future<ProjectDocument?> getProject(String id);

  /// Inserts or replaces [document].
  Future<void> save(ProjectDocument document);

  /// Deletes the project (soft delete).
  Future<void> delete(String id, {required DateTime at});
}
