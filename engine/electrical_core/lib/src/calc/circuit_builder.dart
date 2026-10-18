import 'package:electrical_core/src/calc/currents.dart';
import 'package:electrical_core/src/calc/tolerance.dart';
import 'package:electrical_core/src/model/enums.dart';
import 'package:electrical_core/src/model/project_input.dart';
import 'package:norms_data/norms_data.dart';

/// Circuit before protection and cable selection.
final class CircuitDraft({
  /// Stable id: `dev-<deviceId>` for dedicated circuits, `<group key>-<n>` for shared ones.
  required final String id,

  /// Purpose.
  required final CircuitPurpose purpose,

  /// Name for the user.
  required final String name,

  /// Devices.
  required final List<DeviceInput> devices,

  /// Rooms of the devices, in input order.
  required final List<RoomInput> rooms,

  /// Ordering key for numbering.
  required final String sortKey,
}) {
  /// 3 if the circuit feeds a three-phase device, otherwise 1.
  int get phases => devices.any((d) => d.phases == 3) ? 3 : 1;
}

/// Limits of shared circuits by design current, A.
///
/// Lighting circuits are protected by 10 A breakers, socket circuits by 16 A breakers
/// (socket-outlets 10(16) A, СП 256 п. 15.28), so the shared load must fit these ratings.
const Map<CircuitPurpose, double> sharedLimitA = {
  CircuitPurpose.lighting: 10.0,
  CircuitPurpose.power: 16.0,
};

/// Groups devices into circuits.
///
/// Rules:
/// 1. A device gets its own circuit when the catalog requires or recommends it, when it is
///    three-phase, or when its design current exceeds the shared circuit limit.
/// 2. Lighting (and small fixed fans) is pooled across rooms by zone: dry rooms, wet rooms (bathroom kind:
///    ГОСТ Р 50571.7.701 requires RCD for all circuits of the location) and outdoor.
/// 3. Socket-outlets and small fixed appliances form power circuits per room
///    (СП 256 п. 10.2 recommends separate lines for room sockets, kitchen and lighting).
/// 4. Shared circuits are packed first-fit-decreasing by design current (Kс = 1) within
///    [sharedLimitA]; ties are broken by device id for determinism.
List<CircuitDraft> buildCircuits({
  required List<DeviceInput> devices,
  required List<RoomInput> rooms,
  required double phaseVoltageV,
  required double lineVoltageV,
}) {
  final Map<String, RoomInput> roomById = {for (final r in rooms) r.id: r};
  final Map<String, int> roomIndex = {for (var i = 0; i < rooms.length; i++) rooms[i].id: i};
  double current(DeviceInput d) =>
      deviceCurrent(d, phaseVoltageV: phaseVoltageV, lineVoltageV: lineVoltageV).magnitudeA;

  final drafts = <CircuitDraft>[];
  final shared = <String, List<DeviceInput>>{};
  final sharedMeta = <String, ({CircuitPurpose purpose, String title, String sortKey})>{};

  for (final device in devices) {
    final RoomInput room = roomById[device.roomId]!;
    final CircuitPurpose purpose = _isLightingCircuitLoad(device)
        ? CircuitPurpose.lighting
        : CircuitPurpose.power;
    final bool dedicated =
        device.dedicatedLine != DedicatedLine.no ||
        device.phases == 3 ||
        current(device) > sharedLimitA[purpose]! + epsilon;
    final String roomOrder = roomIndex[room.id]!.toString().padLeft(4, '0');
    if (dedicated) {
      drafts.add(
        CircuitDraft(
          id: 'dev-${device.id}',
          purpose: CircuitPurpose.dedicated,
          name: '${device.name} (${room.name})',
          devices: [device],
          rooms: [room],
          sortKey: '3-$roomOrder-${devices.indexOf(device).toString().padLeft(4, '0')}',
        ),
      );
      continue;
    }
    final String key;
    final String title;
    final String sortKey;
    if (purpose == CircuitPurpose.lighting) {
      final (String, String) zone = switch (room.kind) {
        RoomKind.bathroom => ('wet', 'Освещение влажных помещений'),
        RoomKind.outdoor => ('outdoor', 'Наружное освещение'),
        _ => ('dry', 'Освещение'),
      };
      key = 'light-${zone.$1}';
      title = zone.$2;
      sortKey = '1-${zone.$1 == 'dry' ? 0 : (zone.$1 == 'wet' ? 1 : 2)}';
    } else {
      key = 'power-${room.id}';
      final bool roomHasSockets = devices.any(
        (d) =>
            d.roomId == room.id &&
            !_isLightingCircuitLoad(d) &&
            d.connection == DeviceConnection.socket,
      );
      title = '${roomHasSockets ? 'Розетки' : 'Приборы'}: ${room.name}';
      sortKey = '2-$roomOrder';
    }
    shared.putIfAbsent(key, () => []).add(device);
    sharedMeta[key] = (purpose: purpose, title: title, sortKey: sortKey);
  }

  for (final MapEntry<String, List<DeviceInput>> entry in shared.entries) {
    final ({CircuitPurpose purpose, String sortKey, String title}) meta = sharedMeta[entry.key]!;
    final double limit = sharedLimitA[meta.purpose]!;
    final List<DeviceInput> items = [...entry.value]
      ..sort((a, b) {
        final int byCurrent = current(b).compareTo(current(a));
        return byCurrent != 0 ? byCurrent : a.id.compareTo(b.id);
      });
    final bins = <List<DeviceInput>>[];
    final loads = <double>[];
    for (final item in items) {
      final double i = current(item);
      final int index = loads.indexWhere((load) => lessOrEqual(load + i, limit));
      if (index >= 0) {
        bins[index].add(item);
        loads[index] += i;
      } else {
        bins.add([item]);
        loads.add(i);
      }
    }
    for (var n = 0; n < bins.length; n++) {
      final List<DeviceInput> binDevices = [...bins[n]]
        ..sort((a, b) => devices.indexOf(a).compareTo(devices.indexOf(b)));
      final binRooms = <RoomInput>[];
      for (final d in binDevices) {
        final RoomInput r = roomById[d.roomId]!;
        if (!binRooms.contains(r)) {
          binRooms.add(r);
        }
      }
      binRooms.sort((a, b) => roomIndex[a.id]!.compareTo(roomIndex[b.id]!));
      drafts.add(
        CircuitDraft(
          id: '${entry.key}-${n + 1}',
          purpose: meta.purpose,
          name: bins.length > 1 ? '${meta.title} — ${n + 1}' : meta.title,
          devices: binDevices,
          rooms: binRooms,
          sortKey: '${meta.sortKey}-${(n + 1).toString().padLeft(3, '0')}',
        ),
      );
    }
  }

  drafts.sort((a, b) => a.sortKey.compareTo(b.sortKey));
  return drafts;
}

/// Small fixed fans are switched together with the light and share its circuit.
bool _isLightingCircuitLoad(DeviceInput d) =>
    d.kind == 'lighting' ||
    (d.kind == 'ventilation' && d.connection == DeviceConnection.fixed && d.powerW <= 100);
