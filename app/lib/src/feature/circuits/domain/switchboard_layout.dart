import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:meta/meta.dart';

/// What a piece of the switchboard is.
enum BoardItemKind {
  /// Incomer breaker.
  incomer,

  /// Fire-protection RCD at the input.
  fireRcd,

  /// Auxiliary device from the estimate (SPD, voltage relay, …).
  auxiliary,

  /// RCD shared by a group of circuits.
  groupRcd,

  /// Protection of one circuit (MCB, RCBO or MCB + RCD).
  circuit,
}

/// One device (or the set of devices of one circuit) placed on a DIN rail.
@immutable
final class BoardItem {
  const BoardItem({required this.kind, required this.id, required this.units, this.groupId});

  /// Kind.
  final BoardItemKind kind;

  /// Circuit id for [BoardItemKind.circuit], shared RCD id for [BoardItemKind.groupRcd],
  /// estimate line id otherwise.
  final String id;

  /// Width in DIN modules.
  final int units;

  /// Shared RCD the item belongs to; items of one group are kept on one rail when they fit.
  final String? groupId;
}

/// One DIN rail with the items placed on it.
@immutable
final class BoardRail {
  const BoardRail({required this.items, required this.capacity});

  /// Items, left to right.
  final List<BoardItem> items;

  /// Modules the rail holds.
  final int capacity;

  /// Occupied modules.
  int get used => items.fold(0, (s, i) => s + i.units);
}

/// Switchboard: enclosure size and the items placed on its rails.
@immutable
final class SwitchboardLayout {
  const SwitchboardLayout({required this.rails, required this.modulesPerRail});

  /// Rails, top to bottom; some may be empty.
  final List<BoardRail> rails;

  /// Modules per rail of the enclosure.
  final int modulesPerRail;

  /// Modules of the enclosure.
  int get totalModules => rails.length * modulesPerRail;

  /// Occupied modules.
  int get occupiedModules => rails.fold(0, (s, r) => s + r.used);

  /// Free modules.
  int get reserveModules => totalModules - occupiedModules;
}

/// Typical modular enclosures, smallest first, as (rails, modules per rail).
const typicalEnclosures = [(1, 12), (1, 18), (2, 12), (2, 18), (3, 18), (4, 18), (4, 24), (5, 24)];

/// Share of the enclosure left free for future circuits.
///
/// ASSUMPTION: design practice, not a norm clause; to be confirmed at the verification stage
/// (verification/VERIFICATION.md, E9) before enclosure selection moves into `estimate_core`.
const enclosureReserveShare = 0.2;

/// Lists the switchboard items in mounting order: incomer, fire RCD, auxiliary devices,
/// shared RCD groups with their circuits, the remaining circuits.
///
/// Widths come from the models in [estimate]; when a line has no width, a typical width
/// for the device is used.
List<BoardItem> switchboardItems(
  ProjectInput input,
  ProjectResult result,
  EstimateResult estimate,
) {
  final three = input.supplyPhases == SupplyPhases.three;
  int lineWidth(String id, int typical) {
    final units = estimate.lines.where((l) => l.id == id).firstOrNull?.moduleUnits ?? 0;
    return units > 0 ? units : typical;
  }

  BoardItem circuit(CircuitResult c, [String? groupId]) {
    final units = estimate.lines
        .where((l) => l.circuitId == c.id && l.category == EstimateCategory.apparatus)
        .fold(0, (s, l) => s + l.moduleUnits);
    return BoardItem(
      kind: BoardItemKind.circuit,
      id: c.id,
      units: units > 0 ? units : _typicalCircuitWidth(c),
      groupId: groupId,
    );
  }

  final grouped = {for (final r in result.sharedRcds) ...r.circuitIds};
  return [
    if (result.incomer.breakerA != null)
      BoardItem(
        kind: BoardItemKind.incomer,
        id: 'incomer/mcb',
        units: lineWidth('incomer/mcb', three ? 3 : 2),
      ),
    if (result.fireRcd != null)
      BoardItem(
        kind: BoardItemKind.fireRcd,
        id: 'incomer/rcd',
        units: lineWidth('incomer/rcd', result.fireRcd!.poles),
      ),
    for (final line in estimate.lines)
      if (line.category == EstimateCategory.auxiliary && line.moduleUnits > 0)
        BoardItem(kind: BoardItemKind.auxiliary, id: line.id, units: line.moduleUnits),
    for (final rcd in result.sharedRcds) ...[
      BoardItem(
        kind: BoardItemKind.groupRcd,
        id: rcd.id,
        units: lineWidth(rcd.id, rcd.poles),
        groupId: rcd.id,
      ),
      for (final c in result.circuits)
        if (rcd.circuitIds.contains(c.id)) circuit(c, rcd.id),
    ],
    for (final c in result.circuits)
      if (!grouped.contains(c.id)) circuit(c),
  ];
}

