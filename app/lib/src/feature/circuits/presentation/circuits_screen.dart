import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
class CircuitsScreen extends StatelessWidget {
  const CircuitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectBloc>().state as ProjectReady;
    return context.isExpandedLayout
        ? _ExpandedCircuits(state: state)
        : _CompactCircuits(state: state);
  }
}

class _ExpandedCircuits extends StatelessWidget {
  const _ExpandedCircuits({required this.state});

  final ProjectReady state;

  @override
  Widget build(BuildContext context) {
    final result = state.result;
    final side = [
      _IncomerCard(result: result),
      if (result.issues.isNotEmpty || result.assumptions.isNotEmpty) _IssuesCard(result: result),
    ];
    final circuits = result.circuits.isEmpty
        ? _NoCircuits(projectId: state.document.id)
        : UiCard(child: _CircuitsTable(state: state));
    return PageBody(
      children: [
        UiCard(
          padding: const EdgeInsets.all(UiSpace.l),
          child: SwitchboardView(state: state),
        ),
        ...side,
        circuits,
      ],
    );
  }
}

/// Blocks stacked with the section gap.
class _Stack extends StatelessWidget {
  const _Stack({required this.children});

  final List<Widget> children;

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

class _CompactCircuits extends StatelessWidget {
  const _CompactCircuits({required this.state});

  final ProjectReady state;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final result = state.result;
    final showBoard = SettingsScope.of(context).general.circuitsView == CircuitsViewVO.board;
    final details = [
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
                    UiCard(
                      padding: const EdgeInsets.all(UiSpace.l),
                      child: SwitchboardView(state: state),
                    ),
                    ...details,
                  ]
                : [
                    ...details,
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

class _NoCircuits extends StatelessWidget {
  const _NoCircuits({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
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

class _IncomerCard extends StatelessWidget {
  const _IncomerCard({required this.result});

  final ProjectResult result;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final incomer = result.incomer;
    final balance = result.phaseBalance;
    final fireRcd = result.fireRcd;
    final issues = incomer.checks.where((c) => c.status != CheckStatus.passed).toList();
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
                value: incomer.breakerA == null ? '—' : formatNumber(incomer.breakerA, 0),
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

class _IssuesCard extends StatelessWidget {
  const _IssuesCard({required this.result});

  final ProjectResult result;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
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

String _circuitMeta(CircuitResult c) =>
    '${c.protection.description} · ${c.cable.label} мм²'
    '${c.cable.lengthM == null ? '' : ' · ${formatNumber(c.cable.lengthM)} м'}'
    ' · ${c.phase?.label ?? '3ф'}';

class _CircuitRow extends StatelessWidget {
  const _CircuitRow({required this.projectId, required this.circuit});

  final String projectId;
  final CircuitResult circuit;

  @override
  Widget build(BuildContext context) {
    final c = circuit;
    return UiListRow(
      number: '${c.number}',
      title: c.name,
      subtitle: _circuitMeta(c),
      trailing: Text('${formatNumber(c.designCurrentA)} А'),
      stripe: statusStripe(c.status),
      below: c.status == CalculationStatus.passed ? null : StatusBadge(c.status),
      onTap: () => context.go(AppRoutes.circuit(projectId, c.id)),
    );
  }
}

class _CircuitsTable extends StatelessWidget {
  const _CircuitsTable({required this.state});

  final ProjectReady state;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    return UiTable(
      minWidth: 760,
      columns: [
        UiTableColumn(label: t.columnNumber, width: 48, numeric: true),
        UiTableColumn(label: t.columnCircuit, flex: 3),
        UiTableColumn(label: t.columnProtection, flex: 3),
        UiTableColumn(label: t.columnCable, width: 104),
        UiTableColumn(label: t.columnLength, width: 88, numeric: true),
        UiTableColumn(label: t.columnPhase, width: 64),
        UiTableColumn(label: t.columnCurrent, width: 80, numeric: true),
        UiTableColumn(label: t.circuitStatus, width: 156),
      ],
      rows: [
        for (final c in state.result.circuits)
          UiTableRow(
            stripe: statusStripe(c.status),
            onTap: () => context.go(AppRoutes.circuit(state.document.id, c.id)),
            cells: [
              Text('${c.number}'),
              UiTableCell(c.name),
              UiTableCell(c.protection.description, muted: true),
              Text(c.cable.label, style: UiTextStyles.value),
              Text(c.cable.lengthM == null ? '—' : formatNumber(c.cable.lengthM)),
              Text(c.phase?.label ?? '3ф', style: UiTextStyles.value),
              Text(formatNumber(c.designCurrentA)),
              Align(alignment: Alignment.centerLeft, child: StatusBadge(c.status)),
            ],
          ),
      ],
    );
  }
}
