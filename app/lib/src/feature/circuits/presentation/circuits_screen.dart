import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shchitovik/src/feature/circuits/presentation/length_notice.dart';
import 'package:shchitovik/src/feature/circuits/presentation/review_notice.dart';
import 'package:shchitovik/src/feature/circuits/presentation/status_badge.dart';
import 'package:shchitovik/src/feature/circuits/presentation/switchboard_view.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/settings/domain/model/general.dart';
import 'package:shchitovik/src/feature/settings/presentation/settings_scope.dart';
import 'package:shchitovik/src/logic/app_router.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Switchboard, input, phases, assumptions and circuits.
///
/// Expanded layout shows the board above a table of circuits with the input beside it;
/// compact layout switches between the board and the list and remembers the choice.
class const CircuitsScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectBloc>().state as ProjectReady;
    return context.isExpandedLayout
        ? _ExpandedCircuits(state: state)
        : _CompactCircuits(state: state);
  }
}

class const _ExpandedCircuits({required final ProjectReady state}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ProjectResult result = state.result;
    final List<StatelessWidget> side = [
      _IncomerCard(result: result),
      if (result.issues.isNotEmpty || result.assumptions.isNotEmpty) _IssuesCard(result: result),
    ];
    final StatelessWidget circuits = result.circuits.isEmpty
        ? _NoCircuits(projectId: state.document.id)
        : UiCard(child: _CircuitsTable(state: state));
    return PageBody(
      children: [
        if (LoopReviewNotice.shows(state)) LoopReviewNotice(state: state),
        UiCard(
          padding: const EdgeInsets.all(UiSpace.l),
          child: SwitchboardView(state: state),
        ),
        ...side,
        if (LengthNotice.shows(state)) LengthNotice(state: state),
        circuits,
      ],
    );
  }
}

/// Blocks stacked with the section gap.
class const _Stack({required final List<Widget> children}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: UiSpace.l),
        children[i],
      ],
    ],
  );
}

class const _CompactCircuits({required final ProjectReady state}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final ProjectResult result = state.result;
    final showBoard = SettingsScope.of(context).general.circuitsView == CircuitsViewVO.board;
    final List<StatelessWidget> details = [
      _IncomerCard(result: result),
      if (result.issues.isNotEmpty || result.assumptions.isNotEmpty) _IssuesCard(result: result),
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(UiSpace.l, UiSpace.m, UiSpace.l, 0),
          child: UiSegmented<bool>(
            segments: [
              UiSegment(value: true, icon: UiIcons.board, label: t.circuitsViewBoard),
              UiSegment(value: false, icon: UiIcons.list, label: t.circuitsViewList),
            ],
            selected: showBoard,
            onChanged: (board) => SettingsScope.update(
              context,
              (settings) => settings.copyWith(
                general: settings.general.copyWith(
                  circuitsView: board ? CircuitsViewVO.board : CircuitsViewVO.list,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: PageBody(
            children: showBoard
                ? [
                    if (LoopReviewNotice.shows(state)) LoopReviewNotice(state: state),
                    UiCard(
                      padding: const EdgeInsets.all(UiSpace.l),
                      child: SwitchboardView(state: state),
                    ),
                    ...details,
                  ]
                : [
                    if (LoopReviewNotice.shows(state)) LoopReviewNotice(state: state),
                    ...details,
                    if (LengthNotice.shows(state)) LengthNotice(state: state),
                    if (result.circuits.isEmpty)
                      _NoCircuits(projectId: state.document.id)
                    else
                      UiCard(
                        child: UiDivided(
                          children: [
                            for (final c in result.circuits)
                              _CircuitRow(projectId: state.document.id, circuit: c),
                          ],
                        ),
                      ),
                  ],
          ),
        ),
      ],
    );
  }
}

class const _NoCircuits({required final String projectId}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    return UiCard(
      child: UiEmptyState(
        standalone: false,
        icon: UiIcons.circuits,
        title: t.circuitsEmpty,
        message: t.roomsEmpty,
        actions: [
          UiButton(
            label: t.circuitsEmptyAction,
            icon: UiIcons.add,
            onPressed: () => context.go(AppRoutes.projectRooms(projectId)),
          ),
        ],
      ),
    );
  }
}

String _kw(num watts) => formatNumber(watts / 1000, 2);

