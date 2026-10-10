import 'package:norms_data/src/json_reading.dart';

/// How a receiver is connected.
enum DeviceConnection { socket, fixed }

/// Whether a receiver needs its own circuit.
enum DedicatedLine { required, recommended, no }

/// Kind of room; drives special-location rules (RCD, IP).
enum RoomKind { standard, kitchen, bathroom, outdoor, garage }

/// Typical electrical receiver from the reference catalog.
final class DeviceTemplate {
  const DeviceTemplate({
    required this.id,
    required this.name,
    required this.kind,
    required this.powerW,
    required this.phases,
    required this.cosPhi,
    required this.usageFactor,
    required this.inrushMultiple,
    required this.connection,
    required this.dedicatedLine,
  });

  /// Parses one entry of the `device_catalog` dataset.
  factory DeviceTemplate.fromJson(JsonMap json) => DeviceTemplate(
    id: json['id']! as String,
    name: json['name']! as String,
    kind: json['kind']! as String,
    powerW: json['power_w']! as int,
    phases: json['phases']! as int,
    cosPhi: toDouble(json['cos_phi']),
    usageFactor: toDouble(json['usage_factor']),
    inrushMultiple: toDouble(json['inrush_multiple']),
    connection: DeviceConnection.values.byName(json['connection']! as String),
    dedicatedLine: DedicatedLine.values.byName(json['dedicated_line']! as String),
  );

  /// Stable identifier.
  final String id;

  /// Russian name.
  final String name;

  /// Kind, e.g. `lighting`, `water_heater`.
  final String kind;

  /// Rated active power, Вт.
  final int powerW;

  /// 1 or 3.
  final int phases;

  /// Power factor.
  final double cosPhi;

  /// Usage factor for the «by devices» input estimate.
  final double usageFactor;

  /// Starting current multiple.
  final double inrushMultiple;

  /// Socket or fixed connection.
  final DeviceConnection connection;

  /// Dedicated circuit policy.
  final DedicatedLine dedicatedLine;
}

/// Room template with a typical set of receivers.
final class RoomTemplate {
  const RoomTemplate({
    required this.id,
    required this.name,
    required this.kind,
    required this.devices,
  });

  /// Parses one entry of the `room_templates` dataset.
  factory RoomTemplate.fromJson(JsonMap json) => RoomTemplate(
    id: json['id']! as String,
    name: json['name']! as String,
    kind: RoomKind.values.byName(json['room_kind']! as String),
    devices: [
      for (final d in objects(json['devices']))
        (deviceId: d['device_id']! as String, count: d['count']! as int),
    ],
  );

  /// Stable identifier.
  final String id;

  /// Russian name.
  final String name;

  /// Room kind.
  final RoomKind kind;

  /// Receivers with counts.
  final List<({String deviceId, int count})> devices;
}
