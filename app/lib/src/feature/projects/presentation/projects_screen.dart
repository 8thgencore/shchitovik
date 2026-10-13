import 'dart:async';

import 'package:common_translations/common_translations.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shchitovik/src/feature/project_io/presentation/project_files.dart';
import 'package:shchitovik/src/feature/projects/application/projects_service.dart';
import 'package:shchitovik/src/feature/projects/presentation/bloc/projects_list_bloc.dart';
import 'package:shchitovik/src/feature/projects/presentation/widget/create_project_sheet.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document_codec.dart';
import 'package:shchitovik/src/logic/app_router.dart';
import 'package:shchitovik/src/widget/confirm_delete.dart';
import 'package:shchitovik/src/widget/content_width.dart';
import 'package:shchitovik/src/widget/deferred_progress.dart';
import 'package:shchitovik/src/widget/dependencies_scope.dart';

/// Start screen with the list of the user's projects.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        ProjectsListBloc(service: DependenciesScope.of(context).projectsContainer.projectsService),
    child: const _ProjectsView(),
  );
}

class _ProjectsView extends StatelessWidget {
  const _ProjectsView();

  Future<void> _create(BuildContext context) async {
    final params = await CreateProjectSheet.show(context);
    if (params == null || !context.mounted) return;
    final created = Completer<String>();
    context.read<ProjectsListBloc>().add(
      ProjectCreateRequested(
        name: params.name,
        objectType: params.objectType,
        supplyPhases: params.supplyPhases,
        created: created,
      ),
    );
    final id = await created.future;
    if (context.mounted) context.go(AppRoutes.projectSetup(id));
  }

  Future<void> _import(BuildContext context) async {
    final t = context.translations;
    final messenger = ScaffoldMessenger.of(context);
    final contents = await ProjectFiles.pickProjectFile();
    if (contents == null || !context.mounted) return;
    final imported = Completer<ProjectDocument>();
    context.read<ProjectsListBloc>().add(ProjectImportRequested(contents, imported));
    try {
      final document = await imported.future;
      messenger.showSnackBar(SnackBar(content: Text(t.projectsImported(document.name))));
    } on ProjectFormatException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.projectsImportFailed(e.message)),
          action: SnackBarAction(
            label: t.projectsImportPickAnother,
            onPressed: () {
              if (context.mounted) unawaited(_import(context));
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final projects = context.watch<ProjectsListBloc>().state.projects;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.projectsTitle),
        actions: [
          IconButton(
            tooltip: t.projectsImport,
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () => _import(context),
          ),
          IconButton(
            tooltip: t.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: Text(t.projectsCreate),
      ),
      body: ContentWidth(
        child: switch (projects) {
          null => const DeferredProgress(),
          [] => const _EmptyProjects(),
          final list => _ProjectsList(projects: list),
        },
      ),
    );
  }
}

/// Projects in one bordered surface with hairlines between the rows.
class _ProjectsList extends StatelessWidget {
  const _ProjectsList({required this.projects});

  final List<ProjectSummary> projects;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            sliver: SliverList.separated(
              itemCount: projects.length,
              itemBuilder: (context, index) => _ProjectTile(project: projects[index]),
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects();

  Future<void> _demo(BuildContext context, DemoProjectKind kind) async {
    final created = Completer<String>();
    context.read<ProjectsListBloc>().add(ProjectDemoRequested(kind, created));
    final id = await created.future;
    if (context.mounted) context.go(AppRoutes.projectCircuits(id));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.projectsEmpty, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(t.projectsEmptyHint, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Text(t.projectsDemoTitle),
            const SizedBox(height: 8),
            for (final (kind, label) in [
              (DemoProjectKind.oneRoomApartment, t.projectsDemoOneRoom),
              (DemoProjectKind.threeRoomApartment, t.projectsDemoThreeRoom),
              (DemoProjectKind.house, t.projectsDemoHouse),
            ])
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(onPressed: () => _demo(context, kind), child: Text(label)),
              ),
          ],
        ),
      ),
    );
  }
}

enum _ProjectAction { duplicate, export, delete }

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project});

  final ProjectSummary project;

  Future<void> _onAction(BuildContext context, _ProjectAction action) async {
    final bloc = context.read<ProjectsListBloc>();
    switch (action) {
      case _ProjectAction.duplicate:
        bloc.add(ProjectDuplicateRequested(project.id));
      case _ProjectAction.export:
        final service = DependenciesScope.of(context).projectsContainer.projectsService;
        await ProjectFiles.shareProject(
          projectName: project.name,
          contents: await service.export(project.id),
        );
      case _ProjectAction.delete:
        final t = context.translations;
        final confirmed = await confirmDelete(
          context,
          title: t.projectDeleteTitle(project.name),
          message: t.projectDeleteMessage,
          confirmLabel: t.projectDeleteConfirm,
        );
        if (confirmed) bloc.add(ProjectDeleteRequested(project.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final local = project.updatedAt.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
    return ListTile(
      leading: Icon(switch (project.objectType) {
        ObjectType.apartment => Icons.apartment,
        ObjectType.house => Icons.house_outlined,
        ObjectType.garageWorkshop => Icons.garage_outlined,
        ObjectType.commercial => Icons.storefront_outlined,
      }),
      title: Text(project.name),
      subtitle: Text('${project.objectType.label} · ${t.projectsUpdated(date)}'),
      onTap: () => context.go(AppRoutes.projectCircuits(project.id)),
      trailing: PopupMenuButton<_ProjectAction>(
        onSelected: (a) => _onAction(context, a),
        itemBuilder: (_) => [
          PopupMenuItem(value: _ProjectAction.duplicate, child: Text(t.projectDuplicate)),
          PopupMenuItem(value: _ProjectAction.export, child: Text(t.projectExport)),
          PopupMenuItem(value: _ProjectAction.delete, child: Text(t.projectDeleteConfirm)),
        ],
      ),
    );
  }
}
