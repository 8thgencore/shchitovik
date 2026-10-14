import 'dart:async';

import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
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
import 'package:shchitovik/src/widget/dependencies_scope.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

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
    final contents = await ProjectFiles.pickProjectFile();
    if (contents == null || !context.mounted) return;
    final imported = Completer<ProjectDocument>();
    context.read<ProjectsListBloc>().add(ProjectImportRequested(contents, imported));
    try {
      final document = await imported.future;
      if (context.mounted) showUiToast(context, message: t.projectsImported(document.name));
    } on ProjectFormatException catch (e) {
      if (!context.mounted) return;
      showUiToast(
        context,
        message: t.projectsImportFailed(e.message),
        actionLabel: t.projectsImportPickAnother,
        onAction: () {
          if (context.mounted) unawaited(_import(context));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final projects = context.watch<ProjectsListBloc>().state.projects;
    final expanded = context.isExpandedLayout;
    final hasProjects = projects != null && projects.isNotEmpty;
    final create = UiButton(
      label: t.projectsCreate,
      icon: UiIcons.add,
      expand: !expanded,
      onPressed: () => _create(context),
    );
    return Scaffold(
      appBar: UiTopBar(
        title: t.projectsTitle,
        large: expanded,
        actions: [
          UiIconButton(
            tooltip: t.projectsImport,
            icon: UiIcons.import,
            onPressed: () => _import(context),
          ),
          UiIconButton(
            tooltip: t.settingsOpen,
            icon: UiIcons.settings,
            onPressed: () => context.push(AppRoutes.settings),
          ),
          if (expanded && hasProjects) ...[const SizedBox(width: UiSpace.s), create],
        ],
      ),
      bottomNavigationBar: !expanded && hasProjects ? UiActionBar(child: create) : null,
      body: switch (projects) {
        null => const UiDeferredProgress(),
        [] => _EmptyProjects(onCreate: () => _create(context)),
        final list => _ProjectsList(projects: list),
      },
    );
  }
}

/// Projects in one bordered card with hairlines between the rows, newest first, with a search.
class _ProjectsList extends StatefulWidget {
  const _ProjectsList({required this.projects});

  final List<ProjectSummary> projects;

  @override
  State<_ProjectsList> createState() => _ProjectsListState();
}

class _ProjectsListState extends State<_ProjectsList> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final query = _query.trim().toLowerCase();
    final projects = [
      for (final p in widget.projects)
        if (query.isEmpty || p.name.toLowerCase().contains(query)) p,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return PageBody(
      maxWidth: 960,
      children: [
        UiTextField(
          controller: _search,
          label: t.projectsSearch,
          prefixIcon: UiIcons.search,
          help: t.projectsSorted,
          onChanged: (v) => setState(() => _query = v),
        ),
        UiCard(
          child: projects.isEmpty
              ? UiEmptyState(
                  standalone: false,
                  icon: UiIcons.search,
                  title: t.projectsNotFound(_query.trim()),
                  message: '',
                  actions: [UiButton.secondary(label: t.projectsSearchReset, onPressed: _reset)],
                )
              : UiDivided(children: [for (final p in projects) _ProjectTile(project: p)]),
        ),
      ],
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onCreate});

  final VoidCallback onCreate;

  Future<void> _demo(BuildContext context, DemoProjectKind kind) async {
    final created = Completer<String>();
    context.read<ProjectsListBloc>().add(ProjectDemoRequested(kind, created));
    final id = await created.future;
    if (context.mounted) context.go(AppRoutes.projectCircuits(id));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    return UiEmptyState(
      icon: UiIcons.board,
      title: t.projectsEmpty,
      message: t.projectsEmptyHint,
      actions: [UiButton(label: t.projectsCreate, icon: UiIcons.add, onPressed: onCreate)],
      footer: Column(
        children: [
          UiLabel(t.projectsDemoTitle),
          const SizedBox(height: UiSpace.s),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: UiSpace.s,
            runSpacing: UiSpace.s,
            children: [
              for (final (kind, label) in [
                (DemoProjectKind.oneRoomApartment, t.projectsDemoOneRoom),
                (DemoProjectKind.threeRoomApartment, t.projectsDemoThreeRoom),
                (DemoProjectKind.house, t.projectsDemoHouse),
              ])
                UiButton.secondary(label: label, onPressed: () => _demo(context, kind)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project});

  final ProjectSummary project;

  Future<void> _export(BuildContext context) async {
    final service = DependenciesScope.of(context).projectsContainer.projectsService;
    await ProjectFiles.shareProject(
      projectName: project.name,
      contents: await service.export(project.id),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final t = context.translations;
    final bloc = context.read<ProjectsListBloc>();
    final confirmed = await showUiConfirm(
      context,
      title: t.projectDeleteTitle(project.name),
      message: t.projectDeleteMessage,
      confirmLabel: t.projectDeleteConfirm,
      cancelLabel: t.cancel,
    );
    if (confirmed) bloc.add(ProjectDeleteRequested(project.id));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final local = project.updatedAt.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
    return UiListRow(
      leading: Icon(switch (project.objectType) {
        ObjectType.apartment => UiIcons.apartment,
        ObjectType.house => UiIcons.house,
        ObjectType.garageWorkshop => UiIcons.garage,
        ObjectType.commercial => UiIcons.shop,
      }),
      title: project.name,
      subtitle: '${project.objectType.label} · ${t.projectsUpdated(date)}',
      chevron: true,
      onTap: () => context.go(AppRoutes.projectCircuits(project.id)),
      trailing: UiMenuButton(
        tooltip: t.moreActions,
        entries: [
          UiMenuEntry(
            label: t.projectDuplicate,
            icon: UiIcons.copy,
            onPressed: () =>
                context.read<ProjectsListBloc>().add(ProjectDuplicateRequested(project.id)),
          ),
          UiMenuEntry(
            label: t.projectExport,
            icon: UiIcons.share,
            onPressed: () => _export(context),
          ),
          UiMenuEntry(
            label: t.projectDeleteConfirm,
            icon: UiIcons.delete,
            destructive: true,
            onPressed: () => _delete(context),
          ),
        ],
      ),
    );
  }
}
