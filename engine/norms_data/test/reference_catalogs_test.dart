import 'package:norms_data/norms_data.dart';
import 'package:test/test.dart';

void main() {
  final NormsData norms = NormsData.embedded;

  test('device ids are unique and parameters are in range', () {
    final ids = <String>{};
    for (final DeviceTemplate d in norms.devices) {
      expect(ids.add(d.id), isTrue, reason: 'duplicate ${d.id}');
      expect(d.powerW, greaterThan(0), reason: d.id);
      expect(d.phases, anyOf(1, 3), reason: d.id);
      expect(d.cosPhi, inInclusiveRange(0.1, 1.0), reason: d.id);
      expect(d.usageFactor, inInclusiveRange(0.0, 1.0), reason: d.id);
      expect(d.inrushMultiple, greaterThanOrEqualTo(1), reason: d.id);
    }
  });

  test('room templates reference existing devices', () {
    final Set<String> ids = norms.devices.map((d) => d.id).toSet();
    for (final RoomTemplate room in norms.roomTemplates) {
      for (final ({int count, String deviceId}) d in room.devices) {
        expect(ids, contains(d.deviceId), reason: room.id);
        expect(d.count, greaterThan(0), reason: room.id);
      }
    }
  });

  test('every dataset version is recorded', () {
    expect(
      norms.datasetVersions.keys,
      containsAll(<String>['ampacity', 'sp256_residential_loads']),
    );
  });
}
