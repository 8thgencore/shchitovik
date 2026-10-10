import 'package:common_translations/common_translations.dart';
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
import 'package:shchitovik/src/widget/window_size.dart';

/// Switchboard, input, phases, assumptions and circuits.
///
/// Expanded layout shows the board above the list; compact layout switches between them and
/// remembers the choice in the settings.
class CircuitsScreen extends StatelessWidget {
  const CircuitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final state = context.watch<ProjectBloc>().state as ProjectReady;
    final result = state.result;
    const padding = EdgeInsets.fromLTRB(8, 8, 8, 24);
    final board = Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: SwitchboardView(state: state),
    );
    final details = [
      _IncomerCard(result: result),
      if (result.issues.isNotEmpty || result.assumptions.isNotEmpty) _IssuesCard(result: result),
    ];
    final circuits = [
      if (result.circuits.isEmpty)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t.circuitsEmpty)),
        ),
      for (final c in result.circuits) _CircuitTile(projectId: state.document.id, circuit: c),
    ];
    if (context.isExpandedLayout) {
      return ListView(padding: padding, children: [board, ...details, ...circuits]);
    }
    final showBoard = SettingsScope.of(context).general.circuitsView == CircuitsViewVO.board;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.view_module_outlined),
                label: Text(t.circuitsViewBoard),
              ),
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.list),
                label: Text(t.circuitsViewList),
              ),
            ],
            selected: {showBoard},
            onSelectionChanged: (s) => SettingsScope.update(
              context,
              (settings) => settings.copyWith(
                general: settings.general.copyWith(
                  circuitsView: s.single ? CircuitsViewVO.board : CircuitsViewVO.list,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: padding,
            children: showBoard ? [board, ...details] : [...details, ...circuits],
          ),
        ),
      ],
    );
  }
}

class _IncomerCard extends StatelessWidget {
  const _IncomerCard({required this.result});

  final ProjectResult result;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final incomer = result.incomer;
    final balance = result.phaseBalance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusIcon(result.status),
                const SizedBox(width: 8),
                Text(t.circuitsInput, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(result.status.label),
              ],
            ),
            const SizedBox(height: 8),
            _Row(t.circuitsInstalled, '${formatNumber(incomer.installedPowerW / 1000, 2)} кВт'),
            _Row(
              t.circuitsByDevices,
              '${formatNumber(incomer.demandByDevicesW / 1000, 2)} кВт',
            ),
            _Row(
              t.circuitsNormative,
              '${formatNumber(incomer.demandNormativeW / 1000, 2)} кВт',
            ),
            _Row(t.circuitsDesignCurrent, '${formatNumber(incomer.designCurrentA)} А'),
            _Row(
              t.circuitsIncomer,
              incomer.breakerA == null ? '—' : '${formatNumber(incomer.breakerA, 0)} А',
            ),
            if (result.fireRcd != null)
              _Row(
                t.circuitsFireRcd,
                '${formatNumber(result.fireRcd!.ratedA, 0)} А, ${formatNumber(result.fireRcd!.residualMa, 0)} мА S',
              ),
            if (balance != null)
              _Row(
                t.circuitsPhases,
                [
                  for (final e in balance.loadsA.entries)
                    '${e.key.label} ${formatNumber(e.value)} А',
                ].join(' · '),
              ),
            if (balance != null)
              _Row(t.circuitsImbalance, '${formatNumber(balance.imbalancePercent, 0)} %'),
            for (final c in incomer.checks.where((c) => c.status != CheckStatus.passed))
              Padding(padding: const EdgeInsets.only(top: 6), child: Text(c.message)),
          ],
        ),
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
    return Card(
      child: ExpansionTile(
        title: Text('${t.circuitsIssues} и ${t.circuitsAssumptions.toLowerCase()}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in result.issues)
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• ${i.message}')),
          for (final a in result.assumptions)
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• ${a.message}')),
        ],
      ),
    );
  }
}

class _CircuitTile extends StatelessWidget {
  const _CircuitTile({required this.projectId, required this.circuit});

  final String projectId;
  final CircuitResult circuit;

  @override
  Widget build(BuildContext context) {
    final c = circuit;
    return Card(
      child: ListTile(
        leading: StatusIcon(c.status),
        title: Text('${c.number}. ${c.name}'),
        subtitle: Text(
          '${c.protection.description} · ${c.cable.label} мм²'
          '${c.cable.lengthM == null ? '' : ' · ${formatNumber(c.cable.lengthM)} м'}'
          ' · ${c.phase?.label ?? '3ф'} · ${formatNumber(c.designCurrentA)} А',
        ),
        onTap: () => context.go(AppRoutes.circuit(projectId, c.id)),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}
