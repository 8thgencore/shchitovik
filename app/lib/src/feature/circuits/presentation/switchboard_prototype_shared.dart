// PROTOTYPE – throwaway (branch prototype/board-design). Question: how should devices look on
// the DIN rail so that texts fit and widths read right? Variants: switchboard_prototype_*.dart.
// ignore_for_file: avoid_positional_boolean_parameters, omit_obvious_local_variable_types, unnecessary_type_name_in_constructor, use_key_in_widget_constructors, use_primary_constructors
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shchitovik/src/feature/circuits/presentation/status_badge.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/logic/app_router.dart';

/// One physical device of a board item.
typedef ProtoDevice = ({int units, String kind, String rating, String? extra});

/// Everything a variant needs to draw one board item.
final class ProtoItem {
  ProtoItem._({
    required this.item,
    required this.devices,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.frame,
    required this.semantic,
    required this.tooltip,
    required this.circuit,
  });

  final BoardItem item;
  final List<ProtoDevice> devices;

  /// Circuit number, or a short code for input devices (`ВВ`, `УЗО`, …).
  final String number;
  final String title;
  final String subtitle;

  /// Phase colour for circuits, role colour otherwise.
  final Color accent;

  /// Status colour when the circuit needs attention.
  final Color? frame;
  final String semantic;
  final String? tooltip;
  final CircuitResult? circuit;

  int get units => item.units;
}

/// Conductor colours of the phases by ГОСТ 33542-2015 (IEC 60445): L1 brown, L2 black, L3 grey.
Color protoPhaseColor(Phase phase) => switch (phase) {
  Phase.l1 => const Color(0xFF795548),
  Phase.l2 => const Color(0xFF212121),
  Phase.l3 => const Color(0xFF9E9E9E),
};

