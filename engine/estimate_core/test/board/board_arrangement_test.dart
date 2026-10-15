import 'package:estimate_core/estimate_core.dart';
import 'package:test/test.dart';

BoardItem _item(String id, [int units = 1, String? groupId]) =>
    BoardItem(kind: BoardItemKind.circuit, id: id, units: units, groupId: groupId);

List<List<String>> _ids(SwitchboardLayout layout) => [
  for (final rail in layout.rails) [for (final item in rail.items) item.id],
];

void main() {
  group('BoardArrangement JSON', () {
    const arrangements = [
      BoardArrangement(),
      BoardArrangement(enclosure: (2, 18)),
      BoardArrangement(
        rails: [
          ['a', 'b'],
          [],
          ['c'],
        ],
      ),
      BoardArrangement(
        enclosure: (3, 12),
        rails: [
          ['a'],
          ['b'],
        ],
      ),
    ];
    for (final a in arrangements) {
      test('round-trip ${a.toJson()}', () {
        final decoded = BoardArrangement.fromJson(a.toJson());
        expect(decoded.toJson(), a.toJson());
        expect(decoded.enclosure, a.enclosure);
        expect(decoded.rails, a.rails);
      });
    }

    test('EstimateInput without board is automatic and omits the key', () {
      final input = EstimateInput.fromJson(const {});
      expect(input.board.isAuto, isTrue);
      expect(input.toJson().containsKey('board'), isFalse);
    });

    test('EstimateInput keeps a manual board', () {
      const board = BoardArrangement(
        enclosure: (2, 12),
        rails: [
          ['b', 'a'],
        ],
      );
      final input = EstimateInput.fromJson(const EstimateInput(board: board).toJson());
      expect(input.board.toJson(), board.toJson());
    });
  });

  group('arrangeSwitchboard', () {
    final List<BoardItem> items = [_item('a'), _item('b', 2), _item('c'), _item('d')];

    test('automatic arrangement equals layoutSwitchboard', () {
      final SwitchboardLayout auto = layoutSwitchboard(items);
      final SwitchboardLayout arranged = arrangeSwitchboard(items, const BoardArrangement());
      expect(_ids(arranged), _ids(auto));
      expect(arranged.modulesPerRail, auto.modulesPerRail);
    });

    // (arrangement, expected rails of ids, expected enclosure rails × modules).
    final cases = <String, (BoardArrangement, List<List<String>>, (int, int))>{
      'stored order is kept': (
        const BoardArrangement(
          rails: [
            ['d', 'c', 'b', 'a'],
          ],
        ),
        [
          ['d', 'c', 'b', 'a'],
        ],
        (1, 12),
      ),
      'unknown ids are skipped, new items fill the first rail with room': (
        const BoardArrangement(
          rails: [
            ['x', 'c', 'a'],
          ],
        ),
        [
          ['c', 'a', 'b', 'd'],
        ],
        (1, 12),
      ),
      'manual enclosure with stored rails keeps empty rails': (
        const BoardArrangement(
          enclosure: (3, 12),
          rails: [
            ['a'],
            [],
            ['b', 'c', 'd'],
          ],
        ),
        [
          ['a'],
          [],
          ['b', 'c', 'd'],
        ],
        (3, 12),
      ),
      'manual enclosure only packs in mounting order, spreading the reserve': (
        const BoardArrangement(enclosure: (2, 12)),
        [
          ['a', 'b'],
          ['c', 'd'],
        ],
        (2, 12),
      ),
    };
    for (final MapEntry(key: name, value: (arrangement, rails, enclosure)) in cases.entries) {
      test(name, () {
        final SwitchboardLayout layout = arrangeSwitchboard(items, arrangement);
        expect(_ids(layout), rails);
        expect((layout.enclosureRails, layout.modulesPerRail), enclosure);
      });
    }

    test('items that do not fit the enclosure go to an extra rail', () {
      final List<BoardItem> wide = [for (var i = 0; i < 14; i++) _item('w$i')];
      final SwitchboardLayout layout = arrangeSwitchboard(
        wide,
        const BoardArrangement(enclosure: (1, 12)),
      );
      expect(layout.rails, hasLength(2));
      expect(layout.enclosureRails, 1);
      expect(layout.warnings.whereType<BoardEnclosureTooSmall>(), hasLength(1));
    });
  });

  group('warnings', () {
    // (rails of (id, units, group), expected warning types).
    final cases = <String, (List<List<BoardItem>>, List<Type>)>{
      'none': (
        [
          [_item('a'), _item('b')],
        ],
        [],
      ),
      'overfull rail and low reserve': (
        [
          [for (var i = 0; i < 13; i++) _item('a$i')],
        ],
        [BoardRailOverfull, BoardReserveLow],
      ),
      'group side by side': (
        [
          [_item('g', 2, 'g'), _item('g1', 1, 'g'), _item('g2', 1, 'g'), _item('x')],
        ],
        [],
      ),
      'group not side by side': (
        [
          [_item('g', 2, 'g'), _item('x'), _item('g1', 1, 'g')],
        ],
        [BoardGroupSplit],
      ),
      'group on two rails': (
        [
          [_item('g', 2, 'g')],
          [_item('g1', 1, 'g')],
        ],
        [BoardGroupSplit],
      ),
    };
    for (final MapEntry(key: name, value: (rails, expected)) in cases.entries) {
      test(name, () {
        final layout = SwitchboardLayout(
          modulesPerRail: 12,
          rails: [for (final r in rails) BoardRail(items: r, capacity: 12)],
        );
        expect(layout.warnings.map((w) => w.runtimeType), expected);
      });
    }
  });

  group('moveBoardItem', () {
    final List<BoardItem> items = [
      _item('a'),
      _item('b', 2),
      _item('c'),
      _item('d'),
      _item('e', 3),
      _item('f'),
    ];
    final SwitchboardLayout layout = arrangeSwitchboard(
      items,
      const BoardArrangement(
        enclosure: (2, 12),
        rails: [
          ['a', 'b', 'c'],
          ['d', 'e', 'f'],
        ],
      ),
    );

    // (id, move, expected rails; null — unchanged).
    final cases = <(String, BoardMove, List<List<String>>?)>[
      (
        'b',
        BoardMove.left,
        [
          ['b', 'a', 'c'],
          ['d', 'e', 'f'],
        ],
      ),
      ('a', BoardMove.left, null),
      (
        'd',
        BoardMove.left,
        [
          ['a', 'b', 'c', 'd'],
          ['e', 'f'],
        ],
      ),
      (
        'b',
        BoardMove.right,
        [
          ['a', 'c', 'b'],
          ['d', 'e', 'f'],
        ],
      ),
      (
        'c',
        BoardMove.right,
        [
          ['a', 'b'],
          ['c', 'd', 'e', 'f'],
        ],
      ),
      ('f', BoardMove.right, null),
      // 'c' starts at module 3; on rail 2 module 3 is the end of 'e' (1 + 3 = 4 > 3).
      (
        'c',
        BoardMove.down,
        [
          ['a', 'b'],
          ['d', 'e', 'c', 'f'],
        ],
      ),
      (
        'd',
        BoardMove.up,
        [
          ['d', 'a', 'b', 'c'],
          ['e', 'f'],
        ],
      ),
      ('a', BoardMove.up, null),
      ('f', BoardMove.down, null),
    ];
    for (final (id, move, expected) in cases) {
      test('$id ${move.name}', () {
        const start = BoardArrangement(enclosure: (2, 12));
        final BoardArrangement moved = moveBoardItem(start, layout, id, move);
        if (expected == null) {
          expect(identical(moved, start), isTrue);
        } else {
          expect(moved.rails, expected);
          expect(moved.enclosure, (2, 12));
        }
      });
    }
  });

  group('placeBoardItem', () {
    final SwitchboardLayout layout = arrangeSwitchboard(
      [_item('a'), _item('b'), _item('c'), _item('d')],
      const BoardArrangement(
        enclosure: (2, 12),
        rails: [
          ['a', 'b', 'c'],
          ['d'],
        ],
      ),
    );

    // (id, rail, index, expected rails).
    final cases = <(String, int, int, List<List<String>>)>[
      (
        'a',
        0,
        3,
        [
          ['b', 'c', 'a'],
          ['d'],
        ],
      ),
      (
        'c',
        0,
        0,
        [
          ['c', 'a', 'b'],
          ['d'],
        ],
      ),
      (
        'b',
        1,
        0,
        [
          ['a', 'c'],
          ['b', 'd'],
        ],
      ),
      (
        'b',
        1,
        99,
        [
          ['a', 'c'],
          ['d', 'b'],
        ],
      ),
    ];
    for (final (id, rail, index, expected) in cases) {
      test('$id → rail $rail at $index', () {
        final BoardArrangement placed = placeBoardItem(
          const BoardArrangement(),
          layout,
          id,
          rail,
          index,
        );
        expect(placed.rails, expected);
      });
    }

    test('unknown rail leaves the arrangement unchanged', () {
      const start = BoardArrangement();
      expect(identical(placeBoardItem(start, layout, 'a', 5, 0), start), isTrue);
    });
  });
}
