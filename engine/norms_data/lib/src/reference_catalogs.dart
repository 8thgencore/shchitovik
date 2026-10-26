import 'package:norms_data/src/json_reading.dart';

/// How a receiver is connected.
enum DeviceConnection() {
  socket,
  fixed,
}

/// Whether a receiver needs its own circuit.
enum DedicatedLine() {
  required,
  recommended,
  no,
}

/// Kind of room; drives special-location rules (RCD, IP).
enum RoomKind() {
  standard,
  kitchen,
  bathroom,
  outdoor,
  garage,
}

/// Typical electrical receiver from the reference catalog.
final class const DeviceTemplate({
  /// Stable identifier.
  required final String id,

  /// Russian name.
  required final String name,

  /// Kind, e.g. `lighting`, `water_heater`.
  required final String kind,

  /// Rated active power, Вт.
  required final int powerW,

  /// 1 or 3.
  required final int phases,

  /// Power factor.
  required final double cosPhi,

  /// Usage factor for the «by devices» input estimate.
  required final double usageFactor,

  /// Starting current multiple.
  required final double inrushMultiple,

  /// Socket or fixed connection.
  required final DeviceConnection connection,

  /// Dedicated circuit policy.
  required final DedicatedLine dedicatedLine,

  /// Whether the receiver stays powered when the load switch is off (refrigerators, leak
  /// protection).
  final bool alwaysOn = false,
}) {
  /// Parses one entry of the `device_catalog` dataset.
  factory fromJson(JsonMap json) => DeviceTemplate(
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
    alwaysOn: json['always_on'] as bool? ?? false,
  );
}

/// Room template with a typical set of receivers.
final class const RoomTemplate({
  /// Stable identifier.
  required final String id,

  /// Russian name.
  required final String name,

  /// Room kind.
  required final RoomKind kind,

  /// Receivers with counts.
  required final List<({String deviceId, int count})> devices,
}) {
  /// Parses one entry of the `room_templates` dataset.
  factory fromJson(JsonMap json) => RoomTemplate(
    id: json['id']! as String,
    name: json['name']! as String,
    kind: RoomKind.values.byName(json['room_kind']! as String),
    devices: [
      for (final d in objects(json['devices']))
        (deviceId: d['device_id']! as String, count: d['count']! as int),
    ],
  );
}
