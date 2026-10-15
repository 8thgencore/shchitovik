import 'dart:convert';

import 'package:electrical_core/electrical_core.dart';
import 'package:test/test.dart';

void main() {
  final Map<String, ProjectInput> demos = {
    'one room apartment': DemoProjects.oneRoomApartment(),
    'three room apartment': DemoProjects.threeRoomApartment(),
    'house': DemoProjects.house(),
  };

  for (final MapEntry(key: name, value: input) in demos.entries) {
    group(name, () {
      final ProjectResult result = calculateProject(input);

      test('JSON round trip of the input is lossless', () {
        final String json = jsonEncode(input.toJson());
        expect(
          jsonEncode(ProjectInput.fromJson(jsonDecode(json) as Map<String, Object?>).toJson()),
          json,
        );
      });

      test('no errors and no failed circuits', () {
        expect(result.issues.where((i) => i.severity == IssueSeverity.error), isEmpty);
        expect(
          result.circuits.where((c) => c.status == CalculationStatus.failed).map((c) => c.name),
          isEmpty,
        );
      });

      test('every device is in exactly one circuit', () {
        final List<String> ids = result.circuits.expand((c) => c.deviceIds).toList();
        expect(ids.toSet().length, ids.length);
        expect(ids.toSet(), input.devices.map((d) => d.id).toSet());
      });

      test('invariants: IB ≤ In ≤ Iz, section ≥ minimum, ΔU within limit', () {
        for (final CircuitResult c in result.circuits) {
          expect(c.designCurrentA, lessThanOrEqualTo(c.protection.breakerA + 1e-9), reason: c.name);
          expect(
            c.protection.breakerA,
            lessThanOrEqualTo(c.cable.ampacityA! + 1e-9),
            reason: c.name,
          );
          expect(
            c.cable.voltageDropPercent,
            lessThanOrEqualTo(c.cable.voltageDropLimitPercent + 1e-9),
            reason: c.name,
          );
          expect(
            c.cable.faultCurrentMinA,
            greaterThanOrEqualTo(c.cable.instantaneousTripA! - 1e-9),
            reason: c.name,
          );
        }
      });

      test('circuits that need an RCD have one (default strategy: RCBO)', () {
        for (final CircuitResult c in result.circuits) {
          final needs = c.protection.rcd != null;
          expect(
            c.protection.device,
            needs ? ProtectionDevice.rcbo : ProtectionDevice.mcb,
            reason: c.name,
          );
        }
      });

      test('result is deterministic and serializable', () {
        expect(jsonEncode(calculateProject(input).toJson()), jsonEncode(result.toJson()));
      });
    });
  }

  test('algorithm version is semantic', () {
    expect(algorithmVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
  });
}
