import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/src/board/board_arrangement.dart';
import 'package:estimate_core/src/estimate/estimate_result.dart';
import 'package:estimate_core/src/estimate/requirements.dart';
import 'package:meta/meta.dart';

/// What a piece of the switchboard is.
enum BoardItemKind() {
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
final class const BoardItem({
  /// Kind.
  required final BoardItemKind kind,

  /// Circuit id for [BoardItemKind.circuit], shared RCD id for [BoardItemKind.groupRcd],
  /// estimate line id otherwise.
  required final String id,

  /// Width in DIN modules.
  required final int units,

  /// Shared RCD the item belongs to; items of one group are kept on one rail when they fit.
  final String? groupId,
});

/// One DIN rail with the items placed on it.
@immutable
final class const BoardRail({
  /// Items, left to right.
  required final List<BoardItem> items,

  /// Modules the rail holds.
  required final int capacity,
}) {
  /// Occupied modules.
  int get used => items.fold(0, (s, i) => s + i.units);
}

/// Problem of a switchboard arrangement worth showing to the user.
@immutable
sealed class const BoardWarning();

/// Items on a rail are wider than the rail.
final class const BoardRailOverfull(
  /// Rail index, 0-based.
  final int rail,
) extends BoardWarning;

/// The chosen enclosure has fewer rails than the arrangement uses.
final class const BoardEnclosureTooSmall() extends BoardWarning;

/// Less than [enclosureReserveShare] of the enclosure is free.
final class const BoardReserveLow() extends BoardWarning;

/// A shared RCD and its circuits are not side by side on one rail, so a busbar cannot
/// connect them.
final class const BoardGroupSplit(
  /// Shared RCD id.
  final String rcdId,
) extends BoardWarning;

/// Switchboard: enclosure size and the items placed on its rails.
@immutable
final class const SwitchboardLayout({
  /// Rails, top to bottom; some may be empty. Rails past [enclosureRails] do not fit the
  /// enclosure.
  required final List<BoardRail> rails,

  /// Modules per rail of the enclosure.
  required final int modulesPerRail,
  final int? _enclosureRails,
}) {
  /// Rails of the enclosure.
  int get enclosureRails => _enclosureRails ?? rails.length;

  /// Modules of the enclosure.
  int get totalModules => rails.length * modulesPerRail;

  /// Occupied modules.
  int get occupiedModules => rails.fold(0, (s, r) => s + r.used);

  /// Free modules.
  int get reserveModules => totalModules - occupiedModules;

  /// Problems of the arrangement, in board order.
  List<BoardWarning> get warnings {
    final groups = <String, List<(int, int)>>{};
    for (var r = 0; r < rails.length; r++) {
      for (var i = 0; i < rails[r].items.length; i++) {
        final String? groupId = rails[r].items[i].groupId;
        if (groupId != null) {
          (groups[groupId] ??= []).add((r, i));
        }
      }
    }
    bool split(List<(int, int)> places) {
      final (int rail, int first) = places.first;
      for (var k = 1; k < places.length; k++) {
        if (places[k] != (rail, first + k)) {
          return true;
        }
      }
      return false;
    }

    return [
      for (var r = 0; r < rails.length; r++)
        if (rails[r].used > rails[r].capacity) BoardRailOverfull(r),
      if (rails.length > enclosureRails) const BoardEnclosureTooSmall(),
      if (reserveModules < enclosureReserveShare * totalModules) const BoardReserveLow(),
      for (final MapEntry(key: id, value: places) in groups.entries)
        if (split(places)) BoardGroupSplit(id),
    ];
  }
}

/// One physical device of a board item.
@immutable
final class const BoardDevice({
  /// Width in DIN modules.
  required final int units,

  /// What the device is; `null` for auxiliary devices and when the estimate has no line.
  final ApparatusRequirement? requirement,
});

/// Devices of [item] left to right, in the order of their estimate lines.
///
/// A circuit with a separate MCB and RCD is two devices, so each is drawn with its own width.
/// When the estimate lines do not add up to the item width (no lines, typical width), the item
/// is one device.
List<BoardDevice> boardItemDevices(BoardItem item, EstimateResult estimate) {
  final List<EstimateLine> lines = [
    for (final l in estimate.lines)
      if (l.moduleUnits > 0 &&
          (item.kind == BoardItemKind.circuit
              ? l.circuitId == item.id && l.category == EstimateCategory.apparatus
              : l.id == item.id))
        l,
  ];
  if (lines.isEmpty || lines.fold(0, (s, l) => s + l.moduleUnits) != item.units) {
    return [
      BoardDevice(
        units: item.units,
        requirement: lines.length == 1 ? lines.first.requirement : null,
      ),
    ];
  }
  return [for (final l in lines) BoardDevice(units: l.moduleUnits, requirement: l.requirement)];
}

/// Typical modular enclosures, smallest first, as (rails, modules per rail).
const typicalEnclosures = [(1, 12), (1, 18), (2, 12), (2, 18), (3, 18), (4, 18), (4, 24), (5, 24)];

/// Share of the enclosure left free for future circuits.
///
/// ASSUMPTION: design practice, not a norm clause; to be confirmed at the verification stage
/// (verification/VERIFICATION.md, E9).
const enclosureReserveShare = 0.2;

/// Lists the switchboard items in mounting order: incomer, SPD, DIN-rail socket with its
/// RCBO, fire RCD, voltage relay, non-switchable circuits (with their shared RCDs), load
/// switch, the remaining shared RCD groups with their circuits, the remaining circuits.
///
/// The SPD comes right after the incomer so it also protects the voltage relay; the
/// non-switchable circuits are fed from the relay but bypass the load switch.
/// ASSUMPTION: installation practice, not a norm clause (verification/VERIFICATION.md, E10).
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
    final int units = estimate.lines.where((l) => l.id == id).firstOrNull?.moduleUnits ?? 0;
    return units > 0 ? units : typical;
  }

  Iterable<BoardItem> auxiliary(String id) => [
    for (final line in estimate.lines)
      if (line.id == id && line.moduleUnits > 0)
        BoardItem(kind: BoardItemKind.auxiliary, id: line.id, units: line.moduleUnits),
  ];

  BoardItem circuit(CircuitResult c, [String? groupId]) {
    final int units = estimate.lines
        .where((l) => l.circuitId == c.id && l.category == EstimateCategory.apparatus)
        .fold(0, (s, l) => s + l.moduleUnits);
    return BoardItem(
      kind: BoardItemKind.circuit,
      id: c.id,
      units: units > 0 ? units : _typicalCircuitWidth(c),
      groupId: groupId,
    );
  }

  final Set<String> grouped = {for (final r in result.sharedRcds) ...r.circuitIds};
  Iterable<BoardItem> circuits({required bool alwaysOn}) => [
    for (final rcd in result.sharedRcds)
      if (result.circuits.any((c) => rcd.circuitIds.contains(c.id) && c.alwaysOn == alwaysOn)) ...[
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
      if (!grouped.contains(c.id) && c.alwaysOn == alwaysOn) circuit(c),
  ];

  return [
    if (result.incomer.breakerA != null)
      BoardItem(
        kind: BoardItemKind.incomer,
        id: 'incomer/mcb',
        units: lineWidth('incomer/mcb', three ? 3 : 2),
      ),
    ...auxiliary('aux/spd'),
    if (estimate.lines.any((l) => l.id == dinSocketRcboId))
      BoardItem(
        kind: BoardItemKind.auxiliary,
        id: dinSocketRcboId,
        units: lineWidth(dinSocketRcboId, 2),
      ),
    ...auxiliary('aux/din_socket'),
    if (result.fireRcd != null)
      BoardItem(
        kind: BoardItemKind.fireRcd,
        id: 'incomer/rcd',
        units: lineWidth('incomer/rcd', result.fireRcd!.poles),
      ),
    ...auxiliary('aux/voltage_relay'),
    ...circuits(alwaysOn: true),
    ...auxiliary('aux/load_switch'),
    ...circuits(alwaysOn: false),
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
  final int occupied = items.fold(0, (s, i) => s + i.units);
  for (final (rails, perRail) in typicalEnclosures) {
    if (occupied > (1 - enclosureReserveShare) * rails * perRail) {
      continue;
    }
    final List<List<BoardItem>>? packed = _packBalanced(items, rails, perRail);
    if (packed != null) {
      return _layout(packed, rails, perRail);
    }
  }
  const perRail = 24;
  final List<List<BoardItem>> packed = _pack(items, perRail);
  return _layout(packed, packed.length, perRail);
}

/// Places [items] by [arrangement]: the chosen enclosure or the automatic one, the stored
/// order of items or the mounting order.
///
/// Stored ids missing from [items] are skipped; items missing from the arrangement go right
/// after the item before them in mounting order when its rail has room, otherwise to the
/// first rail with room, or to an extra rail. Rails that do not fit
/// the enclosure are kept and reported in [SwitchboardLayout.warnings].
SwitchboardLayout arrangeSwitchboard(List<BoardItem> items, BoardArrangement arrangement) {
  if (arrangement.isAuto) {
    return layoutSwitchboard(items);
  }
  final (int rails, int perRail) = arrangement.enclosure ?? _autoEnclosure(items);
  final List<List<String>>? stored = arrangement.rails;
  if (stored == null) {
    final List<List<BoardItem>> packed =
        _packBalanced(items, rails, perRail) ?? _pack(items, perRail);
    return _layout(packed, rails, perRail);
  }
  final Map<String, BoardItem> byId = {for (final item in items) item.id: item};
  final placed = <String>{};
  final List<List<BoardItem>> packed = [
    for (final rail in stored)
      [
        for (final id in rail)
          if (byId[id] case final item? when placed.add(id)) item,
      ],
  ];
  while (packed.length > rails && packed.last.isEmpty) {
    packed.removeLast();
  }
  while (packed.length < rails) {
    packed.add([]);
  }
  int used(List<BoardItem> rail) => rail.fold(0, (s, i) => s + i.units);
  // A device added later (e.g. the load switch) takes its place instead of the board's end.
  for (var i = 0; i < items.length; i++) {
    final BoardItem item = items[i];
    if (!placed.add(item.id)) {
      continue;
    }
    if (i > 0) {
      final BoardItem previous = items[i - 1];
      final List<BoardItem> previousRail = packed.firstWhere((r) => r.contains(previous));
      if (used(previousRail) + item.units <= perRail) {
        previousRail.insert(previousRail.indexOf(previous) + 1, item);
        continue;
      }
    }
    final List<BoardItem>? rail = packed.where((r) => used(r) + item.units <= perRail).firstOrNull;
    if (rail != null) {
      rail.add(item);
    } else {
      packed.add([item]);
    }
  }
  return _layout(packed, rails, perRail);
}

(int, int) _autoEnclosure(List<BoardItem> items) {
  final SwitchboardLayout layout = layoutSwitchboard(items);
  return (layout.rails.length, layout.modulesPerRail);
}

SwitchboardLayout _layout(List<List<BoardItem>> packed, int rails, int perRail) =>
    SwitchboardLayout(
      modulesPerRail: perRail,
      enclosureRails: rails,
      rails: [
        for (var i = 0; i < (packed.length > rails ? packed.length : rails); i++)
          BoardRail(items: i < packed.length ? packed[i] : const [], capacity: perRail),
      ],
    );

/// The smallest per-rail fill that still fits [rails], so every rail keeps some reserve;
/// null if the items do not fit.
List<List<BoardItem>>? _packBalanced(List<BoardItem> items, int rails, int perRail) {
  final int occupied = items.fold(0, (s, i) => s + i.units);
  for (int limit = (occupied / rails).ceil(); limit <= perRail; limit++) {
    final List<List<BoardItem>> packed = _pack(items, limit);
    if (packed.length <= rails) {
      return packed;
    }
  }
  return null;
}

/// Greedy packing into rails of [limit] modules; a group that fits a rail is not split.
List<List<BoardItem>> _pack(List<BoardItem> items, int limit) {
  final chunks = <List<BoardItem>>[];
  for (final item in items) {
    final String? groupId = item.groupId;
    if (groupId != null && chunks.isNotEmpty && chunks.last.first.groupId == groupId) {
      chunks.last.add(item);
    } else {
      chunks.add([item]);
    }
  }
  final rails = <List<BoardItem>>[[]];
  int used(List<BoardItem> rail) => rail.fold(0, (s, i) => s + i.units);
  for (final chunk in chunks) {
    final int size = chunk.fold(0, (s, i) => s + i.units);
    if (size <= limit) {
      if (used(rails.last) + size > limit) {
        rails.add([]);
      }
      rails.last.addAll(chunk);
    } else {
      for (final item in chunk) {
        if (used(rails.last) + item.units > limit && rails.last.isNotEmpty) {
          rails.add([]);
        }
        rails.last.add(item);
      }
    }
  }
  if (rails.length > 1 && rails.last.isEmpty) {
    rails.removeLast();
  }
  return rails;
}
