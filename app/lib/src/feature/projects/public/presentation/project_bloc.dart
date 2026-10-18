import 'dart:async';

import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shchitovik/src/feature/catalog_sync/application/catalog_service.dart';
import 'package:shchitovik/src/feature/projects/application/projects_service.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';

/// Events of [ProjectBloc].
sealed class const ProjectEvent();

/// The stored document changed (internal).
final class const _DocumentChanged(final ProjectDocument? document) extends ProjectEvent;

/// User edit of the project.
final class const ProjectEdited(
  /// Changes to apply.
  final ProjectDocument Function(ProjectDocument document) transform,
) extends ProjectEvent;

/// State of [ProjectBloc].
sealed class const ProjectState();

/// Loading the project.
final class const ProjectLoading() extends ProjectState;

/// The project does not exist (deleted or wrong link).
final class const ProjectNotFound() extends ProjectState;

/// Project with its calculation and estimate.
final class const ProjectReady({
  /// Stored document.
  required final ProjectDocument document,

  /// Calculation result.
  required final ProjectResult result,

  /// Estimate.
  required final EstimateResult estimate,

  /// Catalog used for the estimate.
  required final EstimateCatalog catalog,
}) extends ProjectState;

/// Loads a project, recomputes it on every change and applies edits.
///
/// Results are derived, never stored: the document stream is the single source of truth.
final class ProjectBloc({
  /// Project id.
  required final String projectId,
  required final ProjectsService _projects,
  required final CatalogService _catalog,
}) extends Bloc<ProjectEvent, ProjectState> {
  this : super(const ProjectLoading()) {
    on<_DocumentChanged>(_onDocumentChanged);
    on<ProjectEdited>(_onEdited);
    _subscription = _projects.watchProject(projectId).listen((d) => add(_DocumentChanged(d)));
  }

  late final StreamSubscription<ProjectDocument?> _subscription;

  Future<void> _onDocumentChanged(_DocumentChanged event, Emitter<ProjectState> emit) async {
    final ProjectDocument? document = event.document;
    if (document == null) {
      emit(const ProjectNotFound());
      return;
    }
    final EstimateCatalog catalog = await _catalog.current();
    final (ProjectResult, EstimateResult) computed = await compute(_calculate, (
      document.input,
      document.estimate,
      catalog,
    ));
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
    await super.close();
  }
}

(ProjectResult, EstimateResult) _calculate((ProjectInput, EstimateInput, EstimateCatalog) args) {
  final (input, estimate, catalog) = args;
  final ProjectResult result = calculateProject(input);
  return (result, calculateEstimate(input, result, estimate, catalog: catalog));
}
