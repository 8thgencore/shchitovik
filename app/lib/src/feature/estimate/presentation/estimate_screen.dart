import 'package:common_translations/common_translations.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/logic/app_router.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Estimate: scenario, options, totals and lines.
class EstimateScreen extends StatelessWidget {
  const EstimateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final state = context.watch<ProjectBloc>().state as ProjectReady;
    final estimate = state.estimate;
    final choices = state.document.estimate;

    void edit(EstimateInput Function(EstimateInput) change) =>
        ProjectScope.edit(context, (d) => d.copyWith(estimate: change(d.estimate)));

    Widget section(String title, EstimateCategory category, PriceRange total) {
      final lines = estimate.lines.where((l) => l.category == category).toList();
      if (lines.isEmpty) return const SizedBox.shrink();
      return Card(
        child: ExpansionTile(
          title: Text(title),
          subtitle: Text(formatPriceRange(total)),
          children: [
            for (final line in lines)
              ListTile(
                dense: true,
                title: Text(line.title),
                subtitle: Text(
                  line.missing.isEmpty
                      ? line.description
                      : '${line.description} — нет: ${line.missing.join(', ')}',
                ),
                trailing: Text(
                  line.missing.isEmpty
                      ? '${line.unit == 'м' ? '${formatNumber(line.quantity)} м\n' : ''}${formatRubles(line.total.typicalKopecks)}'
                      : '—',
                  textAlign: TextAlign.end,
                ),
                onTap: line.requirement == null
                    ? null
                    : () => context.go(AppRoutes.slot(state.document.id, line.id)),
              ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: SegmentedButton<EstimateScenario>(
            segments: [
              ButtonSegment(value: EstimateScenario.economy, label: Text(t.scenarioEconomy)),
              ButtonSegment(value: EstimateScenario.standard, label: Text(t.scenarioStandard)),
              ButtonSegment(value: EstimateScenario.premium, label: Text(t.scenarioPremium)),
            ],
            selected: {choices.scenario},
            onSelectionChanged: (s) => edit((e) => e.copyWith(scenario: s.single)),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(t.estimateTotal, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(
              '${formatPriceRange(estimate.total)}\n${t.estimateTypical(formatRubles(estimate.total.typicalKopecks))}'
              '\n${t.estimateModules(estimate.moduleUnits)}',
            ),
            isThreeLine: true,
          ),
        ),
        section(t.estimateApparatus, EstimateCategory.apparatus, estimate.apparatusTotal),
        section(t.estimateAuxiliary, EstimateCategory.auxiliary, estimate.auxiliaryTotal),
        section(t.estimateCable, EstimateCategory.cable, estimate.cableTotal),
        Card(
          child: Column(
            children: [
              SectionTitle(t.estimateOptions),
              SwitchListTile(
                title: Text(t.estimateVoltageRelay),
                value: choices.voltageRelay ?? true,
                onChanged: (v) => edit((e) => e.copyWith(voltageRelay: v)),
              ),
              SwitchListTile(
                title: Text(t.estimateSpd),
                value: estimate.lines.any((l) => l.id == 'aux/spd'),
                onChanged: (v) => edit((e) => e.copyWith(surgeProtection: v)),
              ),
              SwitchListTile(
                title: Text(t.estimateOverhead),
                value: choices.overheadSupply,
                onChanged: (v) => edit((e) => e.copyWith(overheadSupply: v)),
              ),
              ChoiceField<String?>(
                label: t.estimateCableMark,
                value: choices.cableMarkId,
                options: [
                  (null, t.auto),
                  for (final m in state.catalog.cableMarks.where((m) => m.material == 'copper'))
                    (m.id, m.name),
                ],
                onChanged: (v) => edit((e) => e.copyWith(cableMarkId: v)),
              ),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            title: Text(t.estimateWarnings),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final w in estimate.warnings)
                Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• ${w.message}')),
              const SizedBox(height: 8),
              Text(t.estimateNotIncluded, style: Theme.of(context).textTheme.labelLarge),
              for (final item in estimate.notIncluded) Text('• $item'),
            ],
          ),
        ),
      ],
    );
  }
}