int _typicalCircuitWidth(CircuitResult c) {
  final three = c.phases == 3;
  return switch (c.protection.device) {
    ProtectionDevice.rcbo => three ? 4 : 2,
    ProtectionDevice.mcbAndRcd => (three ? 3 : 1) + (three ? 4 : 2),
    ProtectionDevice.mcb || ProtectionDevice.mcbUnderGroupRcd => three ? 3 : 1,
  };
}

/// Places [items] into the smallest of [typicalEnclosures] that keeps at least
/// [enclosureReserveShare] free, spreading the reserve over all rails.
///
/// Items of one shared RCD group stay on one rail when the group fits a rail. If no typical
/// enclosure fits, rails of 24 modules are added as needed.
SwitchboardLayout layoutSwitchboard(List<BoardItem> items) {
  final occupied = items.fold(0, (s, i) => s + i.units);
  for (final (rails, perRail) in typicalEnclosures) {
    if (occupied > (1 - enclosureReserveShare) * rails * perRail) continue;
    final packed = _packBalanced(items, rails, perRail);
    if (packed != null) return _layout(packed, rails, perRail);
  }
  const perRail = 24;
  final packed = _pack(items, perRail);
  return _layout(packed, packed.length, perRail);
}

SwitchboardLayout _layout(List<List<BoardItem>> packed, int rails, int perRail) =>
    SwitchboardLayout(
      modulesPerRail: perRail,
      rails: [
        for (var i = 0; i < rails; i++)
          BoardRail(items: i < packed.length ? packed[i] : const [], capacity: perRail),
      ],
    );

/// The smallest per-rail fill that still fits [rails], so every rail keeps some reserve;
/// null if the items do not fit.
List<List<BoardItem>>? _packBalanced(List<BoardItem> items, int rails, int perRail) {
  final occupied = items.fold(0, (s, i) => s + i.units);
  for (var limit = (occupied / rails).ceil(); limit <= perRail; limit++) {
    final packed = _pack(items, limit);
    if (packed.length <= rails) return packed;
  }
  return null;
}

/// Greedy packing into rails of [limit] modules; a group that fits a rail is not split.
List<List<BoardItem>> _pack(List<BoardItem> items, int limit) {
  final chunks = <List<BoardItem>>[];
  for (final item in items) {
    final groupId = item.groupId;
    if (groupId != null && chunks.isNotEmpty && chunks.last.first.groupId == groupId) {
      chunks.last.add(item);
    } else {
      chunks.add([item]);
    }
  }
  final rails = <List<BoardItem>>[[]];
  int used(List<BoardItem> rail) => rail.fold(0, (s, i) => s + i.units);
  for (final chunk in chunks) {
    final size = chunk.fold(0, (s, i) => s + i.units);
    if (size <= limit) {
      if (used(rails.last) + size > limit) rails.add([]);
      rails.last.addAll(chunk);
    } else {
      for (final item in chunk) {
        if (used(rails.last) + item.units > limit && rails.last.isNotEmpty) rails.add([]);
        rails.last.add(item);
      }
    }
  }
  if (rails.length > 1 && rails.last.isEmpty) rails.removeLast();
  return rails;
}
