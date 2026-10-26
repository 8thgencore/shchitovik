// PROTOTYPE – variant B «Повёрнутая рейка»: each rail is drawn vertically, a device's width in
// modules becomes the row height, and the whole row width is left for the texts.
// ignore_for_file: prefer_const_declarations, use_key_in_widget_constructors
import 'package:common_ui/common_ui.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shchitovik/src/feature/circuits/presentation/switchboard_prototype_shared.dart';

/// Height of one DIN module along the rotated rail.
const _module = 40.0;

class const ProtoBoardB({
  required final SwitchboardLayout layout,
  required final ProtoBoard board,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final int count = layout.rails.length;
      final double gap = UiSpace.m;
      // Rails side by side while each keeps at least 260 dp, stacked otherwise.
      final int columns = ((constraints.maxWidth + gap) / (260 + gap)).floor().clamp(1, count);
      final double width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < count; i++)
            SizedBox(
              width: width,
              child: _RailB(
                index: i,
                rail: layout.rails[i],
                outside: i >= layout.enclosureRails,
                board: board,
              ),
            ),
        ],
      );
    },
  );
}

class const _RailB({
  required final int index,
  required final BoardRail rail,
  required final bool outside,
  required final ProtoBoard board,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final int free = rail.capacity - rail.used;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.sunken,
        borderRadius: UiRadius.cardAll,
        border: Border.all(color: board.editing ? c.primary : c.borderStrong),
      ),
      child: Padding(
        padding: const EdgeInsets.all(UiSpace.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiLabel(protoRailLabel(index + 1, rail, outside)),
            const SizedBox(height: UiSpace.xs),
            ProtoDropRail(
              rail: rail,
              index: index,
              module: _module,
              board: board,
              axis: Axis.vertical,
              builder: (active) => Stack(
                children: [
                  // The DIN rail runs down behind the device column.
                  Positioned(
                    left: 14,
                    width: 30,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: active ? c.primary.withValues(alpha: .35) : c.border,
                        border: Border.symmetric(vertical: BorderSide(color: c.borderStrong)),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in rail.items)
                        _RowB(info: protoItem(context, item, board.state), board: board),
                      if (free > 0) _FreeB(modules: free),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _RowB({required final ProtoItem info, required final ProtoBoard board})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ProtoItemShell(
    info: info,
    board: board,
    face: (hovered, selected) => _RowFaceB(info: info, hovered: hovered, selected: selected),
  );
}

class const _RowFaceB({
  required final ProtoItem info,
  required final bool hovered,
  required final bool selected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final Color? frame = selected ? c.primary : info.frame;
    final double height = info.units * _module;
    final bool tall = info.units > 1;
    return SizedBox(
      height: height,
      // Width is bounded by the rail; the drag feedback has none, so cap it.
      width: 320,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Devices across the rail, each as tall as its width in modules.
          SizedBox(
            width: 58,
            child: Column(
              children: [
                for (final d in info.devices) _DeviceB(device: d, accent: info.accent),
              ],
            ),
          ),
          // Group busbar.
          SizedBox(
            width: 3,
            child: ColoredBox(
              color: info.item.groupId == null ? const Color(0x00000000) : c.primary,
            ),
          ),
          const SizedBox(width: UiSpace.xs),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hovered ? c.sunken : c.surface,
                  borderRadius: UiRadius.cardAll,
                  border: Border.all(color: frame ?? c.border, width: frame == null ? 1 : 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: UiSpace.s),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          info.number,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: UiTextStyles.valueStrong.copyWith(color: c.text, fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.title,
                              maxLines: tall ? (info.units > 2 ? 3 : 2) : 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiTextStyles.bodySmall.copyWith(
                                color: c.text,
                                height: 1.15,
                              ),
                            ),
                            Text(
                              info.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiTextStyles.caption.copyWith(
                                color: c.textMuted,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class const _DeviceB({required final ProtoDevice device, required final Color accent})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: .5),
      child: SizedBox(
        height: device.units * _module - 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.all(Radius.circular(3)),
            border: Border.all(color: c.borderStrong),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 3, right: 3),
            child: Row(
              children: [
                // Phase tick.
                SizedBox(
                  width: 4,
                  height: double.infinity,
                  child: ColoredBox(color: accent),
                ),
                const SizedBox(width: 3),
                Expanded(child: _DeviceTextB(device: device)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class const _DeviceTextB({required final ProtoDevice device}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              device.rating.isEmpty ? device.kind : device.rating,
              maxLines: 1,
              style: UiTextStyles.valueStrong.copyWith(color: c.text, fontSize: 13),
            ),
          ),
          if (device.rating.isNotEmpty)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                device.units > 1 && device.extra != null
                    ? '${device.kind} ${device.extra}'
                    : device.kind,
                maxLines: 1,
                style: UiTextStyles.caption.copyWith(
                  color: c.textMuted,
                  fontSize: 10,
                  height: 1.1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class const _FreeB({required final int modules}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: SizedBox(
        // Free places are shown compressed: their count matters, not their length.
        height: (modules > 2 ? 2 : modules) * _module - 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: UiRadius.cardAll,
            border: Border.all(color: c.borderStrong.withValues(alpha: .6)),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(70, UiSpace.s, UiSpace.s, 0),
              child: Text(
                'Свободно: $modules мод.',
                style: UiTextStyles.caption.copyWith(color: c.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
