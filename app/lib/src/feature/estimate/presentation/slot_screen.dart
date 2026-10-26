import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/logic/app_router.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Choice of a model for one estimate slot, or a custom price.
class const SlotScreen({
  /// Slot id.
  required final String slotId,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final state = context.watch<ProjectBloc>().state as ProjectReady;
    final EstimateLine? line = state.estimate.lines.where((l) => l.id == slotId).firstOrNull;
    final ApparatusRequirement? requirement = line?.requirement;
    if (line == null || requirement == null) {
      return UiEmptyState(icon: UiIcons.estimate, title: t.estimateNoModels, message: '');
    }
    final ApparatusSelection? selection = state.document.estimate.selections[slotId];
    final List<({Compatibility compatibility, ApparatusProduct product})> candidates =
        compatibleProducts(requirement, state.catalog);

    // Opened with `go` from the estimate, so there is nothing to pop.
    void back() => context.go(AppRoutes.projectEstimate(state.document.id));

    void select(ApparatusSelection? value) {
      ProjectScope.edit(context, (d) {
        final Map<String, ApparatusSelection> selections = {...d.estimate.selections}
          ..remove(slotId);
        if (value != null) {
          selections[slotId] = value;
        }
        return d.copyWith(estimate: d.estimate.copyWith(selections: selections));
      });
    }

    return PageBody(
      maxWidth: 840,
      children: [
        UiCard(
          eyebrow: t.estimateRequirement(requirement.label),
          title: line.title,
          child: UiDivided(
            topBorder: true,
            children: [
              UiChoiceRow(
                title: t.estimateResetSelection,
                subtitle: line.source == PriceSource.automatic ? line.description : null,
                selected: selection == null,
                onTap: () {
                  select(null);
                  back();
                },
              ),
              if (selection != null)
                Padding(
                  padding: const EdgeInsets.all(UiSpace.l),
                  child: DecimalField(
                    value: selection.customPrice == null
                        ? null
                        : selection.customPrice!.typicalKopecks / 100,
                    label: t.estimateCustomPrice,
                    onChanged: (v) => select(
                      ApparatusSelection(
                        product: selection.product,
                        catalogVersion: selection.catalogVersion,
                        customPrice: v == null ? null : PriceRange.exact((v * 100).round()),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        UiCard(
          title: t.estimatePickModel,
          child: candidates.isEmpty
              ? UiEmptyState(
                  standalone: false,
                  title: t.estimateNoModels,
                  message: t.estimateRequirement(requirement.label),
                )
              : UiDivided(
                  topBorder: true,
                  children: [
                    for (final c in candidates)
                      UiChoiceRow(
                        selected: selection?.product.id == c.product.id,
                        title:
                            '${state.catalog.manufacturers[c.product.manufacturerId]?.name ?? ''} ${c.product.series}',
                        subtitle:
                            '${c.compatibility.status == CompatibilityStatus.exact ? t.compatibilityExact : t.compatibilityDifferences}'
                            '${c.compatibility.reasons.isEmpty ? '' : ': ${c.compatibility.reasons.map((r) => r.message).join(', ')}'}',
                        trailing: Text(formatRubles(c.product.price.typicalKopecks)),
                        onTap: () {
                          select(
                            ApparatusSelection(
                              product: c.product,
                              catalogVersion: state.catalog.catalogVersion,
                            ),
                          );
                          back();
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
