import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/logic/app_router.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Estimate: scenario, total range, lines by category, composition options and warnings.
///
/// Expanded layout keeps the total and the options in a side column next to the lines.
class EstimateScreen extends StatelessWidget {
  const EstimateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProjectBloc>().state as ProjectReady;
    final estimate = state.estimate;
    final t = context.translations;
    final sections = [
      for (final (title, category, total) in [
        (t.estimateApparatus, EstimateCategory.apparatus, estimate.apparatusTotal),
        (t.estimateAuxiliary, EstimateCategory.auxiliary, estimate.auxiliaryTotal),
        (t.estimateCable, EstimateCategory.cable, estimate.cableTotal),
      ])
        if (estimate.lines.any((l) => l.category == category))
          _CategoryCard(state: state, title: title, category: category, total: total),
    ];
    final summary = [
      _ScenarioPicker(state: state),
      _TotalCard(estimate: estimate),
    ];
    final extras = [
      _OptionsCard(state: state),
      _WarningsCard(estimate: estimate),
    ];
    if (!context.isExpandedLayout) {
      return PageBody(children: [...summary, ...sections, ...extras]);
    }
    return PageBody(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < UiBreakpoints.twoColumns) {
              return _Column(children: [...summary, ...sections, ...extras]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Column(children: sections)),
                const SizedBox(width: UiSpace.l),
                SizedBox(width: 360, child: _Column(children: [...summary, ...extras])),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Cards stacked with the section gap.
class _Column extends StatelessWidget {
  const _Column({required this.children});

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

void _edit(BuildContext context, EstimateInput Function(EstimateInput) change) =>
    ProjectScope.edit(context, (d) => d.copyWith(estimate: change(d.estimate)));

class _ScenarioPicker extends StatelessWidget {
  const _ScenarioPicker({required this.state});

  final ProjectReady state;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    return UiSegmented<EstimateScenario>(
      label: t.estimateScenario,
      segments: [
        UiSegment(value: EstimateScenario.economy, label: t.scenarioEconomy),
        UiSegment(value: EstimateScenario.standard, label: t.scenarioStandard),
        UiSegment(value: EstimateScenario.premium, label: t.scenarioPremium),
      ],
      selected: state.document.estimate.scenario,
      onChanged: (v) => _edit(context, (e) => e.copyWith(scenario: v)),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.estimate});

  final EstimateResult estimate;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final c = context.uiColors;
    final total = estimate.total;
    final span = total.maxKopecks - total.minKopecks;
    return UiCard(
      title: t.estimateTotal,
      trailing: UiBadge(label: t.estimateModules(estimate.moduleUnits), tone: UiTone.neutral),
      padding: const EdgeInsets.fromLTRB(UiSpace.l, 0, UiSpace.l, UiSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '≈ ${formatRubles(total.typicalKopecks)}',
            style: UiTextStyles.readingLarge.copyWith(color: c.text),
          ),
          const SizedBox(height: UiSpace.m),
          UiRangeBar(
            position: span == 0 ? .5 : (total.typicalKopecks - total.minKopecks) / span,
            startLabel: formatRubles(total.minKopecks),
            endLabel: formatRubles(total.maxKopecks),
          ),
          const SizedBox(height: UiSpace.m),
          Text(t.estimateDisclaimer, style: UiTextStyles.caption.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.state,
    required this.title,
    required this.category,
    required this.total,
  });

  final ProjectReady state;
  final String title;
  final EstimateCategory category;
  final PriceRange total;

  @override
  Widget build(BuildContext context) {
    final lines = state.estimate.lines.where((l) => l.category == category).toList();
    return UiCard(
      child: UiDisclosure(
        initiallyExpanded: context.isExpandedLayout,
        title: title,
        subtitle: formatPriceRange(total),
        trailing: Text(formatRubles(total.typicalKopecks)),
        child: UiDivided(
          children: [
            for (final line in lines) _LineRow(projectId: state.document.id, line: line),
          ],
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.projectId, required this.line});

  final String projectId;
  final EstimateLine line;

  @override
  Widget build(BuildContext context) {
    final missing = line.missing.isNotEmpty;
    return UiListRow(
      dense: true,
      title: line.title,
      subtitle: missing
          ? '${line.description} — нет: ${line.missing.join(', ')}'
          : line.description,
      stripe: missing ? UiTone.warning : null,
      trailing: missing
          ? const Text('—')
          : Text(
              '${line.unit == 'м' ? '${formatNumber(line.quantity)} м\n' : ''}'
              '${formatRubles(line.total.typicalKopecks)}',
            ),
      chevron: line.requirement != null,
      onTap: line.requirement == null ? null : () => context.go(AppRoutes.slot(projectId, line.id)),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.state});

  final ProjectReady state;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final choices = state.document.estimate;
    return UiCard(
      title: t.estimateOptions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiDivided(
            topBorder: true,
            children: [
              UiSwitchRow(
                title: t.estimateVoltageRelay,
                value: choices.voltageRelay ?? true,
                onChanged: (v) => _edit(context, (e) => e.copyWith(voltageRelay: v)),
              ),
              UiSwitchRow(
                title: t.estimateSpd,
                value: state.estimate.lines.any((l) => l.id == 'aux/spd'),
                onChanged: (v) => _edit(context, (e) => e.copyWith(surgeProtection: v)),
              ),
              UiSwitchRow(
                title: t.estimateOverhead,
                value: choices.overheadSupply,
                onChanged: (v) => _edit(context, (e) => e.copyWith(overheadSupply: v)),
              ),
            ],
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.uiColors.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(UiSpace.l),
              child: UiSelect<String?>(
                label: t.estimateCableMark,
                value: choices.cableMarkId,
                options: [
                  (null, t.auto),
                  for (final m in state.catalog.cableMarks.where((m) => m.material == 'copper'))
                    (m.id, m.name),
                ],
                onChanged: (v) => _edit(context, (e) => e.copyWith(cableMarkId: v)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningsCard extends StatelessWidget {
  const _WarningsCard({required this.estimate});

  final EstimateResult estimate;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final c = context.uiColors;
    return UiCard(
      child: UiDisclosure(
        title: t.estimateWarnings,
        subtitle: '${estimate.warnings.length}',
        child: Padding(
          padding: const EdgeInsets.all(UiSpace.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final w in estimate.warnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: UiSpace.m),
                  child: UiNotice(tone: UiTone.warning, message: w.message),
                ),
              const SizedBox(height: UiSpace.xs),
              UiLabel(t.estimateNotIncluded),
              const SizedBox(height: UiSpace.xs),
              for (final item in estimate.notIncluded)
                Padding(
                  padding: const EdgeInsets.only(top: UiSpace.xs),
                  child: Text(
                    '— $item',
                    style: UiTextStyles.bodySmall.copyWith(color: c.text),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
