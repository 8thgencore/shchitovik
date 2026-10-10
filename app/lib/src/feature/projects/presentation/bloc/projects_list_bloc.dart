import 'dart:async';

import 'package:electrical_core/electrical_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shchitovik/src/feature/projects/application/projects_service.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';

/// Events of [ProjectsListBloc].
sealed class ProjectsListEvent {
  const ProjectsListEvent();
}

final class _ProjectsChanged extends ProjectsListEvent {
  const _ProjectsChanged(this.projects);

  final List<ProjectSummary> projects;
}

/// Creates an empty project; [created] completes with its id.
final class ProjectCreateRequested extends ProjectsListEvent {
  const ProjectCreateRequested({
    required this.name,
    required this.objectType,
    required this.supplyPhases,
    required this.created,
  });

  final String name;
  final ObjectType objectType;
  final SupplyPhases supplyPhases;
  final Completer<String> created;
}

/// Creates a demo project; [created] completes with its id.
final class ProjectDemoRequested extends ProjectsListEvent {
  const ProjectDemoRequested(this.kind, this.created);

  final DemoProjectKind kind;
  final Completer<String> created;
}

/// Duplicates a project.
final class ProjectDuplicateRequested extends ProjectsListEvent {
  const ProjectDuplicateRequested(this.id);

  final String id;
}

/// Deletes a project.
final class ProjectDeleteRequested extends ProjectsListEvent {
  const ProjectDeleteRequested(this.id);

  final String id;
}

/// Imports a `.shchitovik` file; [imported] completes with the new project or an error.
final class ProjectImportRequested extends ProjectsListEvent {
  const ProjectImportRequested(this.contents, this.imported);

  final String contents;
  final Completer<ProjectDocument> imported;
}

/// State: the project list (`null` while loading).
final class ProjectsListState {
  const ProjectsListState(this.projects);

  /// Projects, most recently updated first.
  final List<ProjectSummary>? projects;
}

/// Project list and actions on projects.
final class ProjectsListBloc extends Bloc<ProjectsListEvent, ProjectsListState> {
  ProjectsListBloc({required this._service}) : super(const ProjectsListState(null)) {
    on<_ProjectsChanged>((event, emit) => emit(ProjectsListState(event.projects)));
    on<ProjectCreateRequested>((event, _) async {
      final document = await _service.create(
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

  final ProjectsService _service;
  late final StreamSubscription<List<ProjectSummary>> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
