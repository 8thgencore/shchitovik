import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shchitovik/src/feature/circuits/presentation/status_badge.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/logic/app_router.dart';

/// Width of one DIN module on screen.
const _moduleWidth = 36.0;

/// Switchboard drawn as DIN rails; tapping a circuit opens it.
///
/// The board keeps real proportions and scrolls horizontally as a whole on narrow screens.
/// In the rearrange mode a tap selects a device, which then moves with the arrow buttons or
/// keys; on expanded windows devices can also be dragged. The arrangement and the enclosure
/// are saved with the estimate choices.
class const SwitchboardView({
  /// Project with its calculation and estimate.
  required final ProjectReady state,
  super.key,
}) extends StatefulWidget {
  @override
  State<SwitchboardView> createState() => _SwitchboardViewState();
}

class _SwitchboardViewState() extends State<SwitchboardView> {
  bool _editing = false;
  String? _selected;

  ProjectReady get _state => widget.state;

  void _edit(BoardArrangement Function(BoardArrangement board) transform) => ProjectScope.edit(
    context,
    (d) => d.copyWith(estimate: d.estimate.copyWith(board: transform(d.estimate.board))),
  );

  void _move(SwitchboardLayout layout, BoardMove move) {
    final String? id = _selected;
    if (id != null) {
      _edit((b) => moveBoardItem(b, layout, id, move));
    }
  }

  void _toggleEditing() => setState(() {
    _editing = !_editing;
    _selected = null;
  });

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final UiColors c = context.uiColors;
    final BoardArrangement board = _state.document.estimate.board;
    final SwitchboardLayout layout = arrangeSwitchboard(
      switchboardItems(_state.document.input, _state.result, _state.estimate),
      board,
    );
    final bool draggable = _editing && MediaQuery.sizeOf(context).width >= UiBreakpoints.expanded;
    final String? selected = layout.rails.any((r) => r.items.any((i) => i.id == _selected))
        ? _selected
        : null;
    final int enclosureModules = layout.enclosureRails * layout.modulesPerRail;

    Widget rails = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.sunken,
          borderRadius: UiRadius.cardAll,
          border: Border.all(color: _editing ? c.primary : c.borderStrong),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(UiSpace.m, UiSpace.m, UiSpace.m, UiSpace.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < layout.rails.length; i++)
                _Rail(
                  number: i + 1,
                  rail: layout.rails[i],
                  outside: i >= layout.enclosureRails,
                  state: _state,
                  editing: _editing,
                  draggable: draggable,
                  selected: selected,
                  onSelect: (id) => setState(() => _selected = _selected == id ? null : id),
                  onDrop: (id, index) {
                    setState(() => _selected = id);
                    _edit((b) => placeBoardItem(b, layout, id, i, index));
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (_editing) {
      rails = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _move(layout, BoardMove.left),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _move(layout, BoardMove.right),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(layout, BoardMove.up),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(layout, BoardMove.down),
          const SingleActivator(LogicalKeyboardKey.escape): _toggleEditing,
        },
        child: Focus(autofocus: true, child: rails),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.boardEnclosure(
            layout.enclosureRails,
            layout.modulesPerRail,
            enclosureModules,
            layout.occupiedModules,
            enclosureModules - layout.occupiedModules,
          ),
          style: UiTextStyles.heading.copyWith(color: c.text),
        ),
        if (!board.isAuto)
          Text(t.boardManual, style: UiTextStyles.caption.copyWith(color: c.textMuted)),
        const SizedBox(height: UiSpace.m),
        _Toolbar(
          board: board,
          layout: layout,
          editing: _editing,
          onToggleEditing: _toggleEditing,
          onEnclosure: (enclosure) => _edit((b) => b.copyWith(enclosure: enclosure)),
          onReset: () => _edit((_) => const BoardArrangement()),
        ),
        if (_editing) ...[
          const SizedBox(height: UiSpace.s),
          Text(t.boardRearrangeHint, style: UiTextStyles.caption.copyWith(color: c.textMuted)),
          const SizedBox(height: UiSpace.xs),
          _MoveButtons(onMove: selected == null ? null : (move) => _move(layout, move)),
        ],
        const SizedBox(height: UiSpace.m),
        rails,
        for (final warning in layout.warnings) ...[
          const SizedBox(height: UiSpace.s),
          UiNotice(tone: UiTone.warning, message: _warningText(warning)),
        ],
        const SizedBox(height: UiSpace.s),
        Text(
          t.boardReserveNote((enclosureReserveShare * 100).round()),
          style: UiTextStyles.caption.copyWith(color: c.textMuted),
        ),
      ],
    );
  }

  String _warningText(BoardWarning warning) {
    final CommonTranslationsLocalizations t = context.translations;
    final ProjectResult result = _state.result;
    return switch (warning) {
      BoardRailOverfull(:final rail) => t.boardWarningOverfull(rail + 1),
      BoardEnclosureTooSmall() => t.boardWarningTooSmall,
      BoardReserveLow() => t.boardWarningReserve((enclosureReserveShare * 100).round()),
      BoardGroupSplit(:final rcdId) => t.boardWarningGroupSplit(
        [
          for (final c in result.circuits)
            if (result.sharedRcds.any((r) => r.id == rcdId && r.circuitIds.contains(c.id)))
              '№${c.number}',
        ].join(', '),
      ),
    };
  }
}

