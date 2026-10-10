import 'dart:convert';
import 'dart:io';

import 'package:electrical_core/electrical_core.dart';
import 'package:norms_data/norms_data.dart';
import 'package:test/test.dart';

/// Invariants checked on every circuit of the fixed vector grid (verification/vectors).
void main() {
  final norms = NormsData.embedded;
  final data = jsonDecode(
    File('../../verification/vectors/circuits.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final inputs = [
    for (final v in data['vectors']! as List<Object?>)
      ProjectInput.fromJson((v! as Map<String, Object?>)['input']! as Map<String, Object?>),
  ];

  test('IB ≤ In ≤ Iz, ΔU ≤ limit, Iк ≥ Ia for every non-failed circuit', () {
    for (final input in inputs) {
      for (final c in calculateProject(input).circuits) {
        if (c.status == CalculationStatus.failed) continue;
        expect(c.designCurrentA, lessThanOrEqualTo(c.protection.breakerA + 1e-9), reason: c.id);
        expect(c.protection.breakerA, lessThanOrEqualTo(c.cable.ampacityA! + 1e-9), reason: c.id);
        if (c.cable.lengthM != null) {
          expect(
            c.cable.voltageDropPercent,
            lessThanOrEqualTo(c.cable.voltageDropLimitPercent + 1e-9),
          );
          expect(
            c.cable.faultCurrentMinA,
            greaterThanOrEqualTo(c.cable.instantaneousTripA! - 1e-9),
          );
        }
      }
    }
  });

  test(
    'the selected section is minimal: one standard step smaller fails with every allowed curve',
    () {
      var checked = 0;
      for (final input in inputs) {
        for (final c in calculateProject(input).circuits) {
          if (c.status == CalculationStatus.failed) continue;
          final sections = norms.constants.standardSections;
          final index = sections.indexOf(c.cable.sectionMm2);
          if (index == 0) continue;
          final smaller = sections[index - 1];
          final curves = c.protection.curve == BreakerCurve.d
              ? const [BreakerCurve.d]
              : const [BreakerCurve.c, BreakerCurve.b];
          for (final curve in curves) {
            final forced = input.copyWith(
              circuitSettings: {c.id: CircuitSettings(sectionMm2: smaller, curve: curve)},
            );
            final again = calculateProject(forced).circuits.firstWhere((x) => x.id == c.id);
            expect(
              again.status,
              CalculationStatus.failed,
              reason: '${c.id} ${c.cable.label} → $smaller $curve',
            );
          }
          checked++;
        }
      }
      expect(checked, greaterThan(100));
    },
  );

  test('voltage drop grows and fault current falls with length', () {
    double? previousVd;
    double? previousIk;
    for (final length in [5.0, 10.0, 20.0, 40.0, 80.0]) {
      final c = calculateProject(
        ProjectInput(
          objectType: ObjectType.apartment,
          supplyPhases: SupplyPhases.single,
          supply: const SupplyInput(externalLoopImpedanceOhm: 0.3),
          rooms: const [RoomInput(id: 'r', name: 'r', kind: RoomKind.standard)],
          devices: const [
            DeviceInput(
              id: 'd',
              roomId: 'r',
              name: 'd',
              kind: 'other',
              powerW: 2000,
              dedicatedLine: DedicatedLine.required,
            ),
          ],
          circuitSettings: {'dev-d': CircuitSettings(lengthM: length, sectionMm2: 2.5)},
        ),
      ).circuits.single;
      if (previousVd != null) {
        expect(c.cable.voltageDropPercent, greaterThan(previousVd));
        expect(c.cable.faultCurrentMinA, lessThan(previousIk!));
      }
      previousVd = c.cable.voltageDropPercent;
      previousIk = c.cable.faultCurrentMinA;
    }
  });
}
