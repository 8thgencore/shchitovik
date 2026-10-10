import 'dart:async';

import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shchitovik/src/feature/catalog_sync/application/catalog_service.dart';
import 'package:shchitovik/src/feature/projects/application/projects_service.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';

/// Events of [ProjectBloc].
sealed class ProjectEvent {
  const ProjectEvent();
}

/// The stored document changed (internal).
final class _DocumentChanged extends ProjectEvent {
  const _DocumentChanged(this.document);

  final ProjectDocument? document;
}

/// User edit of the project.
final class ProjectEdited extends ProjectEvent {
  const ProjectEdited(this.transform);

  /// Changes to apply.
  final ProjectDocument Function(ProjectDocument document) transform;
}

/// State of [ProjectBloc].
sealed class ProjectState {
  const ProjectState();
}

/// Loading the project.
final class ProjectLoading extends ProjectState {
  const ProjectLoading();
}

/// The project does not exist (deleted or wrong link).
final class ProjectNotFound extends ProjectState {
  const ProjectNotFound();
}

/// Project with its calculation and estimate.
final class ProjectReady extends ProjectState {
  const ProjectReady({
    required this.document,
    required this.result,
    required this.estimate,
    required this.catalog,
  });

  /// Stored document.
  final ProjectDocument document;

  /// Calculation result.
  final ProjectResult result;

  /// Estimate.
  final EstimateResult estimate;

  /// Catalog used for the estimate.
  final EstimateCatalog catalog;
}

/// Loads a project, recomputes it on every change and applies edits.
///
/// Results are derived, never stored: the document stream is the single source of truth.
final class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  ProjectBloc({required this.projectId, required this._projects, required this._catalog})
    : super(const ProjectLoading()) {
    on<_DocumentChanged>(_onDocumentChanged);
    on<ProjectEdited>(_onEdited);
    _subscription = _projects.watchProject(projectId).listen((d) => add(_DocumentChanged(d)));
  }

  /// Project id.
  final String projectId;

  final ProjectsService _projects;
  final CatalogService _catalog;
  late final StreamSubscription<ProjectDocument?> _subscription;

  Future<void> _onDocumentChanged(_DocumentChanged event, Emitter<ProjectState> emit) async {
    final document = event.document;
    if (document == null) {
      emit(const ProjectNotFound());
      return;
    }
    final catalog = await _catalog.current();
    final computed = await compute(_calculate, (document.input, document.estimate, catalog));
    emit(
      ProjectReady(
        document: document,
        result: computed.$1,
        estimate: computed.$2,
        catalog: catalog,
      ),
    );
  }

  Future<void> _onEdited(ProjectEdited event, Emitter<ProjectState> emit) async {
    await _projects.update(projectId, event.transform);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

(ProjectResult, EstimateResult) _calculate((ProjectInput, EstimateInput, EstimateCatalog) args) {
  final (input, estimate, catalog) = args;
  final result = calculateProject(input);
  return (result, calculateEstimate(input, result, estimate, catalog: catalog));
}
