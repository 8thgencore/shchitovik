import 'package:clock/clock.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:shchitovik/src/feature/project_io/domain/project_file_codec.dart';
import 'package:shchitovik/src/feature/projects/domain/repositories/projects_repository.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';
import 'package:uuid/uuid.dart';

/// Demo project kinds offered on the first launch.
enum DemoProjectKind { oneRoomApartment, threeRoomApartment, house }

/// Use cases around projects: create, edit, duplicate, delete, import and export.
final class ProjectsService {
  ProjectsService({required this._repository, required this.appVersion, Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final ProjectsRepository _repository;
  final Uuid _uuid;

  /// Version written into exported files.
  final String appVersion;

  /// Live project list.
  Stream<List<ProjectSummary>> watchProjects() => _repository.watchProjects();

  /// Live project.
  Stream<ProjectDocument?> watchProject(String id) => _repository.watchProject(id);

  /// Creates an empty project.
  Future<ProjectDocument> create({
    required String name,
    required ObjectType objectType,
    required SupplyPhases supplyPhases,
  }) => _insert(name, ProjectInput(objectType: objectType, supplyPhases: supplyPhases));

  /// Creates a project from a demo.
  Future<ProjectDocument> createDemo(DemoProjectKind kind) => switch (kind) {
    DemoProjectKind.oneRoomApartment => _insert(
      'Демо: 1-комнатная квартира',
      DemoProjects.oneRoomApartment(),
    ),
    DemoProjectKind.threeRoomApartment => _insert(
      'Демо: 3-комнатная квартира',
      DemoProjects.threeRoomApartment(),
    ),
    DemoProjectKind.house => _insert('Демо: частный дом', DemoProjects.house()),
  };

  /// Applies [transform] to the stored project and saves it with a new update time.
  Future<ProjectDocument> update(
    String id,
    ProjectDocument Function(ProjectDocument) transform,
  ) async {
    final current = await _repository.getProject(id);
    if (current == null) throw StateError('Project $id not found');
    final updated = transform(current)
        .copyWith(id: id, createdAt: current.createdAt, updatedAt: clock.now().toUtc());
    await _repository.save(updated);
    return updated;
  }

  /// Copies the project under a new id and name.
  Future<ProjectDocument> duplicate(String id) async {
    final source = await _repository.getProject(id);
    if (source == null) throw StateError('Project $id not found');
    return _store(source.copyWith(name: '${source.name} (копия)'));
  }

  /// Deletes the project.
  Future<void> delete(String id) => _repository.delete(id, at: clock.now().toUtc());

  /// Contents of the `.shchitovik` file for the project.
  Future<String> export(String id) async {
    final document = await _repository.getProject(id);
    if (document == null) throw StateError('Project $id not found');
    return ProjectFileCodec.encode(document, appVersion: appVersion, exportedAt: clock.now());
  }

  /// Imports a `.shchitovik` file as a new project (never overwrites an existing one).
  ///
  /// Throws `ProjectFormatException` with a user-facing message for invalid files.
  Future<ProjectDocument> import(String contents) => _store(ProjectFileCodec.decode(contents));

  Future<ProjectDocument> _insert(String name, ProjectInput input) {
    final now = clock.now().toUtc();
    return _store(
      ProjectDocument(id: '', name: name, createdAt: now, updatedAt: now, input: input),
    );
  }

  Future<ProjectDocument> _store(ProjectDocument document) async {
    final now = clock.now().toUtc();
    final stored = document.copyWith(id: _uuid.v4(), createdAt: now, updatedAt: now);
    await _repository.save(stored);
    return stored;
  }
}
