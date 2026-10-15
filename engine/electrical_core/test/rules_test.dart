import 'package:electrical_core/electrical_core.dart';
import 'package:norms_data/norms_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('grouping', () {
    test('lighting is pooled across rooms, sockets are per room', () {
      const kitchen = RoomInput(id: 'k', name: 'Кухня', kind: RoomKind.kitchen);
      const bedroom = RoomInput(id: 'b', name: 'Спальня', kind: RoomKind.standard);
      final input = ProjectInput(
        objectType: ObjectType.apartment,
        supplyPhases: SupplyPhases.single,
        rooms: const [kitchen, bedroom],
        devices: [
          device('l1', powerW: 60, kind: 'lighting', dedicatedLine: DedicatedLine.no, roomId: 'k'),
          device('l2', powerW: 60, kind: 'lighting', dedicatedLine: DedicatedLine.no, roomId: 'b'),
          device(
            's1',
            powerW: 200,
            kind: 'socket',
            connection: DeviceConnection.socket,
            dedicatedLine: DedicatedLine.no,
            roomId: 'k',
          ),
          device(
            's2',
            powerW: 200,
            kind: 'socket',
            connection: DeviceConnection.socket,
            dedicatedLine: DedicatedLine.no,
            roomId: 'b',
          ),
        ],
      );
      final List<CircuitResult> circuits = calculateProject(input).circuits;
      expect(circuits.map((c) => c.id), ['light-dry-1', 'power-k-1', 'power-b-1']);
      expect(circuits.first.deviceIds, ['l1', 'l2']);
      expect(circuits.map((c) => c.number), [1, 2, 3]);
    });

    test('shared socket circuit is split when IB exceeds 16 A (first-fit decreasing)', () {
      final List<DeviceInput> devices = [
        for (var i = 1; i <= 5; i++)
          device(
            'a$i',
            powerW: 1000,
            kind: 'kitchen_appliance',
            connection: DeviceConnection.socket,
            dedicatedLine: DedicatedLine.no,
          ),
      ];
      final List<CircuitResult> circuits = calculateProject(singleRoomProject(devices)).circuits;
      // 5 × 4,545 A = 22,7 A > 16 A → 3 + 2 devices.
      expect(circuits.map((c) => c.deviceIds.length), [3, 2]);
      expect(circuits.every((c) => c.designCurrentA <= 16), isTrue);
    });

    test('device above the shared limit gets its own circuit', () {
      final List<CircuitResult> circuits = calculateProject(
        singleRoomProject([
          device(
            'big',
            powerW: 4000,
            dedicatedLine: DedicatedLine.no,
          ),
        ]),
      ).circuits;
      expect(circuits.single.purpose, CircuitPurpose.dedicated);
      expect(circuits.single.id, 'dev-big');
    });

    test('three-phase device on a single-phase supply is rejected', () {
      final ProjectResult result = calculateProject(
        singleRoomProject([device('m', powerW: 3000, phases: 3)]),
      );
      expect(result.circuits, isEmpty);
      expect(result.issues.single.code, 'three_phase_device_on_single_phase_supply');
      expect(result.status, CalculationStatus.failed);
    });
  });

  group('RCD rules', () {
    test('bathroom lighting goes to the wet zone with an RCD; dry lighting has none', () {
      const bath = RoomInput(id: 'bath', name: 'Ванная', kind: RoomKind.bathroom);
      final ProjectResult result = calculateProject(
        ProjectInput(
          objectType: ObjectType.apartment,
          supplyPhases: SupplyPhases.single,
          rooms: const [standardRoom, bath],
          devices: [
            device('l1', powerW: 40, kind: 'lighting', dedicatedLine: DedicatedLine.no),
            device(
              'l2',
              powerW: 20,
              kind: 'lighting',
              dedicatedLine: DedicatedLine.no,
              roomId: 'bath',
            ),
          ],
        ),
      );
      final CircuitResult dry = result.circuits.firstWhere((c) => c.id == 'light-dry-1');
      final CircuitResult wet = result.circuits.firstWhere((c) => c.id == 'light-wet-1');
      expect(dry.protection.device, ProtectionDevice.mcb);
      expect(wet.protection.device, ProtectionDevice.rcbo);
      expect(wet.protection.rcd!.reasons.single, contains('701.411.3.3'));
    });

    test('heating cable requires an RCD', () {
      final CircuitResult c = calculateProject(
        singleRoomProject([device('floor', powerW: 1500, kind: 'floor_heating')]),
      ).circuits.single;
      expect(c.protection.rcd!.reasons.single, contains('50571.7.753'));
    });

    test('per-circuit RCD strategy: MCB + RCD rated not below In', () {
      final CircuitResult c = calculateProject(
        singleRoomProject(
          [
            device(
              'wm',
              powerW: 2200,
              kind: 'washing_machine',
              connection: DeviceConnection.socket,
            ),
          ],
          rcdStrategy: RcdStrategy.rcdPerCircuit,
        ),
      ).circuits.single;
      expect(c.protection.device, ProtectionDevice.mcbAndRcd);
      expect(c.protection.rcd!.ratedA, greaterThanOrEqualTo(c.protection.breakerA));
    });

    test('grouped strategy: shared RCDs respect leakage 1/3 IΔn and rated ≥ Σ IB', () {
      final ProjectInput input = DemoProjects.threeRoomApartment().copyWith(
        rcdStrategy: RcdStrategy.groupedRcd,
      );
      final ProjectResult result = calculateProject(input);
      final Iterable<CircuitResult> grouped = result.circuits.where(
        (c) => c.protection.device == ProtectionDevice.mcbUnderGroupRcd,
      );
      expect(grouped, isNotEmpty);
      for (final c in grouped) {
        expect(c.protection.rcd!.groupId, isNotNull);
      }
      for (final SharedRcdResult rcd in result.sharedRcds) {
        expect(rcd.leakageMa, lessThanOrEqualTo(10 + 1e-9));
        final double sum = result.circuits
            .where((c) => rcd.circuitIds.contains(c.id))
            .fold<double>(0, (s, c) => s + c.designCurrentA);
        expect(rcd.ratedA, greaterThanOrEqualTo(sum));
      }
      expect(result.sharedRcds.expand((r) => r.circuitIds).toSet().length, grouped.length);
    });

    test('fire RCD 300 mA S at the input of a house only', () {
      expect(calculateProject(DemoProjects.house()).fireRcd!.residualMa, 300);
      expect(calculateProject(DemoProjects.house()).fireRcd!.selective, isTrue);
      expect(calculateProject(DemoProjects.oneRoomApartment()).fireRcd, isNull);
    });
  });

  group('statuses', () {
    test('no length → preliminary, voltage drop and fault loop not evaluated', () {
      final CircuitResult c = calculateProject(singleRoomProject([device('h', powerW: 2000)]))
          .circuits
          .single;
      expect(c.status, CalculationStatus.preliminary);
      expect(checkOf(c, CheckCode.voltageDrop).status, CheckStatus.notEvaluated);
    });

    test('assumed Zвнеш → requires review and an assumption in the report', () {
      final ProjectResult result = calculateProject(
        singleRoomProject([device('h', powerW: 2000)], lengthM: 10),
      );
      expect(result.circuits.single.status, CalculationStatus.requiresReview);
      expect(result.assumptions.map((a) => a.code), contains('assumed_external_loop_impedance'));
    });

    test('manual 1,5 mm² on a socket circuit fails the normative minimum', () {
      final CircuitResult c = calculateProject(
        singleRoomProject(
          [
            device(
              'wm',
              powerW: 2200,
              kind: 'washing_machine',
              connection: DeviceConnection.socket,
            ),
          ],
          lengthM: 10,
          externalLoopImpedanceOhm: 0.3,
          circuitSettings: const {'dev-wm': CircuitSettings(sectionMm2: 1.5)},
        ),
      ).circuits.single;
      expect(c.cable.sectionSource, ValueSource.manual);
      expect(checkOf(c, CheckCode.minimumSection).status, CheckStatus.failed);
      expect(c.status, CalculationStatus.failed);
    });

    test('manual breaker above the cable ampacity fails In ≤ Iz', () {
      final CircuitResult c = calculateProject(
        singleRoomProject(
          [device('h', powerW: 2000)],
          lengthM: 10,
          externalLoopImpedanceOhm: 0.3,
          circuitSettings: const {'dev-h': CircuitSettings(sectionMm2: 1.5, breakerA: 25)},
        ),
      ).circuits.single;
      expect(checkOf(c, CheckCode.breakerVsAmpacity).status, CheckStatus.failed);
      expect(c.protection.breakerSource, ValueSource.manual);
    });

    test('manual section without tabulated data fails instead of throwing (Al 1,5 mm²)', () {
      final CircuitResult c = calculateProject(
        ProjectInput(
          objectType: ObjectType.apartment,
          supplyPhases: SupplyPhases.single,
          cableDefaults: const CableDefaults(material: ConductorMaterial.aluminium, lengthM: 10),
          rooms: const [standardRoom],
          devices: [device('h', powerW: 1000)],
          circuitSettings: const {'dev-h': CircuitSettings(sectionMm2: 1.5)},
        ),
      ).circuits.single;
      expect(checkOf(c, CheckCode.datasetCoverage).status, CheckStatus.failed);
      expect(checkOf(c, CheckCode.faultDisconnection).status, CheckStatus.notEvaluated);
      expect(c.status, CalculationStatus.failed);
    });

    test('socket circuit protected above 16 A fails', () {
      final CircuitResult c = calculateProject(
        singleRoomProject(
          [
            device(
              'k',
              powerW: 3000,
              kind: 'kitchen_appliance',
              connection: DeviceConnection.socket,
            ),
          ],
          lengthM: 5,
        ),
      ).circuits.single;
      expect(c.protection.breakerA, 16);
      expect(checkOf(c, CheckCode.socketRating).status, CheckStatus.passed);
      final CircuitResult big = calculateProject(
        singleRoomProject(
          [
            device(
              'k',
              powerW: 4000,
              kind: 'kitchen_appliance',
              connection: DeviceConnection.socket,
            ),
          ],
          lengthM: 5,
        ),
      ).circuits.single;
      expect(checkOf(big, CheckCode.socketRating).status, CheckStatus.failed);
    });
  });

  group('input demand, СП 256', () {
    test('declared power × Kс (табл. 7.2) with interpolation', () {
      final ProjectResult result = calculateProject(
        singleRoomProject([device('h', powerW: 20000)], allowedPowerKw: 15),
      );
      // Kс(15 кВт) = 0,8 − (0,8 − 0,65) · (15 − 14) / (20 − 14) = 0,775.
      expect(result.incomer.demandNormativeW, closeTo(15000 * 0.775, 1e-6));
      expect(
        result.assumptions.map((a) => a.code),
        isNot(contains('declared_power_from_installed')),
      );
    });

    test('not below the specific load of табл. 7.1 (gas stove: 4,5 кВт)', () {
      final ProjectResult result = calculateProject(
        singleRoomProject([device('h', powerW: 1000)], allowedPowerKw: 3),
      );
      expect(result.incomer.demandNormativeW, 4500);
    });

    test('without allowed power the installed power is used and flagged', () {
      final ProjectResult result = calculateProject(
        singleRoomProject([device('h', powerW: 10000)]),
      );
      expect(result.incomer.demandNormativeW, closeTo(10000 * 0.8, 1e-6));
      expect(result.assumptions.map((a) => a.code), contains('declared_power_from_installed'));
    });

    test('existing incomer breaker below the design current fails', () {
      final ProjectInput input = singleRoomProject([device('h', powerW: 9000)], allowedPowerKw: 15);
      final ProjectResult result = calculateProject(
        ProjectInput(
          objectType: input.objectType,
          supplyPhases: input.supplyPhases,
          supply: const SupplyInput(allowedPowerKw: 15, incomerBreakerA: 32),
          rooms: input.rooms,
          devices: input.devices,
        ),
      );
      expect(
        result.incomer.checks.firstWhere((c) => c.code == CheckCode.loadVsBreaker).status,
        CheckStatus.failed,
      );
      expect(result.incomer.breakerSource, ValueSource.manual);
    });

    test('commercial office uses СП 256 7.2 (lighting × Kс.о + power × Kс)', () {
      final ProjectResult result = calculateProject(
        singleRoomProject(
          [
            device(
              'light',
              powerW: 40,
              quantity: 10,
              kind: 'lighting',
              dedicatedLine: DedicatedLine.no,
            ),
            device(
              'pc',
              powerW: 400,
              quantity: 4,
              kind: 'electronics',
              connection: DeviceConnection.socket,
              dedicatedLine: DedicatedLine.no,
            ),
          ],
          objectType: ObjectType.commercial,
        ),
      );
      expect(result.incomer.normativeMethod, contains('табл. 7.6'));
      expect(result.incomer.demandNormativeW, lessThan(result.incomer.installedPowerW));
    });
  });
}