class const _Toolbar({
  required final BoardArrangement board,
  required final SwitchboardLayout layout,
  required final bool editing,
  required final VoidCallback onToggleEditing,
  required final ValueChanged<(int, int)?> onEnclosure,
  required final VoidCallback onReset,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final String auto = t.boardEnclosureOption(
      layout.enclosureRails,
      layout.modulesPerRail,
      layout.enclosureRails * layout.modulesPerRail,
    );
    return Wrap(
      spacing: UiSpace.s,
      runSpacing: UiSpace.s,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: 240,
          child: UiSelect<(int, int)?>(
            label: t.boardEnclosureLabel,
            value: board.enclosure,
            options: [
              (null, '${t.auto} ($auto)'),
              for (final (rails, perRail) in typicalEnclosures)
                ((rails, perRail), t.boardEnclosureOption(rails, perRail, rails * perRail)),
            ],
            onChanged: onEnclosure,
          ),
        ),
        if (editing)
          UiButton(label: t.boardRearrangeDone, icon: UiIcons.check, onPressed: onToggleEditing)
        else
          UiButton.secondary(
            label: t.boardRearrange,
            icon: UiIcons.rearrange,
            onPressed: onToggleEditing,
          ),
        if (!board.isAuto)
          UiButton.ghost(label: t.boardReset, icon: UiIcons.reset, onPressed: onReset),
      ],
    );
  }
}

class const _MoveButtons({
  /// `null` — nothing is selected.
  required final ValueChanged<BoardMove>? onMove,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final ValueChanged<BoardMove>? onMove = this.onMove;
    VoidCallback? on(BoardMove move) => onMove == null ? null : () => onMove(move);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UiIconButton(
          icon: UiIcons.moveLeft,
          tooltip: t.boardMoveLeft,
          onPressed: on(BoardMove.left),
        ),
        UiIconButton(icon: UiIcons.moveUp, tooltip: t.boardMoveUp, onPressed: on(BoardMove.up)),
        UiIconButton(
          icon: UiIcons.moveDown,
          tooltip: t.boardMoveDown,
          onPressed: on(BoardMove.down),
        ),
        UiIconButton(
          icon: UiIcons.moveRight,
          tooltip: t.boardMoveRight,
          onPressed: on(BoardMove.right),
        ),
      ],
    );
  }
}

