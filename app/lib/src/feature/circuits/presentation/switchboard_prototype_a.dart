// PROTOTYPE – variant A «Реалистичный»: devices in real proportions, one body per device,
// a marking label under each line (vertical text on narrow lines).
// ignore_for_file: specify_nonobvious_local_variable_types, use_key_in_widget_constructors
import 'package:common_ui/common_ui.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shchitovik/src/feature/circuits/presentation/switchboard_prototype_shared.dart';

class const ProtoBoardA({
  required final SwitchboardLayout layout,
  required final ProtoBoard board,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double module = protoModule(constraints.maxWidth - 2 * UiSpace.m, layout, 30, 52);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.sunken,
              borderRadius: UiRadius.cardAll,
              border: Border.all(color: board.editing ? c.primary : c.borderStrong),
            ),
            child: Padding(
              padding: const EdgeInsets.all(UiSpace.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < layout.rails.length; i++)
                    _RailA(
                      index: i,
                      rail: layout.rails[i],
                      outside: i >= layout.enclosureRails,
                      module: module,
                      board: board,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class const _RailA({
  required final int index,
  required final BoardRail rail,
  required final bool outside,
  required final double module,
  required final ProtoBoard board,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final double body = (module * 2.6).clamp(100, 136);
    final int modules = rail.used > rail.capacity ? rail.used : rail.capacity;
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiLabel(protoRailLabel(index + 1, rail, outside)),
          const SizedBox(height: UiSpace.xs),
          ProtoDropRail(
            rail: rail,
            index: index,
            module: module,
            board: board,
            builder: (active) => SizedBox(
              width: modules * module,
              child: Stack(
                children: [
                  // DIN rail (35 mm top-hat), visible through empty places.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: body * .36,
                    height: body * .28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: active ? c.primary.withValues(alpha: .35) : c.border,
                        border: Border.symmetric(horizontal: BorderSide(color: c.borderStrong)),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in rail.items)
                        _LineA(
                          info: protoItem(context, item, board.state),
                          module: module,
                          body: body,
                          board: board,
                        ),
                      for (var i = rail.used; i < rail.capacity; i++)
                        _PlugA(module: module, body: body),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class const _LineA({
  required final ProtoItem info,
  required final double module,
  required final double body,
  required final ProtoBoard board,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ProtoItemShell(
    info: info,
    board: board,
    face: (hovered, selected) => _LineFaceA(
      info: info,
      module: module,
      body: body,
      hovered: hovered,
      selected: selected,
    ),
  );
}

class const _LineFaceA({
  required final ProtoItem info,
  required final double module,
  required final double body,
  required final bool hovered,
  required final bool selected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final double width = info.units * module;
    final Color? frame = selected ? c.primary : info.frame;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Row(
            children: [
              for (final d in info.devices)
                _DeviceA(device: d, module: module, body: body, accent: info.accent, lit: hovered),
            ],
          ),
          // Busbar of a shared RCD group.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            child: SizedBox(
              height: 3,
              width: double.infinity,
              child: ColoredBox(
                color: info.item.groupId == null ? const Color(0x00000000) : c.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: _MarkingA(info: info, width: width - 2, frame: frame),
          ),
        ],
      ),
    );
  }
}

/// Marking label under a line, like the stickers electricians put on a panel.
class const _MarkingA({
  required final ProtoItem info,
  required final double width,
  required final Color? frame,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final TextStyle title = UiTextStyles.caption.copyWith(
      color: c.text,
      fontSize: width < 50 ? 9 : 10,
      height: 1.05,
      fontWeight: FontWeight.w500,
    );
    // Compact sticker: number on the phase strip and up to two lines of the name; cable and
    // status are in the tooltip, the phase is the strip colour.
    return SizedBox(
      width: width,
      height: 38,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.all(Radius.circular(2)),
          border: Border.all(color: frame ?? c.borderStrong, width: frame == null ? 1 : 2),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 12,
              width: double.infinity,
              child: ColoredBox(
                color: info.accent,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        info.number,
                        style: UiTextStyles.valueStrong.copyWith(
                          color: protoOn(info.accent),
                          fontSize: 10,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    info.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: title,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One device body: terminal covers, kind, rating window, lever.
class const _DeviceA({
  required final ProtoDevice device,
  required final double module,
  required final double body,
  required final Color accent,
  required final bool lit,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final double width = device.units * module;
    final rcd = device.kind == 'УЗО' || device.kind == 'АВДТ';
    final double lever = (module * .34).clamp(8, 16);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: .5),
      child: SizedBox(
        width: width - 1,
        height: body,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: lit ? c.sunken : c.surface,
            borderRadius: const BorderRadius.all(Radius.circular(3)),
            border: Border.all(color: c.borderStrong),
          ),
          child: Column(
            children: [
              // Upper terminal cover with the phase tick.
              SizedBox(
                height: body * .14,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.border,
                    border: Border(top: BorderSide(color: accent, width: 3)),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Fit(
                        device.kind,
                        UiTextStyles.label.copyWith(
                          color: c.textMuted,
                          fontSize: 9,
                          letterSpacing: 0,
                        ),
                      ),
                      if (device.rating.isNotEmpty)
                        _Fit(
                          device.rating,
                          UiTextStyles.valueStrong.copyWith(color: c.text, fontSize: 14),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: lever,
                            height: body * .2,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.text.withValues(alpha: .8),
                                borderRadius: const BorderRadius.all(Radius.circular(2)),
                              ),
                            ),
                          ),
                          if (rcd && device.units > 1) ...[
                            SizedBox(width: module * .2),
                            // Test button «T».
                            SizedBox.square(
                              dimension: lever * .8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: c.warning,
                                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (device.extra != null)
                        _Fit(
                          device.extra!,
                          UiTextStyles.caption.copyWith(color: c.textMuted, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: body * .1,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line of text shrunk to fit its width.
class const _Fit(final String text, final TextStyle style) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, style: style),
  );
}

/// Blank cover of a free place.
class const _PlugA({required final double module, required final double body})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(.5, body * .25, .5, 0),
    child: SizedBox(
      width: module - 1,
      height: body * .5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.uiColors.surface.withValues(alpha: .5),
          borderRadius: const BorderRadius.all(Radius.circular(2)),
          border: Border.all(color: context.uiColors.borderStrong.withValues(alpha: .6)),
        ),
      ),
    ),
  );
}
