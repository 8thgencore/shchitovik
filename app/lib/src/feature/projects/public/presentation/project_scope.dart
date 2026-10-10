import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/widget/dependencies_scope.dart';

/// Provides [ProjectBloc] of one project to the project screens.
class ProjectScope extends StatelessWidget {
  const ProjectScope({required this.projectId, required this.child, super.key});

  /// Project id.
  final String projectId;

  /// Subtree.
  final Widget child;

  /// Sends an edit of the current project.
  static void edit(BuildContext context, ProjectDocument Function(ProjectDocument) transform) =>
      context.read<ProjectBloc>().add(ProjectEdited(transform));

  @override
  Widget build(BuildContext context) {
    final dependencies = DependenciesScope.of(context);
    return BlocProvider(
      key: ValueKey(projectId),
      create: (_) => ProjectBloc(
        projectId: projectId,
        projects: dependencies.projectsContainer.projectsService,
        catalog: dependencies.catalogContainer.catalogService,
      ),
      child: child,
    );
  }
}
