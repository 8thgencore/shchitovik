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

/// Narrowest width of one DIN module on screen; below it the board scrolls horizontally.
const _minModule = 30.0;

/// Widest width of one DIN module on screen.
const _maxModule = 52.0;

/// Switchboard drawn as DIN rails; tapping a circuit opens it.
///
/// Every device of a line has its own body as wide as its model in the estimate; a label under
/// the line carries its number and name. The module width follows the available width, and the
/// board scrolls horizontally as a whole when even the narrowest module does not fit.
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

    final int perRail = layout.rails.fold(
      layout.modulesPerRail,
      (m, r) => r.used > m ? r.used : m,
    );
    Widget rails = LayoutBuilder(
      builder: (context, constraints) {
        final double module = ((constraints.maxWidth - 2 * UiSpace.m) / perRail).clamp(
          _minModule,
          _maxModule,
        );
        return SingleChildScrollView(
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
                      module: module,
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
      },
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
  /// `null` – nothing is selected.
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
  required final double module,
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
      if (x < (start + units / 2) * module) {
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
    final double body = _bodyHeight(module);
    return Padding(
      padding: const EdgeInsets.only(bottom: UiSpace.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiLabel(outside ? '$label · ${t.boardRailOutside}' : label),
          const SizedBox(height: UiSpace.xs),
          DragTarget<String>(
            onWillAcceptWithDetails: (_) => draggable,
            onAcceptWithDetails: (details) {
              final box = context.findRenderObject()! as RenderBox;
              final double x = box.globalToLocal(details.offset).dx + module / 2;
              onDrop(details.data, _dropIndex(x));
            },
            builder: (context, candidates, _) => SizedBox(
              width: modules * module,
              child: Stack(
                children: [
                  // The DIN rail itself, seen through the free places.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: body * .36,
                    height: body * .28,
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
                        _BoardItemLine(
                          item: item,
                          module: module,
                          state: state,
                          editing: editing,
                          draggable: draggable,
                          selected: item.id == selected,
                          onSelect: () => onSelect(item.id),
                        ),
                      for (var i = rail.used; i < rail.capacity; i++) _BlankModule(module: module),
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

/// Height of a device body for a module [width], close to the real 1 : 2.6 face.
double _bodyHeight(double width) => (width * 2.6).clamp(100, 136);

/// Conductor colours of the phases by ГОСТ 33542-2015 (IEC 60445): L1 brown, L2 black, L3 grey.
///
/// These are physical marking colours, not theme roles.
Color _phaseColor(Phase phase) => switch (phase) {
  Phase.l1 => const Color(0xFF795548),
  Phase.l2 => const Color(0xFF212121),
  Phase.l3 => const Color(0xFF9E9E9E),
};

/// Black or white, whichever reads on [background].
Color _onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? const Color(0xFFFFFFFF)
    : const Color(0xFF000000);

/// Face of one device body: kind, rating and a second value (poles or residual current).
typedef _DeviceFace = ({int units, String kind, String rating, String? extra});

/// Texts and look of one board item.
typedef _LineFace = ({
  String number,
  String title,
  Color accent,
  Color? frame,
  String label,
  List<_DeviceFace> devices,
});

class const _BoardItemLine({
  required final BoardItem item,
  required final double module,
  required final ProjectReady state,
  required final bool editing,
  required final bool draggable,
  required final bool selected,
  required final VoidCallback onSelect,
}) extends StatelessWidget {
  _DeviceFace _device(
    BuildContext context,
    BoardDevice device, {
    required String kind,
    required String rating,
    String? extra,
  }) {
    final CommonTranslationsLocalizations t = context.translations;
    final ApparatusRequirement? r = device.requirement;
    if (r == null) {
      return (units: device.units, kind: kind, rating: rating, extra: extra);
    }
    final String curve = r.curve?.name.toUpperCase() ?? '';
    final String rated = formatNumber(r.ratedCurrentA, 0);
    final String? leakage = r.leakageMa == null ? null : '${formatNumber(r.leakageMa, 0)} мА';
    return switch (r.function) {
      ApparatusFunction.mcb => (
        units: device.units,
        kind: t.boardMcb,
        rating: '$curve$rated',
        extra: '${r.poles}P',
      ),
      ApparatusFunction.rcd => (
        units: device.units,
        kind: t.boardRcd,
        rating: '$rated А',
        extra: leakage,
      ),
      ApparatusFunction.rcbo => (
        units: device.units,
        kind: t.boardRcbo,
        rating: '$curve$rated',
        extra: leakage,
      ),
    };
  }

  _LineFace _face(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final UiColors c = context.uiColors;
    final ProjectResult result = state.result;
    final List<BoardDevice> devices = boardItemDevices(item, state.estimate);
    List<_DeviceFace> faces({required String kind, required String rating, String? extra}) => [
      for (final d in devices) _device(context, d, kind: kind, rating: rating, extra: extra),
    ];
    switch (item.kind) {
      case BoardItemKind.incomer:
        return (
          number: t.boardIncomer,
          title: t.boardDesignCurrent(formatNumber(result.incomer.designCurrentA)),
          accent: c.primary,
          frame: null,
          label: t.boardIncomer,
          devices: faces(kind: t.boardMcb, rating: 'C${formatNumber(result.incomer.breakerA, 0)}'),
        );
      case BoardItemKind.fireRcd:
        final SharedRcdResult rcd = result.fireRcd!;
        return (
          number: t.boardRcd,
          title: t.boardFireRcd,
          accent: c.danger,
          frame: null,
          label: '${t.boardRcd}, ${t.boardFireRcd}',
          devices: faces(
            kind: t.boardRcd,
            rating: '${formatNumber(rcd.ratedA, 0)} А',
            extra: '${formatNumber(rcd.residualMa, 0)} мА',
          ),
        );
      case BoardItemKind.auxiliary:
        final EstimateLine line = state.estimate.lines.firstWhere((l) => l.id == item.id);
        final String short = switch (item.id) {
          'aux/spd' => t.boardSpd,
          'aux/voltage_relay' => t.boardVoltageRelay,
          'aux/din_socket' => t.boardDinSocket,
          'aux/load_switch' => t.boardLoadSwitch,
          dinSocketRcboId => t.boardRcbo,
          _ => t.boardAuxiliary,
        };
        return (
          number: short,
          title: line.title,
          accent: c.textMuted,
          frame: null,
          label: line.title,
          devices: faces(kind: short, rating: ''),
        );
      case BoardItemKind.groupRcd:
        final SharedRcdResult rcd = result.sharedRcds.firstWhere((r) => r.id == item.id);
        final String numbers = [
          for (final x in result.circuits)
            if (rcd.circuitIds.contains(x.id)) x.number,
        ].join(', ');
        return (
          number: t.boardRcd,
          title: t.boardRcdGroup(numbers),
          accent: c.primary,
          frame: null,
          label: '${t.boardRcd}, ${t.boardRcdGroup(numbers)}',
          devices: faces(
            kind: t.boardRcd,
            rating: '${formatNumber(rcd.ratedA, 0)} А',
            extra: '${formatNumber(rcd.residualMa, 0)} мА',
          ),
        );
      case BoardItemKind.circuit:
        final CircuitResult circuit = result.circuits.firstWhere((x) => x.id == item.id);
        final Phase? phase = circuit.phase;
        return (
          number: '${circuit.number}',
          title: circuit.name,
          accent: phase == null ? c.primary : _phaseColor(phase),
          frame: statusStripe(circuit.status)?.color(c),
          label:
              '${circuit.number}. ${circuit.name}, '
              '${circuit.alwaysOn ? '${t.deviceAlwaysOn}, ' : ''}${circuit.status.label}',
          devices: faces(
            kind: circuit.protection.device == ProtectionDevice.rcbo ? t.boardRcbo : t.boardMcb,
            rating: circuit.protection.label,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final _LineFace face = _face(context);
    final CircuitResult? circuit = item.kind == BoardItemKind.circuit
        ? state.result.circuits.firstWhere((x) => x.id == item.id)
        : null;
    final void Function()? onPressed = editing
        ? onSelect
        : circuit == null
        ? null
        : () => context.go(AppRoutes.circuit(state.document.id, circuit.id));
    final line = _Line(
      face: face,
      module: module,
      grouped: item.groupId != null,
      selected: selected,
    );
    if (onPressed == null) {
      return line;
    }
    Widget pressable = UiPressable(
      onPressed: onPressed,
      selected: editing ? selected : null,
      semanticLabel: selected ? t.boardSelected(face.label) : face.label,
      builder: (context, s) => UiFocusRing(
        visible: s.focused,
        child: _Line(
          face: face,
          module: module,
          grouped: item.groupId != null,
          selected: selected,
          hovered: s.hovered || selected,
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
      feedback: Opacity(opacity: .85, child: line),
      childWhenDragging: Opacity(opacity: .3, child: line),
      child: pressable,
    );
  }
}

/// Devices of one line, the busbar of its RCD group and the marking label under them.
class const _Line({
  required final _LineFace face,
  required final double module,
  required final bool grouped,
  required final bool selected,
  final bool hovered = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final double width = face.devices.fold(0, (s, d) => s + d.units) * module;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Row(
            children: [
              for (final d in face.devices)
                _DeviceBody(
                  device: d,
                  module: module,
                  accent: face.accent,
                  hovered: hovered,
                ),
            ],
          ),
          // Busbar of a shared RCD group.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            child: SizedBox(
              width: double.infinity,
              height: 3,
              child: ColoredBox(color: grouped ? c.primary : const Color(0x00000000)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: _Marking(
              face: face,
              width: width - 2,
              frame: selected ? c.primary : face.frame,
            ),
          ),
        ],
      ),
    );
  }
}

/// Marking label under a line, like the stickers on a real panel: the number on the phase
/// colour and up to two lines of the name. Cable and status are in the tooltip.
class const _Marking({
  required final _LineFace face,
  required final double width,
  required final Color? frame,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
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
                color: face.accent,
                child: Center(
                  child: _FitText(
                    face.number,
                    style: UiTextStyles.valueStrong.copyWith(
                      color: _onColor(face.accent),
                      fontSize: 10,
                      height: 1.1,
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
                    face.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: UiTextStyles.caption.copyWith(
                      color: c.text,
                      fontSize: width < 50 ? 9 : 10,
                      height: 1.05,
                      fontWeight: FontWeight.w500,
                    ),
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

/// Body of one device: terminal covers, kind, rating window, lever and the test button of RCDs.
class const _DeviceBody({
  required final _DeviceFace device,
  required final double module,
  required final Color accent,
  required final bool hovered,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final UiColors c = context.uiColors;
    final double body = _bodyHeight(module);
    final double lever = (module * .34).clamp(8, 16);
    final bool rcd = device.kind == t.boardRcd || device.kind == t.boardRcbo;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: .5),
      child: SizedBox(
        width: device.units * module - 1,
        height: body,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? c.sunken : c.surface,
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
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FitText(
                        device.kind,
                        style: UiTextStyles.label.copyWith(
                          color: c.textMuted,
                          fontSize: 9,
                          letterSpacing: 0,
                        ),
                      ),
                      if (device.rating.isNotEmpty)
                        _FitText(
                          device.rating,
                          style: UiTextStyles.valueStrong.copyWith(color: c.text, fontSize: 14),
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
                            // Test button «Т».
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
                      if (device.extra case final String extra)
                        _FitText(
                          extra,
                          style: UiTextStyles.caption.copyWith(color: c.textMuted, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: body * .1,
                width: double.infinity,
                child: ColoredBox(color: c.border),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line of text shrunk to fit its width.
class const _FitText(final String text, {required final TextStyle style}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, style: style),
  );
}

/// Blank cover of a free place.
class const _BlankModule({required final double module}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final double body = _bodyHeight(module);
    return Padding(
      padding: EdgeInsets.fromLTRB(.5, body * .25, .5, 0),
      child: SizedBox(
        width: module - 1,
        height: body * .5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: .5),
            borderRadius: const BorderRadius.all(Radius.circular(2)),
            border: Border.all(color: c.borderStrong.withValues(alpha: .6)),
          ),
        ),
      ),
    );
  }
}