/// Text colour readable on [background].
Color protoOn(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? const Color(0xFFFFFFFF)
    : const Color(0xFF000000);

String _n(double v) => formatNumber(v, 0);

/// Short marking of an auxiliary device for a narrow body.
String protoShortKind(String title) {
  final String t = title.toLowerCase();
  return t.contains('реле напряж')
      ? 'РН'
      : t.contains('узип') || t.contains('импульс')
      ? 'УЗИП'
      : t.contains('счётчик') || t.contains('счетчик')
      ? 'Wh'
      : title;
}

ProtoDevice _device(EstimateLine line) {
  final ApparatusRequirement? r = line.requirement;
  if (r == null) {
    return (units: line.moduleUnits, kind: protoShortKind(line.title), rating: '', extra: null);
  }
  final String curve = r.curve == null ? '' : r.curve!.name.toUpperCase();
  return switch (r.function) {
    ApparatusFunction.mcb => (
      units: line.moduleUnits,
      kind: 'АВ',
      rating: '$curve${_n(r.ratedCurrentA)}',
      extra: '${r.poles}P',
    ),
    ApparatusFunction.rcd => (
      units: line.moduleUnits,
      kind: 'УЗО',
      rating: '${_n(r.ratedCurrentA)} А',
      extra: r.leakageMa == null ? null : '${_n(r.leakageMa!)} мА',
    ),
    ApparatusFunction.rcbo => (
      units: line.moduleUnits,
      kind: 'АВДТ',
      rating: '$curve${_n(r.ratedCurrentA)}',
      extra: r.leakageMa == null ? null : '${_n(r.leakageMa!)} мА',
    ),
  };
}

int _order(ProtoDevice d) => switch (d.kind) {
  'УЗО' => 0,
  'АВДТ' => 1,
  _ => 2,
};

/// Splits an item into its devices; falls back to one device when the estimate disagrees.
List<ProtoDevice> _devices(BoardItem item, ProjectReady state, ProtoDevice fallback) {
  final List<EstimateLine> lines = [
    for (final l in state.estimate.lines)
      if (item.kind == BoardItemKind.circuit
          ? l.circuitId == item.id && l.category == EstimateCategory.apparatus
          : l.id == item.id)
        l,
  ];
  final List<ProtoDevice> devices = [
    for (final l in lines)
      if (l.moduleUnits > 0) _device(l),
  ]..sort((a, b) => _order(a) - _order(b));
  return devices.isEmpty || devices.fold(0, (s, d) => s + d.units) != item.units
      ? [fallback]
      : devices;
}

/// Collects the texts and colours of [item].
ProtoItem protoItem(BuildContext context, BoardItem item, ProjectReady state) {
  final UiColors c = context.uiColors;
  final ProjectResult result = state.result;
  switch (item.kind) {
    case BoardItemKind.incomer:
      final rating = 'C${_n(result.incomer.breakerA ?? 0)}';
      return ProtoItem._(
        item: item,
        devices: _devices(item, state, (
          units: item.units,
          kind: 'АВ',
          rating: rating,
          extra: null,
        )),
        number: 'ВВ',
        title: 'Вводной',
        subtitle: 'Iр ${formatNumber(result.incomer.designCurrentA)} А',
        accent: c.primary,
        frame: null,
        semantic: 'Вводной автомат $rating',
        tooltip: null,
        circuit: null,
      );
    case BoardItemKind.fireRcd:
      final SharedRcdResult rcd = result.fireRcd!;
      return ProtoItem._(
        item: item,
        devices: _devices(item, state, (
          units: item.units,
          kind: 'УЗО',
          rating: '${_n(rcd.ratedA)} А',
          extra: '${_n(rcd.residualMa)} мА',
        )),
        number: 'УЗО',
        title: 'Противопожарное',
        subtitle: '${_n(rcd.residualMa)} мА',
        accent: c.danger,
        frame: null,
        semantic: 'Противопожарное УЗО',
        tooltip: null,
        circuit: null,
      );
    case BoardItemKind.auxiliary:
      final EstimateLine line = state.estimate.lines.firstWhere((l) => l.id == item.id);
      return ProtoItem._(
        item: item,
        devices: _devices(item, state, (
          units: item.units,
          kind: protoShortKind(line.title),
          rating: '',
          extra: null,
        )),
        number: protoShortKind(line.title),
        title: line.title,
        subtitle: line.description,
        accent: c.textMuted,
        frame: null,
        semantic: line.title,
        tooltip: line.description,
        circuit: null,
      );
    case BoardItemKind.groupRcd:
      final SharedRcdResult rcd = result.sharedRcds.firstWhere((r) => r.id == item.id);
      final String numbers = [
        for (final x in result.circuits)
          if (rcd.circuitIds.contains(x.id)) x.number,
      ].join(', ');
      return ProtoItem._(
        item: item,
        devices: _devices(item, state, (
          units: item.units,
          kind: 'УЗО',
          rating: '${_n(rcd.ratedA)} А',
          extra: '${_n(rcd.residualMa)} мА',
        )),
        number: 'УЗО',
        title: 'Группа $numbers',
        subtitle: '${_n(rcd.residualMa)} мА',
        accent: c.primary,
        frame: null,
        semantic: 'Групповое УЗО, линии $numbers',
        tooltip: null,
        circuit: null,
      );
    case BoardItemKind.circuit:
      final CircuitResult circuit = result.circuits.firstWhere((x) => x.id == item.id);
      final Phase? phase = circuit.phase;
      return ProtoItem._(
        item: item,
        devices: _devices(item, state, (
          units: item.units,
          kind: circuit.protection.device == ProtectionDevice.rcbo ? 'АВДТ' : 'АВ',
          rating: circuit.protection.label,
          extra: null,
        )),
        number: '${circuit.number}',
        title: circuit.name,
        subtitle: '${circuit.cable.label} мм² · ${phase?.label ?? '3ф'}',
        accent: phase == null ? c.primary : protoPhaseColor(phase),
        frame: statusStripe(circuit.status)?.color(c),
        semantic: '${circuit.number}. ${circuit.name}, ${circuit.status.label}',
        tooltip:
            '${circuit.number}. ${circuit.name}\n${circuit.protection.description}\n'
            '${circuit.cable.label} мм² · ${phase?.label ?? '3ф'} · ${circuit.status.label}',
        circuit: circuit,
      );
  }
}

/// Size of one DIN module for the available [width], kept within [min]..[max].
double protoModule(double width, SwitchboardLayout layout, double min, double max) {
  final int perRail = layout.rails.fold(
    layout.modulesPerRail,
    (m, r) => r.used > m ? r.used : m,
  );
  return (width / perRail).clamp(min, max);
}

/// Index before which an item whose start is dropped at [offset] along the rail goes.
int protoDropIndex(BoardRail rail, double module, double offset) {
  final double x = offset + module / 2;
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

/// Shared callbacks of the board for the variants.
typedef ProtoBoard = ({
  ProjectReady state,
  bool editing,
  bool draggable,
  String? selected,
  ValueChanged<String> onSelect,
  void Function(String id, int rail, int index) onDrop,
});

/// Tap, selection, tooltip and drag around a variant's face of an item.
class const ProtoItemShell({
  required final ProtoItem info,
  required final ProtoBoard board,
  required final Widget Function(bool hovered, bool selected) face,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool selected = info.item.id == board.selected;
    final CircuitResult? circuit = info.circuit;
    final VoidCallback? onPressed = board.editing
        ? () => board.onSelect(info.item.id)
        : circuit == null
        ? null
        : () => context.go(AppRoutes.circuit(board.state.document.id, circuit.id));
    final Widget still = face(false, selected);
    if (onPressed == null) {
      return still;
    }
    Widget pressable = UiPressable(
      onPressed: onPressed,
      selected: board.editing ? selected : null,
      semanticLabel: info.semantic,
      builder: (context, s) => UiFocusRing(
        visible: s.focused,
        child: face(s.hovered, selected),
      ),
    );
    if (info.tooltip != null && !board.editing) {
      pressable = Tooltip(message: info.tooltip, child: pressable);
    }
    if (!board.draggable) {
      return pressable;
    }
    return Draggable<String>(
      data: info.item.id,
      feedback: Opacity(opacity: .85, child: still),
      childWhenDragging: Opacity(opacity: .3, child: still),
      child: pressable,
    );
  }
}

/// Drop target over one rail; [builder] draws the rail, `true` while a device hovers it.
class const ProtoDropRail({
  required final BoardRail rail,
  required final int index,
  required final double module,
  required final ProtoBoard board,
  required final Widget Function(bool active) builder,
  final Axis axis = Axis.horizontal,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DragTarget<String>(
    onWillAcceptWithDetails: (_) => board.draggable,
    onAcceptWithDetails: (details) {
      final box = context.findRenderObject()! as RenderBox;
      final Offset local = box.globalToLocal(details.offset);
      board.onDrop(
        details.data,
        index,
        protoDropIndex(rail, module, axis == Axis.horizontal ? local.dx : local.dy),
      );
    },
    builder: (context, candidates, _) => builder(candidates.isNotEmpty),
  );
}

/// Rail caption like the current view.
String protoRailLabel(int number, BoardRail rail, bool outside) =>
    'Рейка $number · ${rail.used}/${rail.capacity} мод.${outside ? ' · вне корпуса' : ''}';
