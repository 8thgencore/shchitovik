import 'package:electrical_core/electrical_core.dart';
import 'package:norms_data/norms_data.dart';

/// Room used by single-device scenarios.
const standardRoom = RoomInput(id: 'room', name: 'Комната', kind: RoomKind.standard);

/// Project with one room and the given devices.
ProjectInput singleRoomProject(
  List<DeviceInput> devices, {
  RoomInput room = standardRoom,
  SupplyPhases supply = SupplyPhases.single,
  double? lengthM,
  double? externalLoopImpedanceOhm,
  String installationMethodId = 'plaster_direct',
  Map<String, CircuitSettings> circuitSettings = const {},
  RcdStrategy rcdStrategy = RcdStrategy.rcboPerCircuit,
  ObjectType objectType = ObjectType.apartment,
  double? allowedPowerKw,
}) => ProjectInput(
  objectType: objectType,
  supplyPhases: supply,
  rcdStrategy: rcdStrategy,
  supply: SupplyInput(
    externalLoopImpedanceOhm: externalLoopImpedanceOhm,
    allowedPowerKw: allowedPowerKw,
  ),
  cableDefaults: CableDefaults(lengthM: lengthM, installationMethodId: installationMethodId),
  rooms: [room],
  devices: devices,
  circuitSettings: circuitSettings,
);

/// Device in [standardRoom].
DeviceInput device(
  String id, {
  required int powerW,
  String kind = 'other',
  int quantity = 1,
  int phases = 1,
  double cosPhi = 1,
  double usageFactor = 1,
  double inrushMultiple = 1,
  DeviceConnection connection = DeviceConnection.fixed,
  DedicatedLine dedicatedLine = DedicatedLine.required,
  String roomId = 'room',
}) => DeviceInput(
  id: id,
  roomId: roomId,
  name: id,
  kind: kind,
  powerW: powerW,
  quantity: quantity,
  phases: phases,
  cosPhi: cosPhi,
  usageFactor: usageFactor,
  inrushMultiple: inrushMultiple,
  connection: connection,
  dedicatedLine: dedicatedLine,
);

/// Check of [circuit] by code.
Check checkOf(CircuitResult circuit, CheckCode code) =>
    circuit.allChecks.firstWhere((c) => c.code == code);
