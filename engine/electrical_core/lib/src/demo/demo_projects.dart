import 'package:electrical_core/src/model/enums.dart';
import 'package:electrical_core/src/model/project_input.dart';
import 'package:norms_data/norms_data.dart';

/// Builds a project from room templates of the reference catalog.
///
/// Room ids are `r1`, `r2`, …; device ids are `r1-d1`, … — stable for tests and demos.
ProjectInput projectFromTemplates({
  required ObjectType objectType,
  required SupplyPhases supplyPhases,
  required List<String> roomTemplateIds,
  double? defaultLengthM,
  double? allowedPowerKw,
  NormsData? norms,
}) {
  final NormsData data = norms ?? NormsData.embedded;
  final rooms = <RoomInput>[];
  final devices = <DeviceInput>[];
  for (var i = 0; i < roomTemplateIds.length; i++) {
    final RoomTemplate template = data.roomTemplates.firstWhere((r) => r.id == roomTemplateIds[i]);
    final roomId = 'r${i + 1}';
    final int sameKindBefore = roomTemplateIds.take(i).where((id) => id == template.id).length;
    rooms.add(
      RoomInput(
        id: roomId,
        name: sameKindBefore == 0 ? template.name : '${template.name} ${sameKindBefore + 1}',
        kind: template.kind,
      ),
    );
    for (var j = 0; j < template.devices.length; j++) {
      final ({int count, String deviceId}) entry = template.devices[j];
      devices.add(
        DeviceInput.fromTemplate(
          data.device(entry.deviceId),
          id: '$roomId-d${j + 1}',
          roomId: roomId,
          quantity: entry.count,
        ),
      );
    }
  }
  return ProjectInput(
    objectType: objectType,
    supplyPhases: supplyPhases,
    supply: SupplyInput(allowedPowerKw: allowedPowerKw),
    cableDefaults: CableDefaults(lengthM: defaultLengthM),
    rooms: rooms,
    devices: devices,
  );
}

/// Demo projects shown on the first launch and used as regression scenarios.
abstract final class DemoProjects() {
  /// One-room apartment, single-phase supply.
  static ProjectInput oneRoomApartment() => projectFromTemplates(
    objectType: ObjectType.apartment,
    supplyPhases: SupplyPhases.single,
    roomTemplateIds: const ['kitchen', 'bathroom', 'living_room', 'hallway', 'balcony'],
    defaultLengthM: 15,
    allowedPowerKw: 10,
  );

  /// Three-room apartment, single-phase supply.
  static ProjectInput threeRoomApartment() => projectFromTemplates(
    objectType: ObjectType.apartment,
    supplyPhases: SupplyPhases.single,
    roomTemplateIds: const [
      'kitchen',
      'bathroom',
      'toilet',
      'living_room',
      'bedroom',
      'kids_room',
      'hallway',
      'balcony',
    ],
    defaultLengthM: 18,
    allowedPowerKw: 15,
  );

  /// Single-family house, three-phase supply.
  static ProjectInput house() => projectFromTemplates(
    objectType: ObjectType.house,
    supplyPhases: SupplyPhases.three,
    roomTemplateIds: const [
      'kitchen',
      'bathroom',
      'toilet',
      'living_room',
      'bedroom',
      'bedroom',
      'kids_room',
      'hallway',
      'boiler_room',
      'sauna',
      'garage',
      'outdoor',
    ],
    defaultLengthM: 25,
    allowedPowerKw: 30,
  );
}
