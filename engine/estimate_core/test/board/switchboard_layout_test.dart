import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:test/test.dart';

List<BoardItem> _circuits(List<int> widths, {String? groupId}) => [
  for (var i = 0; i < widths.length; i++)
    BoardItem(
      kind: BoardItemKind.circuit,
      id: '${groupId ?? 'c'}$i',
      units: widths[i],
      groupId: groupId,
    ),
];

void main() {
  group('layoutSwitchboard', () {
    // (occupied modules as 1-module items, expected rails × modules per rail).
    const enclosures = [
      (1, (1, 12)),
      (9, (1, 12)),
      (10, (1, 18)),
      (14, (1, 18)),
      (15, (2, 12)),
      (19, (2, 12)),
      (20, (2, 18)),
      (28, (2, 18)),
      (29, (3, 18)),
      (43, (3, 18)),
      (44, (4, 18)),
      (57, (4, 18)),
      (58, (4, 24)),
      (76, (4, 24)),
      (77, (5, 24)),
      (96, (5, 24)),
    ];
    for (final (occupied, (rails, perRail)) in enclosures) {
      test('$occupied modules → $rails×$perRail with ≥ 20 % reserve', () {
        final SwitchboardLayout layout = layoutSwitchboard(_circuits(List.filled(occupied, 1)));
        expect((layout.rails.length, layout.modulesPerRail), (rails, perRail));
        expect(layout.occupiedModules, occupied);
        expect(layout.reserveModules, greaterThanOrEqualTo(0.2 * layout.totalModules));
      });
    }

    test('beyond typical enclosures adds rails of 24 modules', () {
      final SwitchboardLayout layout = layoutSwitchboard(_circuits(List.filled(130, 1)));
      expect(layout.modulesPerRail, 24);
      expect(layout.rails.length, 6);
      expect(layout.occupiedModules, 130);
    });

    test('reserve is spread over all rails', () {
      final SwitchboardLayout layout = layoutSwitchboard(_circuits(List.filled(40, 1)));
      expect(layout.rails.map((r) => r.used), [14, 14, 12]);
    });

    test('a shared RCD group is not split between rails', () {
      final List<BoardItem> items = [
        ..._circuits(List.filled(10, 1)),
        const BoardItem(kind: BoardItemKind.groupRcd, id: 'g', units: 2, groupId: 'g'),
        ..._circuits([1, 1, 1, 1, 1, 1], groupId: 'g'),
      ];
      final SwitchboardLayout layout = layoutSwitchboard(items);
      final Iterable<BoardRail> railsWithGroup = layout.rails.where(
        (r) => r.items.any((i) => i.groupId == 'g'),
      );
      expect(railsWithGroup, hasLength(1));
      expect(railsWithGroup.single.items.where((i) => i.groupId == 'g'), hasLength(7));
    });

    test('a group wider than a rail is split item by item', () {
      final List<BoardItem> items = _circuits(List.filled(30, 1), groupId: 'g');
      final SwitchboardLayout layout = layoutSwitchboard(items);
      expect(layout.occupiedModules, 30);
      for (final BoardRail rail in layout.rails) {
        expect(rail.used, lessThanOrEqualTo(rail.capacity));
      }
    });

    test('order of items is kept', () {
      final List<BoardItem> items = _circuits([1, 2, 4, 1, 3, 2, 2, 1, 4, 1, 1, 2]);
      final SwitchboardLayout layout = layoutSwitchboard(items);
      expect(layout.rails.expand((r) => r.items).map((i) => i.id), items.map((i) => i.id));
    });
  });

  group('switchboardItems', () {
    final Map<String, ProjectInput> demos = {
      '1-room apartment': DemoProjects.oneRoomApartment(),
      '3-room apartment': DemoProjects.threeRoomApartment(),
      'house': DemoProjects.house(),
    };
    for (final MapEntry(key: name, value: input) in demos.entries) {
      test('$name: board width equals estimate modules, every circuit is placed', () {
        final ProjectResult result = calculateProject(input);
        final EstimateResult estimate = calculateEstimate(input, result, const EstimateInput());
        final List<BoardItem> items = switchboardItems(input, result, estimate);
        expect(items.fold(0, (s, i) => s + i.units), estimate.moduleUnits);
        expect(
          items.where((i) => i.kind == BoardItemKind.circuit).map((i) => i.id).toSet(),
          result.circuits.map((c) => c.id).toSet(),
        );
        expect(items.first.kind, BoardItemKind.incomer);
      });
    }
  });
}
