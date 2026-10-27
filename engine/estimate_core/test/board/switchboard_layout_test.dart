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

      test('$name: mounting order – protection devices, non-switchable lines, load switch', () {
        final ProjectResult result = calculateProject(input);
        final EstimateResult estimate = calculateEstimate(input, result, const EstimateInput());
        final List<String> ids = [
          for (final i in switchboardItems(input, result, estimate)) i.id,
        ];
        const List<String> sequence = [
          'incomer/mcb',
          'aux/spd',
          dinSocketRcboId,
          'aux/din_socket',
          'incomer/rcd',
          'aux/voltage_relay',
          'aux/load_switch',
        ];
        final List<String> present = [
          for (final id in sequence)
            if (ids.contains(id)) id,
        ];
        expect(ids.where(sequence.contains).toList(), present);
        expect(present, containsAll(['incomer/mcb', dinSocketRcboId, 'aux/load_switch']));

        final int loadSwitch = ids.indexOf('aux/load_switch');
        for (final CircuitResult c in result.circuits) {
          final Matcher side = c.alwaysOn ? lessThan(loadSwitch) : greaterThan(loadSwitch);
          expect(ids.indexOf(c.id), side, reason: c.id);
          expect(ids.indexOf(c.id), greaterThan(ids.indexOf('aux/voltage_relay')), reason: c.id);
        }
      });
    }

    test('apartments have a non-switchable line', () {
      final ProjectInput input = DemoProjects.threeRoomApartment();
      expect(calculateProject(input).circuits.where((c) => c.alwaysOn), isNotEmpty);
    });

    test('without switchable circuits there is no load switch', () {
      final ProjectInput input = DemoProjects.oneRoomApartment();
      final ProjectInput fridgeOnly = input.copyWith(
        devices: [
          for (final d in input.devices)
            if (d.alwaysOn) d,
        ],
      );
      final EstimateResult estimate = calculateEstimate(
        fridgeOnly,
        calculateProject(fridgeOnly),
        const EstimateInput(),
      );
      expect(estimate.lines.map((l) => l.id), isNot(contains('aux/load_switch')));
    });

    test('a device without a catalog model keeps a typical width (relay for 80 A)', () {
      final ProjectInput base = DemoProjects.oneRoomApartment();
      final ProjectInput input = base.copyWith(supply: const SupplyInput(incomerBreakerA: 80));
      final ProjectResult result = calculateProject(input);
      final EstimateResult estimate = calculateEstimate(input, result, const EstimateInput());
      final EstimateLine relay = estimate.lines.firstWhere((l) => l.id == 'aux/voltage_relay');
      expect(relay.missing, isNotEmpty);
      final EstimateLine loadSwitch = estimate.lines.firstWhere((l) => l.id == 'aux/load_switch');
      expect(loadSwitch.description, 'Выключатель нагрузки 2P 100 А');
      final BoardItem item = switchboardItems(
        input,
        result,
        estimate,
      ).firstWhere((i) => i.id == 'aux/voltage_relay');
      expect(item.units, 2);
    });
  });

  group('boardItemDevices', () {
    test('devices of every demo item add up to its width', () {
      for (final ProjectInput input in [
        DemoProjects.oneRoomApartment(),
        DemoProjects.threeRoomApartment(),
        DemoProjects.house(),
      ]) {
        final ProjectResult result = calculateProject(input);
        final EstimateResult estimate = calculateEstimate(input, result, const EstimateInput());
        for (final BoardItem item in switchboardItems(input, result, estimate)) {
          final List<BoardDevice> devices = boardItemDevices(item, estimate);
          expect(devices.fold(0, (s, d) => s + d.units), item.units, reason: item.id);
        }
      }
    });

    test('separate MCB and RCD of a socket circuit are two devices in estimate order', () {
      final ProjectInput input = DemoProjects.oneRoomApartment().copyWith(
        rcdStrategy: RcdStrategy.rcdPerCircuit,
      );
      final ProjectResult result = calculateProject(input);
      final EstimateResult estimate = calculateEstimate(input, result, const EstimateInput());
      final CircuitResult sockets = result.circuits.firstWhere(
        (c) => c.protection.device == ProtectionDevice.mcbAndRcd,
      );
      final BoardItem item = switchboardItems(
        input,
        result,
        estimate,
      ).firstWhere((i) => i.id == sockets.id);
      final List<BoardDevice> devices = boardItemDevices(item, estimate);
      final List<ApparatusFunction?> functions = [
        for (final d in devices) d.requirement?.function,
      ];
      final List<ApparatusFunction?> lines = [
        for (final l in estimate.lines)
          if (l.circuitId == sockets.id && l.category == EstimateCategory.apparatus)
            l.requirement?.function,
      ];
      expect(functions, lines);
      expect(functions.toSet(), {ApparatusFunction.mcb, ApparatusFunction.rcd});
      expect(devices.map((d) => d.units).toList(), [
        for (final l in estimate.lines)
          if (l.circuitId == sockets.id && l.category == EstimateCategory.apparatus) l.moduleUnits,
      ]);
    });

    test('an item without estimate lines is one device of its width', () {
      const item = BoardItem(kind: BoardItemKind.circuit, id: 'missing', units: 3);
      final ProjectInput input = DemoProjects.oneRoomApartment();
      final ProjectResult result = calculateProject(input);
      final EstimateResult estimate = calculateEstimate(input, result, const EstimateInput());
      final List<BoardDevice> devices = boardItemDevices(item, estimate);
      expect(devices.length, 1);
      expect(devices.single.units, 3);
      expect(devices.single.requirement, isNull);
    });
  });
}