class const _Rail({
  required final int number,
  required final BoardRail rail,
  required final bool outside,
  required final ProjectReady state,
  required final bool editing,
  required final bool draggable,
  required final String? selected,
  required final ValueChanged<String> onSelect,
  required final void Function(String id, int index) onDrop,
}) extends StatelessWidget {
  /// Index before which a device whose centre is dropped at [x] from the rail start goes.
  int _dropIndex(double x) {
    var start = 0;
    for (var i = 0; i < rail.items.length; i++) {
      final int units = rail.items[i].units;
      if (x < (start + units / 2) * _moduleWidth) {
        return i;
      }
      start += units;
    }
    return rail.items.length;
  }

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final UiColors c = context.uiColors;
    final int modules = rail.used > rail.capacity ? rail.used : rail.capacity;
    final String label = t.boardRail(number, rail.used, rail.capacity);
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiLabel(outside ? '$label · ${t.boardRailOutside}' : label),
          const SizedBox(height: UiSpace.xs),
          DragTarget<String>(
            onWillAcceptWithDetails: (_) => draggable,
            onAcceptWithDetails: (details) {
              final box = context.findRenderObject()! as RenderBox;
              final double x = box.globalToLocal(details.offset).dx + _moduleWidth / 2;
              onDrop(details.data, _dropIndex(x));
            },
            builder: (context, candidates, _) => SizedBox(
              width: modules * _moduleWidth,
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
                        color: candidates.isEmpty ? c.border : c.primary.withValues(alpha: .35),
                        border: Border.symmetric(horizontal: BorderSide(color: c.borderStrong)),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in rail.items)
                        _BoardItemModule(
                          item: item,
                          state: state,
                          editing: editing,
                          draggable: draggable,
                          selected: item.id == selected,
                          onSelect: () => onSelect(item.id),
                        ),
                      for (var i = rail.used; i < rail.capacity; i++) const _BlankModule(),
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

/// Conductor colours of the phases by ГОСТ 33542-2015 (IEC 60445): L1 brown, L2 black, L3 grey.
///
/// These are physical marking colours, not theme roles.
Color _phaseColor(Phase phase) => switch (phase) {
  Phase.l1 => const Color(0xFF795548),
  Phase.l2 => const Color(0xFF212121),
  Phase.l3 => const Color(0xFF9E9E9E),
};

/// Texts and look of one board item.
typedef _ModuleFace = ({
  String top,
  String title,
  String bottom,
  Color strip,
  Color? frame,
  String label,
});

class const _BoardItemModule({
  required final BoardItem item,
  required final ProjectReady state,
  required final bool editing,
  required final bool draggable,
  required final bool selected,
  required final VoidCallback onSelect,
}) extends StatelessWidget {
  _ModuleFace _face(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final UiColors c = context.uiColors;
    final ProjectResult result = state.result;
    switch (item.kind) {
      case BoardItemKind.incomer:
        return (
          top: t.boardIncomer,
          title: 'C${formatNumber(result.incomer.breakerA, 0)}',
          bottom: '${formatNumber(result.incomer.designCurrentA)} А',
          strip: c.primary,
          frame: null,
          label: t.boardIncomer,
        );
      case BoardItemKind.fireRcd:
        final SharedRcdResult rcd = result.fireRcd!;
        return (
          top: t.boardRcd,
          title: '${formatNumber(rcd.residualMa, 0)} мА',
          bottom: '${formatNumber(rcd.ratedA, 0)} А',
          strip: c.danger,
          frame: null,
          label: t.boardRcd,
        );
      case BoardItemKind.auxiliary:
        final EstimateLine line = state.estimate.lines.firstWhere((l) => l.id == item.id);
        final ApparatusRequirement? requirement = line.requirement;
        return (
          top: t.boardAuxiliary,
          // The DIN-rail socket RCBO shows its rating like circuit breakers do.
          title: requirement?.curve == null
              ? line.title
              : '${requirement!.curve!.name.toUpperCase()}${formatNumber(requirement.ratedCurrentA, 0)}',
          bottom: line.description,
          strip: c.textMuted,
          frame: null,
          label: line.title,
        );
      case BoardItemKind.groupRcd:
        final SharedRcdResult rcd = result.sharedRcds.firstWhere((r) => r.id == item.id);
        return (
          top: t.boardRcd,
          title: '${formatNumber(rcd.residualMa, 0)} мА',
          bottom: '${formatNumber(rcd.ratedA, 0)} А',
          strip: c.primary,
          frame: null,
          label: t.boardRcd,
        );
      case BoardItemKind.circuit:
        final CircuitResult circuit = result.circuits.firstWhere((x) => x.id == item.id);
        final Phase? phase = circuit.phase;
        return (
          top: '${circuit.number} · ${phase?.label ?? '3ф'}',
          title: circuit.protection.label,
          bottom: circuit.name,
          strip: phase == null ? c.primary : _phaseColor(phase),
          frame: statusStripe(circuit.status)?.color(c),
          label:
              '${circuit.number}. ${circuit.name}, '
              '${circuit.alwaysOn ? '${t.deviceAlwaysOn}, ' : ''}${circuit.status.label}',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final UiColors c = context.uiColors;
    final _ModuleFace face = _face(context);
    final CircuitResult? circuit = item.kind == BoardItemKind.circuit
        ? state.result.circuits.firstWhere((x) => x.id == item.id)
        : null;
    final void Function()? onPressed = editing
        ? onSelect
        : circuit == null
        ? null
        : () => context.go(AppRoutes.circuit(state.document.id, circuit.id));
    final module = _Module(
      units: item.units,
      top: face.top,
      title: face.title,
      bottom: face.bottom,
      strip: face.strip,
      frame: selected ? c.primary : face.frame,
      underline: item.groupId == null ? null : c.primary,
    );
    if (onPressed == null) {
      return module;
    }
    Widget pressable = UiPressable(
      onPressed: onPressed,
      selected: editing ? selected : null,
      semanticLabel: selected ? t.boardSelected(face.label) : face.label,
      builder: (context, s) => UiFocusRing(
        visible: s.focused,
        child: _Module(
          units: item.units,
          top: face.top,
          title: face.title,
          bottom: face.bottom,
          strip: face.strip,
          frame: selected ? c.primary : face.frame,
          hovered: s.hovered || selected,
          underline: item.groupId == null ? null : c.primary,
        ),
      ),
    );
    if (circuit != null && !editing) {
      pressable = Tooltip(
        message:
            '${circuit.number}. ${circuit.name}\n'
            '${circuit.alwaysOn ? '${t.circuitAlwaysOn}\n' : ''}'
            '${circuit.protection.description}\n'
            '${circuit.cable.label} мм² · ${circuit.phase?.label ?? '3ф'} · '
            '${circuit.status.label}',
        child: pressable,
      );
    }
    if (!draggable) {
      return pressable;
    }
    return Draggable<String>(
      data: item.id,
      feedback: Opacity(opacity: .85, child: module),
      childWhenDragging: Opacity(opacity: .3, child: module),
      child: pressable,
    );
  }
}

class const _Module({
  required final int units,
  required final String top,
  required final String title,
  required final String bottom,
  required final Color strip,
  final Color? frame,
  final Color? underline,
  final bool hovered = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final double width = units * _moduleWidth - 2;
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

class const _BlankModule() extends StatelessWidget {
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
