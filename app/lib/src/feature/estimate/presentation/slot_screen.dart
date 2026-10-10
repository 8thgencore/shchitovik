import 'package:common_translations/common_translations.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Choice of a model for one estimate slot, or a custom price.
class SlotScreen extends StatelessWidget {
  const SlotScreen({required this.slotId, super.key});

  /// Slot id.
  final String slotId;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final state = context.watch<ProjectBloc>().state as ProjectReady;
    final line = state.estimate.lines.where((l) => l.id == slotId).firstOrNull;
    final requirement = line?.requirement;
    if (line == null || requirement == null) return Center(child: Text(t.estimateNoModels));
    final selection = state.document.estimate.selections[slotId];
    final candidates = compatibleProducts(requirement, state.catalog);

    void select(ApparatusSelection? value) {
      ProjectScope.edit(context, (d) {
        final selections = {...d.estimate.selections}..remove(slotId);
        if (value != null) selections[slotId] = value;
        return d.copyWith(estimate: d.estimate.copyWith(selections: selections));
      });
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ListTile(
          title: Text(line.title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(t.estimateRequirement(requirement.label)),
        ),
        ListTile(
          leading: Icon(selection == null ? Icons.radio_button_checked : Icons.radio_button_off),
          title: Text(t.estimateResetSelection),
          subtitle: Text(line.source == PriceSource.automatic ? line.description : ''),
          onTap: () {
            select(null);
            context.pop();
          },
        ),
        if (selection != null)
          DecimalField(
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
        SectionTitle(t.estimatePickModel),
        if (candidates.isEmpty) ListTile(title: Text(t.estimateNoModels)),
        for (final c in candidates)
          ListTile(
            leading: Icon(
              selection?.product.id == c.product.id
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(
              '${state.catalog.manufacturers[c.product.manufacturerId]?.name ?? ''} ${c.product.series}',
            ),
            subtitle: Text(
              '${c.compatibility.status == CompatibilityStatus.exact ? t.compatibilityExact : t.compatibilityDifferences}'
              '${c.compatibility.reasons.isEmpty ? '' : ': ${c.compatibility.reasons.map((r) => r.message).join(', ')}'}',
            ),
            trailing: Text(formatRubles(c.product.price.typicalKopecks)),
            onTap: () {
              select(
                ApparatusSelection(
                  product: c.product,
                  catalogVersion: state.catalog.catalogVersion,
                ),
              );
              context.pop();
            },
          ),
      ],
    );
  }
}
