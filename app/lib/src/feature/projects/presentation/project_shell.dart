import 'package:common_translations/common_translations.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:shchitovik/src/feature/project_io/domain/project_file_codec.dart';
import 'package:shchitovik/src/feature/project_io/presentation/project_files.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/logic/app_router.dart';
import 'package:shchitovik/src/widget/dependencies_scope.dart';
import 'package:shchitovik/src/widget/window_size.dart';

/// Frame of a project around its sections Объект / Помещения / Линии / Смета.
///
/// Expanded layout: navigation rail, the switchboard is the home section.
/// Compact layout: step-by-step wizard with progress and «Назад / Далее».
class ProjectShell extends StatelessWidget {
  const ProjectShell({
    required this.projectId,
    required this.location,
    required this.child,
    super.key,
  });

  /// Project id.
  final String projectId;

  /// Current path, selects the section.
  final String location;

  /// Section content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frame = _Frame(projectId: projectId, location: location);
    return ProjectScope(
      projectId: projectId,
      child: context.isExpandedLayout
          ? _ExpandedProjectFrame(frame: frame, child: child)
          : _CompactProjectFrame(frame: frame, child: child),
    );
  }
}

/// Section of a project.
enum _Section { setup, rooms, circuits, estimate }

/// Where the frame is: project, section and whether the section root is shown.
final class _Frame {
  const _Frame({required this.projectId, required this.location});

  final String projectId;
  final String location;

  String path(_Section section) => switch (section) {
    _Section.setup => AppRoutes.projectSetup(projectId),
    _Section.rooms => AppRoutes.projectRooms(projectId),
    _Section.circuits => AppRoutes.projectCircuits(projectId),
    _Section.estimate => AppRoutes.projectEstimate(projectId),
  };

  _Section get section =>
      _Section.values.where((s) => location.startsWith(path(s))).firstOrNull ?? _Section.circuits;

  bool get isSectionRoot => _Section.values.any((s) => location == path(s));

  /// From a section root back to the projects, from a nested page (opened with `go`, so
  /// there is nothing to pop) back to its section.
  void back(BuildContext context) => context.go(isSectionRoot ? AppRoutes.projects : path(section));
}

class _ProjectBody extends StatelessWidget {
  const _ProjectBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => switch (context.watch<ProjectBloc>().state) {
    ProjectLoading() => const Center(child: CircularProgressIndicator()),
    ProjectNotFound() => Center(child: Text(context.translations.projectNotFound)),
    ProjectReady() => child,
  };
}

// Expanded layout.

class _ExpandedProjectFrame extends StatelessWidget {
  const _ExpandedProjectFrame({required this.frame, required this.child});

  final _Frame frame;
  final Widget child;

  /// The switchboard comes first: it is the home section on a large screen.
  static const _order = [_Section.circuits, _Section.rooms, _Section.setup, _Section.estimate];

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final state = context.watch<ProjectBloc>().state;
    final labels = {
      _Section.circuits: t.tabBoard,
      _Section.rooms: t.tabRooms,
      _Section.setup: t.tabSetup,
      _Section.estimate: t.tabEstimate,
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => frame.back(context),
        ),
        title: Text(
          state is ProjectReady
              ? '${state.document.name} · ${labels[frame.section]}'
              : labels[frame.section]!,
        ),
        actions: [_ProjectActions(projectId: frame.projectId)],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _order.indexOf(frame.section),
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (i) => context.go(frame.path(_order[i])),
            destinations: [
              for (final section in _order)
                NavigationRailDestination(
                  icon: Icon(_sectionIcon(section)),
                  label: Text(labels[section]!),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _ProjectBody(child: child)),
        ],
      ),
    );
  }
}

IconData _sectionIcon(_Section section) => switch (section) {
  _Section.setup => Icons.home_work_outlined,
  _Section.rooms => Icons.meeting_room_outlined,
  _Section.circuits => Icons.view_module_outlined,
  _Section.estimate => Icons.receipt_long_outlined,
};

// Compact layout.

class _CompactProjectFrame extends StatelessWidget {
  const _CompactProjectFrame({required this.frame, required this.child});

  final _Frame frame;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectBloc>().state;
    final ready = state is ProjectReady && frame.isSectionRoot ? state : null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => frame.back(context),
        ),
        title: Text(state is ProjectReady ? state.document.name : ''),
        actions: [_ProjectActions(projectId: frame.projectId)],
        bottom: ready == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(76),
                child: _StepsHeader(frame: frame, state: ready),
              ),
      ),
      body: _ProjectBody(child: child),
      bottomNavigationBar: ready == null ? null : _StepsNavigation(frame: frame, state: ready),
    );
  }
}

