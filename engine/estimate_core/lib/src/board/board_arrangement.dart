import 'package:electrical_core/electrical_core.dart' show unset;
import 'package:estimate_core/src/board/switchboard_layout.dart';
import 'package:meta/meta.dart';

/// Switchboard arrangement chosen by the user; persisted with the estimate choices.
///
/// Each field left `null` is chosen automatically by `layoutSwitchboard`.
@immutable
final class const BoardArrangement({
  /// Enclosure as (rails, modules per rail); `null` — the smallest typical one with reserve.
  final (int, int)? enclosure,

  /// Item ids ([BoardItem.id]) by rail, top to bottom, left to right; `null` — mounting order.
  final List<List<String>>? rails,
}) {
  /// Captures the placement of [layout] as a manual arrangement keeping [enclosure].
  factory fromLayout(SwitchboardLayout layout, {(int, int)? enclosure}) => BoardArrangement(
    enclosure: enclosure,
    rails: [
      for (final rail in layout.rails) [for (final item in rail.items) item.id],
    ],
  );

  /// Parses JSON produced by [toJson].
  factory fromJson(Map<String, Object?> json) {
    final enclosure = json['enclosure'] as List<Object?>?;
    final rails = json['rails'] as List<Object?>?;
    return BoardArrangement(
      enclosure: enclosure == null ? null : (enclosure[0]! as int, enclosure[1]! as int),
      rails: rails == null
          ? null
          : [
              for (final rail in rails) [for (final id in rail! as List<Object?>) id! as String],
            ],
    );
  }

  /// Whether nothing is set manually.
  bool get isAuto => enclosure == null && rails == null;

  /// Returns a copy with the given fields replaced; pass `null` explicitly to clear a field.
  BoardArrangement copyWith({Object? enclosure = unset, Object? rails = unset}) => BoardArrangement(
    enclosure: identical(enclosure, unset) ? this.enclosure : enclosure as (int, int)?,
    rails: identical(rails, unset) ? this.rails : rails as List<List<String>>?,
  );

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
    if (enclosure case (final rails, final perRail)) 'enclosure': [rails, perRail],
    if (rails != null) 'rails': rails,
  };
}

/// Direction of a manual move on the switchboard.
enum BoardMove() {
  /// One place to the left; from the rail start — to the end of the rail above.
  left,

  /// One place to the right; from the rail end — to the start of the rail below.
  right,

  /// To the rail above, at the same distance from the rail start.
  up,

  /// To the rail below, at the same distance from the rail start.
  down,
}

/// Moves item [id] of [layout] by [move]; returns [arrangement] unchanged when the item
/// cannot move that way.
BoardArrangement moveBoardItem(
  BoardArrangement arrangement,
  SwitchboardLayout layout,
  String id,
  BoardMove move,
) {
  final List<List<String>> rails = _ids(layout);
  final (int r, int i) = _find(rails, id) ?? (-1, -1);
  if (r < 0) return arrangement;
  final List<String> rail = rails[r];
  switch (move) {
    case BoardMove.left when i > 0:
      rail.insert(i - 1, rail.removeAt(i));
    case BoardMove.left when r > 0:
      rails[r - 1].add(rail.removeAt(i));
    case BoardMove.right when i < rail.length - 1:
      rail.insert(i + 1, rail.removeAt(i));
    case BoardMove.right when r < rails.length - 1:
      rails[r + 1].insert(0, rail.removeAt(i));
    case BoardMove.up when r > 0:
    case BoardMove.down when r < rails.length - 1:
      final int target = move == BoardMove.up ? r - 1 : r + 1;
      final int offset = layout.rails[r].items.take(i).fold(0, (s, x) => s + x.units);
      var index = 0;
      var position = 0;
      for (final BoardItem item in layout.rails[target].items) {
        if (position >= offset) break;
        position += item.units;
        index++;
      }
      rails[target].insert(index, rail.removeAt(i));
    default:
      return arrangement;
  }
  return arrangement.copyWith(rails: rails);
}

/// Places item [id] of [layout] on [rail] (0-based) before the item at [index]; an index past
/// the end appends. Returns [arrangement] unchanged for an unknown id or rail.
BoardArrangement placeBoardItem(
  BoardArrangement arrangement,
  SwitchboardLayout layout,
  String id,
  int rail,
  int index,
) {
  final List<List<String>> rails = _ids(layout);
  final (int, int)? source = _find(rails, id);
  if (source == null || rail < 0 || rail >= rails.length) return arrangement;
  final (int r, int i) = source;
  rails[r].removeAt(i);
  final int target = r == rail && i < index ? index - 1 : index;
  rails[rail].insert(target.clamp(0, rails[rail].length), id);
  return arrangement.copyWith(rails: rails);
}

List<List<String>> _ids(SwitchboardLayout layout) => [
  for (final rail in layout.rails) [for (final item in rail.items) item.id],
];

(int, int)? _find(List<List<String>> rails, String id) {
  for (var r = 0; r < rails.length; r++) {
    final int i = rails[r].indexOf(id);
    if (i >= 0) return (r, i);
  }
  return null;
}