class const _IncomerCard({required final ProjectResult result}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final IncomerResult incomer = result.incomer;
    final PhaseBalanceResult? balance = result.phaseBalance;
    final SharedRcdResult? fireRcd = result.fireRcd;
    final List<Check> issues = incomer.checks.where((c) => c.status != CheckStatus.passed).toList();
    return UiCard(
      title: t.circuitsInput,
      trailing: StatusBadge(result.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiMetricGrid(
            metrics: [
              UiMetric(
                label: t.circuitsDesignCurrent,
                value: formatNumber(incomer.designCurrentA),
                unit: 'А',
              ),
              UiMetric(
                label: t.circuitsIncomer,
                value: incomer.breakerA == null ? '–' : formatNumber(incomer.breakerA, 0),
                unit: incomer.breakerA == null ? null : 'А',
              ),
              UiMetric(
                label: t.circuitsNormative,
                value: _kw(incomer.demandNormativeW),
                unit: 'кВт',
              ),
              UiMetric(
                label: t.circuitsInstalled,
                value: _kw(incomer.installedPowerW),
                unit: 'кВт',
              ),
            ],
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.uiColors.border)),
            ),
            child: UiKeyValueList(
              padding: const EdgeInsets.fromLTRB(UiSpace.l, UiSpace.s, UiSpace.l, UiSpace.m),
              entries: [
                (t.circuitsByDevices, '${_kw(incomer.demandByDevicesW)} кВт'),
                if (fireRcd != null)
                  (
                    t.circuitsFireRcd,
                    '${formatNumber(fireRcd.ratedA, 0)} А, ${formatNumber(fireRcd.residualMa, 0)} мА S',
                  ),
                if (balance != null)
                  (
                    t.circuitsPhases,
                    [
                      for (final e in balance.loadsA.entries)
                        '${e.key.label} ${formatNumber(e.value)}',
                    ].join(' · '),
                  ),
                if (balance != null)
                  (t.circuitsImbalance, '${formatNumber(balance.imbalancePercent, 0)} %'),
              ],
            ),
          ),
          if (issues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(UiSpace.l, 0, UiSpace.l, UiSpace.l),
              child: _Stack(
                children: [
                  for (final c in issues)
                    UiNotice(
                      boxed: true,
                      tone: c.status == CheckStatus.failed ? UiTone.danger : UiTone.warning,
                      message: c.message,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class const _IssuesCard({required final ProjectResult result}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    return UiCard(
      child: UiDisclosure(
        title: '${t.circuitsIssues} и ${t.circuitsAssumptions.toLowerCase()}',
        subtitle: '${result.issues.length} · ${result.assumptions.length}',
        child: Padding(
          padding: const EdgeInsets.all(UiSpace.l),
          child: _Stack(
            children: [
              for (final i in result.issues) UiNotice(tone: UiTone.warning, message: i.message),
              for (final a in result.assumptions) UiNotice(message: a.message),
            ],
          ),
        ),
      ),
    );
  }
}

String _circuitMeta(CommonTranslationsLocalizations t, CircuitResult c) =>
    '${c.protection.label} · ${c.cable.label} мм²'
    ' · ${c.cable.lengthM == null ? t.circuitLengthMissing : '${formatNumber(c.cable.lengthM)} м'}'
    ' · ${c.phase?.label ?? '3ф'}';

class const _CircuitRow({required final String projectId, required final CircuitResult circuit})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CircuitResult c = circuit;
    return UiListRow(
      number: '${c.number}',
      title: c.name,
      subtitle: _circuitMeta(context.translations, c),
      trailing: UiQuantity(formatNumber(c.designCurrentA), unit: 'А'),
      stripe: statusStripe(c.status),
      // «Requires review» is explained once above the list; the stripe marks the rows.
      below: c.status == CalculationStatus.passed || c.status == CalculationStatus.requiresReview
          ? null
          : StatusBadge(c.status),
      onTap: () => context.go(AppRoutes.circuit(projectId, c.id)),
    );
  }
}

class const _CircuitsTable({required final ProjectReady state}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final Map<String, String> roomNames = {
      for (final r in state.document.input.rooms) r.id: r.name,
    };
    final Color muted = context.uiColors.textMuted;
    return UiTable(
      minWidth: 760,
      columns: [
        UiTableColumn(label: t.columnNumber, width: 48, numeric: true),
        UiTableColumn(label: t.columnCircuit, flex: 3),
        UiTableColumn(label: t.columnProtection, flex: 3),
        UiTableColumn(label: t.columnCable, width: 112),
        UiTableColumn(label: t.columnPhase, width: 64),
        UiTableColumn(label: t.columnCurrent, width: 80, numeric: true),
        UiTableColumn(label: t.circuitStatus, width: 80),
      ],
      rows: [
        for (final (c, problem) in [for (final c in state.result.circuits) (c, _problem(c))])
          UiTableRow(
            stripe: statusStripe(c.status),
            onTap: () => context.go(AppRoutes.circuit(state.document.id, c.id)),
            cells: [
              Text('${c.number}', style: TextStyle(color: muted)),
              UiTableCell(
                c.name,
                strong: true,
                // A failed or doubtful check is what the row is about; rooms otherwise.
                detail:
                    problem?.message ??
                    (c.roomIds.isEmpty
                        ? null
                        : [for (final id in c.roomIds) ?roomNames[id]].join(', ')),
                detailColor: problem == null
                    ? null
                    : (problem.status == CheckStatus.failed ? UiTone.danger : UiTone.warning).color(
                        context.uiColors,
                      ),
              ),
              UiTableDetail(
                detail: c.protection.deviceSummary,
                child: Text(c.protection.label, style: UiTextStyles.valueStrong),
              ),
              UiTableDetail(
                detail: c.cable.lengthM == null
                    ? t.circuitLengthMissing
                    : '${formatNumber(c.cable.lengthM)} м',
                child: Text(c.cable.label, style: UiTextStyles.value),
              ),
              Text(c.phase?.label ?? '3ф', style: UiTextStyles.value),
              Text(formatNumber(c.designCurrentA)),
              Align(alignment: Alignment.centerLeft, child: StatusIcon(c.status)),
            ],
          ),
      ],
    );
  }
}

/// First failed check of the circuit, or else the first warning.
Check? _problem(CircuitResult c) =>
    c.allChecks.where((x) => x.status == CheckStatus.failed).firstOrNull ??
    c.allChecks.where((x) => x.status == CheckStatus.warning).firstOrNull;