/// Step names in wizard order.
String _stepName(BuildContext context, _Section section) {
  final t = context.translations;
  return switch (section) {
    _Section.setup => t.tabSetup,
    _Section.rooms => t.tabRooms,
    _Section.circuits => t.tabCircuits,
    _Section.estimate => t.tabEstimate,
  };
}

bool _stepDone(_Section section, ProjectReady state) => switch (section) {
  _Section.setup => true,
  _Section.rooms => state.document.input.rooms.isNotEmpty,
  _Section.circuits =>
    state.result.circuits.isNotEmpty && state.result.status != CalculationStatus.failed,
  _Section.estimate => state.estimate.lines.every((l) => l.missing.isEmpty),
};

String _stepSummary(BuildContext context, _Section section, ProjectReady state) {
  final t = context.translations;
  final input = state.document.input;
  final circuits = state.result.circuits;
  return switch (section) {
    _Section.setup => input.objectType.label,
    _Section.rooms => t.stepRoomsSummary(input.rooms.length, input.devices.length),
    _Section.circuits => t.stepCircuitsSummary(
      circuits.length,
      circuits.where((c) => c.status == CalculationStatus.failed).length,
    ),
    _Section.estimate => '≈ ${formatRubles(state.estimate.total.typicalKopecks)}',
  };
}

class _StepsHeader extends StatelessWidget {
  const _StepsHeader({required this.frame, required this.state});

  final _Frame frame;
  final ProjectReady state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    child: Row(
      children: [
        for (final section in _Section.values)
          Expanded(
            child: _StepIndicator(frame: frame, section: section, state: state),
          ),
      ],
    ),
  );
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.frame, required this.section, required this.state});

  final _Frame frame;
  final _Section section;
  final ProjectReady state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = section == frame.section;
    final done = _stepDone(section, state);
    final first = section == _Section.values.first;
    final last = section == _Section.values.last;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(frame.path(section)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: first ? Colors.transparent : scheme.outline)),
              CircleAvatar(
                radius: 13,
                backgroundColor: current
                    ? scheme.primary
                    : done
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                child: done && !current
                    ? Icon(Icons.check, size: 16, color: scheme.onPrimaryContainer)
                    : Text(
                        '${section.index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          color: current ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
              ),
              Expanded(child: Divider(color: last ? Colors.transparent : scheme.outline)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _stepName(context, section),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: current ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _stepSummary(context, section, state),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StepsNavigation extends StatelessWidget {
  const _StepsNavigation({required this.frame, required this.state});

  final _Frame frame;
  final ProjectReady state;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final section = frame.section;
    final failed = state.result.circuits.where((c) => c.status == CalculationStatus.failed);
    final hint = switch (section) {
      _Section.rooms when state.document.input.rooms.isEmpty => t.stepNeedRooms,
      _Section.circuits when failed.isNotEmpty => t.stepFailedCircuits(
        failed.map((c) => '№${c.number}').join(', '),
      ),
      _ => null,
    };
    final previous = section.index > 0 ? _Section.values[section.index - 1] : null;
    final next = section.index < _Section.values.length - 1
        ? _Section.values[section.index + 1]
        : null;
    return Material(
      elevation: 3,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Expanded(child: Text(hint)),
                    ],
                  ),
                ),
              Row(
                children: [
                  if (previous != null)
                    OutlinedButton.icon(
                      onPressed: () => context.go(frame.path(previous)),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(t.stepBack),
                    ),
                  const Spacer(),
                  if (next != null)
                    FilledButton.icon(
                      onPressed: () => context.go(frame.path(next)),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(_stepName(context, next)),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _ProjectActions.report(context, state),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(t.reportPdf),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Actions.

/// PDF report and project export buttons.
class _ProjectActions extends StatelessWidget {
  const _ProjectActions({required this.projectId});

  final String projectId;

  /// Builds the PDF report and offers to share it.
  static Future<void> report(BuildContext context, ProjectReady state) async {
    final messenger = ScaffoldMessenger.of(context);
    final t = context.translations;
    try {
      final bytes = await DependenciesScope.of(
        context,
      ).projectsContainer.reportService.build(state.document, catalog: state.catalog);
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${ProjectFileCodec.fileName(state.document.name).split('.').first}.pdf',
      );
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(t.reportFailed('$e'))));
    }
  }

  Future<void> _export(BuildContext context, ProjectReady state) async {
    final service = DependenciesScope.of(context).projectsContainer.projectsService;
    await ProjectFiles.shareProject(
      projectName: state.document.name,
      contents: await service.export(projectId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final state = context.watch<ProjectBloc>().state;
    if (state is! ProjectReady) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: t.reportPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: () => report(context, state),
        ),
        IconButton(
          tooltip: t.projectExport,
          icon: const Icon(Icons.ios_share),
          onPressed: () => _export(context, state),
        ),
      ],
    );
  }
}
