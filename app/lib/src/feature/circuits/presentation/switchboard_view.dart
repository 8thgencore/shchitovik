import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
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
    final c = context.uiColors;
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
          style: UiTextStyles.heading.copyWith(color: c.text),
        ),
        const SizedBox(height: UiSpace.m),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.sunken,
              borderRadius: UiRadius.cardAll,
              border: Border.all(color: c.borderStrong),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(UiSpace.m, UiSpace.m, UiSpace.m, UiSpace.xs),
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
        const SizedBox(height: UiSpace.s),
        Text(
          t.boardReserveNote((enclosureReserveShare * 100).round()),
          style: UiTextStyles.caption.copyWith(color: c.textMuted),
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
    final c = context.uiColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiLabel(context.translations.boardRail(number, rail.used, rail.capacity)),
          const SizedBox(height: UiSpace.xs),
          SizedBox(
            width: rail.capacity * _moduleWidth,
            height: 108,
            child: Stack(
              children: [
                // The DIN rail itself, behind the modules.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 38,
                  height: 26,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.border,
                      border: Border.symmetric(horizontal: BorderSide(color: c.borderStrong)),
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
///
/// These are physical marking colours, not theme roles.
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
    final c = context.uiColors;
    final result = state.result;
    final group = item.groupId == null ? null : c.primary;
    switch (item.kind) {
      case BoardItemKind.incomer:
        return _Module(
          units: item.units,
          top: t.boardIncomer,
          title: 'C${formatNumber(result.incomer.breakerA, 0)}',
          bottom: '${formatNumber(result.incomer.designCurrentA)} А',
          strip: c.primary,
        );
      case BoardItemKind.fireRcd:
        final rcd = result.fireRcd!;
        return _Module(
          units: item.units,
          top: t.boardRcd,
          title: '${formatNumber(rcd.residualMa, 0)} мА',
          bottom: '${formatNumber(rcd.ratedA, 0)} А',
          strip: c.danger,
        );
      case BoardItemKind.auxiliary:
        final line = state.estimate.lines.firstWhere((l) => l.id == item.id);
        return _Module(
          units: item.units,
          top: t.boardAuxiliary,
          title: line.title,
          bottom: line.description,
          strip: c.textMuted,
        );
      case BoardItemKind.groupRcd:
        final rcd = result.sharedRcds.firstWhere((r) => r.id == item.id);
        return _Module(
          units: item.units,
          top: t.boardRcd,
          title: '${formatNumber(rcd.residualMa, 0)} мА',
          bottom: '${formatNumber(rcd.ratedA, 0)} А',
          strip: c.primary,
          underline: group,
        );
      case BoardItemKind.circuit:
        final circuit = result.circuits.firstWhere((x) => x.id == item.id);
        final phase = circuit.phase;
        final tone = statusStripe(circuit.status);
        return Tooltip(
          message:
              '${circuit.number}. ${circuit.name}\n${circuit.protection.description}\n'
              '${circuit.cable.label} мм² · ${phase?.label ?? '3ф'} · ${circuit.status.label}',
          child: UiPressable(
            onPressed: () => context.go(AppRoutes.circuit(state.document.id, circuit.id)),
            semanticLabel: '${circuit.number}. ${circuit.name}, ${circuit.status.label}',
            builder: (context, s) => UiFocusRing(
              visible: s.focused,
              child: _Module(
                units: item.units,
                top: '${circuit.number} · ${phase?.label ?? '3ф'}',
                title: circuit.protection.label,
                bottom: circuit.name,
                strip: phase == null ? c.primary : _phaseColor(phase),
                frame: tone?.color(c),
                hovered: s.hovered,
                underline: group,
              ),
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
    required this.strip,
    this.frame,
    this.underline,
    this.hovered = false,
  });

  final int units;
  final String top;
  final String title;
  final String bottom;
  final Color strip;
  final Color? frame;
  final Color? underline;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
    final width = units * _moduleWidth - 2;
    final onStrip = ThemeData.estimateBrightnessForColor(strip) == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        children: [
          SizedBox(
            width: width,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: hovered ? c.sunken : c.surface,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
                border: Border.all(color: frame ?? c.borderStrong, width: frame == null ? 1 : 2),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 16,
                    child: ColoredBox(
                      color: strip,
                      child: Center(
                        child: Text(
                          top,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: UiTextStyles.label.copyWith(
                            color: onStrip,
                            fontSize: 11,
                            letterSpacing: 0,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: UiTextStyles.valueStrong.copyWith(color: c.text, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  // Toggle lever of the device.
                  SizedBox(
                    width: 10,
                    height: 20,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.text.withValues(alpha: .75),
                        borderRadius: const BorderRadius.all(Radius.circular(1.5)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
                    child: Text(
                      bottom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: UiTextStyles.caption.copyWith(
                        color: c.textMuted,
                        fontSize: 12,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: width,
            height: 3,
            child: ColoredBox(color: underline ?? const Color(0x00000000)),
          ),
        ],
      ),
    );
  }
}

class _BlankModule extends StatelessWidget {
  const _BlankModule();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(1, 18, 1, 0),
    child: SizedBox(
      width: _moduleWidth - 2,
      height: 66,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(2)),
          border: Border.all(color: context.uiColors.borderStrong.withValues(alpha: .6)),
        ),
      ),
    ),
  );
}
