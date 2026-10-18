import 'dart:async';

import 'package:electrical_core/electrical_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shchitovik/src/feature/projects/application/projects_service.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';

/// Events of [ProjectsListBloc].
sealed class const ProjectsListEvent();

final class const _ProjectsChanged(final List<ProjectSummary> projects) extends ProjectsListEvent;

/// Creates an empty project; [created] completes with its id.
final class const ProjectCreateRequested({
  required final String name,
  required final ObjectType objectType,
  required final SupplyPhases supplyPhases,
  required final Completer<String> created,
}) extends ProjectsListEvent;

/// Creates a demo project; [created] completes with its id.
final class const ProjectDemoRequested(final DemoProjectKind kind, final Completer<String> created)
    extends ProjectsListEvent;

/// Duplicates a project.
final class const ProjectDuplicateRequested(final String id) extends ProjectsListEvent;

/// Deletes a project.
final class const ProjectDeleteRequested(final String id) extends ProjectsListEvent;

/// Imports a `.shchitovik` file; [imported] completes with the new project or an error.
final class const ProjectImportRequested(
  final String contents,
  final Completer<ProjectDocument> imported,
) extends ProjectsListEvent;

/// State: the project list (`null` while loading).
final class const ProjectsListState(
  /// Projects, most recently updated first.
  final List<ProjectSummary>? projects,
);

/// Project list and actions on projects.
final class ProjectsListBloc({required final ProjectsService _service})
    extends Bloc<ProjectsListEvent, ProjectsListState> {
  this : super(const ProjectsListState(null)) {
    on<_ProjectsChanged>((event, emit) => emit(ProjectsListState(event.projects)));
    on<ProjectCreateRequested>((event, _) async {
      final ProjectDocument document = await _service.create(
        name: event.name,
        objectType: event.objectType,
        supplyPhases: event.supplyPhases,
      );
      event.created.complete(document.id);
    });
    on<ProjectDemoRequested>((event, _) async {
      event.created.complete((await _service.createDemo(event.kind)).id);
    });
    on<ProjectDuplicateRequested>((event, _) => _service.duplicate(event.id));
    on<ProjectDeleteRequested>((event, _) => _service.delete(event.id));
    on<ProjectImportRequested>((event, _) async {
      try {
        event.imported.complete(await _service.import(event.contents));
      } on Object catch (e, s) {
        event.imported.completeError(e, s);
      }
    });
    _subscription = _service.watchProjects().listen((p) => add(_ProjectsChanged(p)));
  }

  late final StreamSubscription<List<ProjectSummary>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
