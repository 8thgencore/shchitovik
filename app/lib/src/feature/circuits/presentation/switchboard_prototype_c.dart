// PROTOTYPE – variant C «Компактная рейка + легенда»: a dense rail that fits a phone, with only
// numbers and ratings on the bodies; names live in a legend under each rail, paired by number.
// ignore_for_file: use_key_in_widget_constructors
import 'package:common_ui/common_ui.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shchitovik/src/feature/circuits/presentation/switchboard_prototype_shared.dart';

class const ProtoBoardC({
  required final SwitchboardLayout layout,
  required final ProtoBoard board,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double module = protoModule(constraints.maxWidth - 2 * UiSpace.s, layout, 13, 40);
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
                for (var i = 0; i < layout.rails.length; i++)
                  _RailC(
                    index: i,
                    rail: layout.rails[i],
                    outside: i >= layout.enclosureRails,
                    module: module,
                    legendColumns: constraints.maxWidth >= 720 ? 2 : 1,
                    board: board,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class const _RailC({
  required final int index,
  required final BoardRail rail,
  required final bool outside,
  required final double module,
  required final int legendColumns,
  required final ProtoBoard board,
}) extends StatefulWidget {
  @override
  State<_RailC> createState() => _RailCState();
}

class _RailCState() extends State<_RailC> {
  /// Item highlighted on the rail and in the legend at once.
  String? _lit;

  void _light(String id, bool on) => setState(() => _lit = on ? id : (_lit == id ? null : _lit));

  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final double module = widget.module;
    final double body = (module * 2.4).clamp(48, 92);
    final BoardRail rail = widget.rail;
    final int modules = rail.used > rail.capacity ? rail.used : rail.capacity;
    final ProtoBoard b = widget.board;
    // Legend rows select and open circuits but are not dragged.
    final ProtoBoard legendBoard = (
      state: b.state,
      editing: b.editing,
      draggable: false,
      selected: b.selected,
      onSelect: b.onSelect,
      onDrop: b.onDrop,
    );
    final List<ProtoItem> items = [
      for (final item in rail.items) protoItem(context, item, widget.board.state),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiLabel(protoRailLabel(widget.index + 1, rail, widget.outside)),
          const SizedBox(height: UiSpace.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ProtoDropRail(
              rail: rail,
              index: widget.index,
              module: module,
              board: widget.board,
              builder: (active) => SizedBox(
                width: modules * module,
                height: body + 4,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: body * .38,
                      height: body * .24,
                      child: ColoredBox(
                        color: active ? c.primary.withValues(alpha: .35) : c.border,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final info in items)
                          MouseRegion(
                            onEnter: (_) => _light(info.item.id, true),
                            onExit: (_) => _light(info.item.id, false),
                            child: ProtoItemShell(
                              info: info,
                              board: widget.board,
                              face: (hovered, selected) => _BodyC(
                                info: info,
                                module: module,
                                body: body,
                                lit: hovered || _lit == info.item.id,
                                selected: selected,
                              ),
                            ),
                          ),
                        for (var i = rail.used; i < rail.capacity; i++)
                          Padding(
                            padding: EdgeInsets.fromLTRB(.5, body * .3, .5, 0),
                            child: SizedBox(
                              width: module - 1,
                              height: body * .4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: c.borderStrong.withValues(alpha: .5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: UiSpace.s),
          LayoutBuilder(
            builder: (context, constraints) {
              final int columns = widget.legendColumns;
              final double width = (constraints.maxWidth - UiSpace.l * (columns - 1)) / columns;
              return Wrap(
                spacing: UiSpace.l,
                children: [
                  for (final info in items)
                    SizedBox(
                      width: width,
                      child: MouseRegion(
                        onEnter: (_) => _light(info.item.id, true),
                        onExit: (_) => _light(info.item.id, false),
                        child: ProtoItemShell(
                          info: info,
                          board: legendBoard,
                          face: (hovered, selected) => _LegendRowC(
                            info: info,
                            lit: hovered || _lit == info.item.id,
                            selected: selected,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class const _BodyC({
  required final ProtoItem info,
  required final double module,
  required final double body,
  required final bool lit,
  required final bool selected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final Color? frame = selected ? c.primary : info.frame;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < info.devices.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: .5),
                child: SizedBox(
                  width: info.devices[i].units * module - 1,
                  height: body,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: lit ? c.accentSoft : c.surface,
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                      border: Border.all(
                        color: frame ?? c.borderStrong,
                        width: frame == null ? 1 : 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 14,
                          width: double.infinity,
                          child: ColoredBox(
                            color: info.accent,
                            child: i == 0
                                ? Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 1),
                                        child: Text(
                                          info.number,
                                          maxLines: 1,
                                          style: UiTextStyles.valueStrong.copyWith(
                                            color: protoOn(info.accent),
                                            fontSize: 11,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _Rating(
                              text: info.devices[i].rating.isEmpty
                                  ? info.devices[i].kind
                                  : info.devices[i].rating,
                              vertical: info.devices[i].units * module < 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: SizedBox(
            width: info.units * module - 1,
            height: 3,
            child: ColoredBox(
              color: info.item.groupId == null ? const Color(0x00000000) : c.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class const _Rating({required final String text, required final bool vertical})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = Padding(
      padding: const EdgeInsets.all(2),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: UiTextStyles.valueStrong.copyWith(color: context.uiColors.text, fontSize: 13),
        ),
      ),
    );
    return vertical ? RotatedBox(quarterTurns: 3, child: label) : label;
  }
}

class const _LegendRowC({
  required final ProtoItem info,
  required final bool lit,
  required final bool selected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final String ratings = [
      for (final d in info.devices) [if (d.rating.isNotEmpty) d.rating, ?d.extra].join(' '),
    ].where((s) => s.isNotEmpty).join(' + ');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: lit || selected ? c.accentSoft : const Color(0x00000000),
        borderRadius: UiRadius.controlAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: UiSpace.xs, vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 20,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: info.accent,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      info.number,
                      style: UiTextStyles.valueStrong.copyWith(
                        color: protoOn(info.accent),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: UiSpace.s),
            Expanded(
              child: Text(
                info.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiTextStyles.bodySmall.copyWith(color: c.text),
              ),
            ),
            const SizedBox(width: UiSpace.s),
            Text(
              ratings,
              style: UiTextStyles.value.copyWith(color: c.textMuted, fontSize: 12),
            ),
            if (info.frame != null) ...[
              const SizedBox(width: UiSpace.xs),
              SizedBox.square(
                dimension: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: info.frame, shape: BoxShape.circle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
