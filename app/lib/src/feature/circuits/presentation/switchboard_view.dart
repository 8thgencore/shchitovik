import 'package:common_translations/common_translations.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shchitovik/src/feature/circuits/domain/switchboard_layout.dart';
import 'package:shchitovik/src/feature/circuits/presentation/status_badge.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/logic/app_router.dart';

/// Width of one DIN module on screen.
const _moduleWidth = 36.0;

/// Switchboard drawn as DIN rails; tapping a circuit opens it.
///
/// The board keeps real proportions and scrolls horizontally as a whole on narrow screens.
class SwitchboardView extends StatelessWidget {
  const SwitchboardView({required this.state, super.key});

  /// Project with its calculation and estimate.
  final ProjectReady state;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final scheme = Theme.of(context).colorScheme;
    final layout = layoutSwitchboard(
      switchboardItems(state.document.input, state.result, state.estimate),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.boardEnclosure(
            layout.rails.length,
            layout.modulesPerRail,
            layout.totalModules,
            layout.occupiedModules,
            layout.reserveModules,
          ),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.surfaceContainerHighest, width: 3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < layout.rails.length; i++)
                    _Rail(number: i + 1, rail: layout.rails[i], state: state),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.boardReserveNote((enclosureReserveShare * 100).round()),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.number, required this.rail, required this.state});

  final int number;
  final BoardRail rail;
  final ProjectReady state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.translations.boardRail(number, rail.used, rail.capacity),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: rail.capacity * _moduleWidth,
            height: 112,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 40,
                  height: 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      border: Border.all(color: scheme.outline),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in rail.items) _BoardItemModule(item: item, state: state),
                    for (var i = rail.used; i < rail.capacity; i++) const _BlankModule(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Conductor colours of the phases by ГОСТ 33542-2015 (IEC 60445): L1 brown, L2 black, L3 grey.
Color _phaseColor(Phase phase) => switch (phase) {
  Phase.l1 => const Color(0xFF795548),
  Phase.l2 => const Color(0xFF212121),
  Phase.l3 => const Color(0xFF9E9E9E),
};

class _BoardItemModule extends StatelessWidget {
  const _BoardItemModule({required this.item, required this.state});

  final BoardItem item;
  final ProjectReady state;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final scheme = Theme.of(context).colorScheme;
    final result = state.result;
    final group = item.groupId == null ? null : scheme.tertiary;
    switch (item.kind) {
      case BoardItemKind.incomer:
        return _Module(
          units: item.units,
          top: t.boardIncomer,
          title: 'C${formatNumber(result.incomer.breakerA, 0)}',
          bottom: '${formatNumber(result.incomer.designCurrentA)} А',
          color: scheme.secondary,
        );
      case BoardItemKind.fireRcd:
        final rcd = result.fireRcd!;
        return _Module(
          units: item.units,
          top: t.boardRcd,
          title: '${formatNumber(rcd.residualMa, 0)} мА',
          bottom: '${formatNumber(rcd.ratedA, 0)} А',
          color: scheme.error,
        );
      case BoardItemKind.auxiliary:
        final line = state.estimate.lines.firstWhere((l) => l.id == item.id);
        return _Module(
          units: item.units,
          top: t.boardAuxiliary,
          title: line.title,
          bottom: line.description,
          color: scheme.secondary,
        );
      case BoardItemKind.groupRcd:
        final rcd = result.sharedRcds.firstWhere((r) => r.id == item.id);
        return _Module(
          units: item.units,
          top: t.boardRcd,
          title: '${formatNumber(rcd.residualMa, 0)} мА',
          bottom: '${formatNumber(rcd.ratedA, 0)} А',
          color: scheme.tertiary,
          underline: group,
        );
      case BoardItemKind.circuit:
        final circuit = result.circuits.firstWhere((c) => c.id == item.id);
        final phase = circuit.phase;
        return Tooltip(
          message:
              '${circuit.number}. ${circuit.name}\n${circuit.protection.description}\n'
              '${circuit.cable.label} мм² · ${phase?.label ?? '3ф'} · ${circuit.status.label}',
          child: InkWell(
            onTap: () => context.go(AppRoutes.circuit(state.document.id, circuit.id)),
            child: _Module(
              units: item.units,
              top: '${circuit.number} · ${phase?.label ?? '3ф'}',
              title: circuit.protection.label,
              bottom: circuit.name,
              color: phase == null ? scheme.primary : _phaseColor(phase),
              border: statusColor(context, circuit.status),
              underline: group,
            ),
          ),
        );
    }
  }
}

class _Module extends StatelessWidget {
  const _Module({
    required this.units,
    required this.top,
    required this.title,
    required this.bottom,
    required this.color,
    this.border,
    this.underline,
  });

  final int units;
  final String top;
  final String title;
  final String bottom;
  final Color color;
  final Color? border;
  final Color? underline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = units * _moduleWidth - 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        children: [
          SizedBox(
            width: width,
            height: 104,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: border ?? scheme.outline,
                  width: border == null ? 1 : 2,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 18,
                    child: ColoredBox(
                      color: color,
                      child: Center(
                        child: Text(
                          top,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(color: _foregroundOn(color), fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.toggle_on_outlined, size: 22, color: scheme.onSurfaceVariant),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
                    child: Text(
                      bottom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, height: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: width,
            height: 4,
            child: ColoredBox(color: underline ?? Colors.transparent),
          ),
        ],
      ),
    );
  }
}

/// Black or white text, whichever is readable on [background].
Color _foregroundOn(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : Colors.black;

class _BlankModule extends StatelessWidget {
  const _BlankModule();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(1, 20, 1, 0),
    child: SizedBox(
      width: _moduleWidth - 2,
      height: 68,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
      ),
    ),
  );
}
