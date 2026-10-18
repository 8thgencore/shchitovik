import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:printing/printing.dart';
import 'package:shchitovik/src/feature/project_io/domain/project_file_codec.dart';
import 'package:shchitovik/src/feature/project_io/presentation/project_files.dart';
import 'package:shchitovik/src/feature/projects/application/projects_service.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/logic/app_router.dart';
import 'package:shchitovik/src/widget/dependencies_scope.dart';

/// Frame of a project around its sections Объект / Помещения / Линии / Смета.
///
/// Expanded layout: sidebar with the sections, the switchboard is the home section.
/// Compact layout: step-by-step wizard with progress and «Назад / Далее».
class const ProjectShell({
  /// Project id.
  required final String projectId,

  /// Current path, selects the section.
  required final String location,

  /// Section content.
  required final Widget child,
  super.key,
}) extends StatelessWidget {
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
enum _Section() {
  setup,
  rooms,
  circuits,
  estimate,
}

/// Where the frame is: project, section and whether the section root is shown.
final class const _Frame({required final String projectId, required final String location}) {
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

class const _ProjectBody({required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (context.watch<ProjectBloc>().state) {
    ProjectLoading() => const UiDeferredProgress(),
    ProjectNotFound() => UiEmptyState(
      icon: UiIcons.projects,
      title: context.translations.projectNotFound,
      message: context.translations.projectNotFoundHint,
      actions: [
        UiButton(
          label: context.translations.projectsAll,
          icon: UiIcons.back,
          onPressed: () => context.go(AppRoutes.projects),
        ),
      ],
    ),
    ProjectReady() => child,
  };
}

class const _BackButton({required final _Frame frame}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => UiIconButton(
    icon: UiIcons.back,
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: () => frame.back(context),
  );
}

// Expanded layout.

class const _ExpandedProjectFrame({required final _Frame frame, required final Widget child})
    extends StatelessWidget {
  /// The switchboard comes first: it is the home section on a large screen.
  static const List<_Section> _order = [
    _Section.circuits,
    _Section.rooms,
    _Section.setup,
    _Section.estimate,
  ];

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final ProjectState state = context.watch<ProjectBloc>().state;
    final ProjectReady? ready = state is ProjectReady ? state : null;
    final Map<_Section, String> labels = {
      _Section.circuits: t.tabBoard,
      _Section.rooms: t.tabRooms,
      _Section.setup: t.tabSetup,
      _Section.estimate: t.tabEstimate,
    };
    final Map<_Section, int?> counts = {
      _Section.circuits: ready?.result.circuits.length,
      _Section.rooms: ready?.document.input.rooms.length,
    };
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiSidebar(
            brand: t.appTitle,
            header: ready == null ? null : _ProjectSummary(state: ready),
            items: [
              for (final section in _order)
                UiNavItem(
                  icon: _sectionIcon(section),
                  label: labels[section]!,
                  count: counts[section]?.toString(),
                  selected: section == frame.section,
                  onPressed: () => context.go(frame.path(section)),
                ),
            ],
            footer: [
              UiNavItem(
                icon: UiIcons.projects,
                label: t.projectsAll,
                onPressed: () => context.go(AppRoutes.projects),
              ),
              UiNavItem(
                icon: UiIcons.settings,
                label: t.settingsTitle,
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiTopBar(
                  large: true,
                  eyebrow: ready?.document.name,
                  title: labels[frame.section]!,
                  leading: frame.isSectionRoot ? null : _BackButton(frame: frame),
                  actions: [
                    if (ready != null) ...[
                      _ExportButton(projectId: frame.projectId, state: ready),
                      _ReportButton(state: ready, variant: _ReportVariant.secondary),
                    ],
                  ],
                ),
                Expanded(child: _ProjectBody(child: child)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Name and key facts of the project at the top of the sidebar.
class const _ProjectSummary({required final ProjectReady state}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final UiColors c = context.uiColors;
    final ProjectInput input = state.document.input;
    final String supply = input.supplyPhases == SupplyPhases.single
        ? t.supplySingle
        : t.supplyThree;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.document.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: UiTextStyles.bodySmall.copyWith(color: c.text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          '${input.objectType.label} · $supply',
          style: UiTextStyles.caption.copyWith(color: c.textMuted),
        ),
      ],
    );
  }
}

IconData _sectionIcon(_Section section) => switch (section) {
  _Section.setup => UiIcons.object,
  _Section.rooms => UiIcons.rooms,
  _Section.circuits => UiIcons.board,
  _Section.estimate => UiIcons.estimate,
};

// Compact layout.

class const _CompactProjectFrame({required final _Frame frame, required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ProjectState state = context.watch<ProjectBloc>().state;
    final ProjectReady? ready = state is ProjectReady ? state : null;
    final ProjectReady? root = ready != null && frame.isSectionRoot ? ready : null;
    return Scaffold(
      appBar: UiTopBar(
        leading: _BackButton(frame: frame),
        title: ready?.document.name ?? '',
        actions: [
          if (ready != null) ...[
            _ReportButton(state: ready, variant: _ReportVariant.icon),
            _ExportButton(projectId: frame.projectId, state: ready),
          ],
        ],
        bottom: root == null ? null : _StepsHeader(frame: frame, state: root),
      ),
      body: _ProjectBody(child: child),
      bottomNavigationBar: root == null ? null : _StepsNavigation(frame: frame, state: root),
    );
  }
}

/// Wizard progress under the top bar.
class const _StepsHeader({required final _Frame frame, required final ProjectReady state})
    extends StatelessWidget
    implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(UiStepBar.height);

  @override
  Widget build(BuildContext context) => UiStepBar(
    steps: [
      for (final section in _Section.values)
        UiStep(
          label: _stepName(context, section),
          summary: _stepSummary(context, section, state),
          state: section == frame.section
              ? UiStepState.current
              : _stepDone(section, state)
              ? UiStepState.done
              : UiStepState.upcoming,
        ),
    ],
    onSelected: (i) => context.go(frame.path(_Section.values[i])),
  );
}

/// Step names in wizard order.
String _stepName(BuildContext context, _Section section) {
  final CommonTranslationsLocalizations t = context.translations;
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
  final CommonTranslationsLocalizations t = context.translations;
  final ProjectInput input = state.document.input;
  final List<CircuitResult> circuits = state.result.circuits;
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

class const _StepsNavigation({required final _Frame frame, required final ProjectReady state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final _Section section = frame.section;
    final Iterable<CircuitResult> failed = state.result.circuits.where(
      (c) => c.status == CalculationStatus.failed,
    );
    final (String? hint, UiTone tone) = switch (section) {
      _Section.rooms when state.document.input.rooms.isEmpty => (t.stepNeedRooms, UiTone.warning),
      _Section.circuits when failed.isNotEmpty => (
        t.stepFailedCircuits(failed.map((c) => '№${c.number}').join(', ')),
        UiTone.danger,
      ),
      _ => (null, UiTone.neutral),
    };
    final _Section? previous = section.index > 0 ? _Section.values[section.index - 1] : null;
    final _Section? next = section.index < _Section.values.length - 1
        ? _Section.values[section.index + 1]
        : null;
    return UiActionBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null) ...[
            UiNotice(message: hint, tone: tone),
            const SizedBox(height: UiSpace.m),
          ],
          Row(
            children: [
              if (previous != null) ...[
                UiButton.secondary(
                  label: t.stepBack,
                  icon: UiIcons.back,
                  onPressed: () => context.go(frame.path(previous)),
                ),
                const SizedBox(width: UiSpace.s),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: next != null
                      ? UiButton(
                          label: switch (next) {
                            _Section.rooms => t.stepGoRooms,
                            _Section.circuits => t.stepGoCircuits,
                            _ => t.stepGoEstimate,
                          },
                          trailingIcon: UiIcons.next,
                          onPressed: () => context.go(frame.path(next)),
                        )
                      : _ReportButton(state: state, variant: _ReportVariant.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Actions.

/// Shares the project file.
class const _ExportButton({required final String projectId, required final ProjectReady state})
    extends StatelessWidget {
  Future<void> _export(BuildContext context) async {
    final ProjectsService service = DependenciesScope.of(context).projectsContainer.projectsService;
    await ProjectFiles.shareProject(
      projectName: state.document.name,
      contents: await service.export(projectId),
    );
  }

  @override
  Widget build(BuildContext context) => UiIconButton(
    tooltip: context.translations.projectExport,
    icon: UiIcons.share,
    onPressed: () => _export(context),
  );
}

enum _ReportVariant() {
  primary,
  secondary,
  icon,
}

/// Builds the PDF report and offers to share it; shows progress on the button meanwhile.
class const _ReportButton({
  required final ProjectReady state,
  required final _ReportVariant variant,
}) extends StatefulWidget {
  @override
  State<_ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState() extends State<_ReportButton> {
  var _busy = false;

  Future<void> _report() async {
    if (_busy) {
      return;
    }
    final CommonTranslationsLocalizations t = context.translations;
    final BuildContext toastContext = context;
    final ProjectDocument document = widget.state.document;
    setState(() => _busy = true);
    try {
      final Uint8List bytes = await DependenciesScope.of(
        context,
      ).projectsContainer.reportService.build(document, catalog: widget.state.catalog);
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${ProjectFileCodec.fileName(document.name).split('.').first}.pdf',
      );
    } on Object catch (e, stackTrace) {
      if (toastContext.mounted) {
        showUiToast(
          toastContext,
          message: t.reportFailed,
          actionLabel: t.copyErrorDetails,
          onAction: () => Clipboard.setData(ClipboardData(text: '$e\n$stackTrace')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final String label = _busy ? t.reportInProgress : t.reportPdf;
    return switch (widget.variant) {
      _ReportVariant.primary => UiButton(
        label: label,
        icon: UiIcons.report,
        busy: _busy,
        onPressed: _report,
      ),
      _ReportVariant.secondary => UiButton.secondary(
        label: label,
        icon: UiIcons.report,
        busy: _busy,
        onPressed: _report,
      ),
      _ReportVariant.icon => UiIconButton(
        tooltip: label,
        icon: UiIcons.report,
        busy: _busy,
        onPressed: _report,
      ),
    };
  }
}
