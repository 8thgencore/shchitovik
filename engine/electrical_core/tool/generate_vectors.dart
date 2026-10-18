// Generates reference vectors for the independent oracle: dart run tool/generate_vectors.dart
//
// Writes ../../verification/vectors/{circuits,projects}.json: every vector holds the project
// input and the fields of the result that the Python oracle recomputes. The test
// `vectors_test.dart` fails when the committed vectors differ from the current core, so any
// change of results is visible in review.
import 'dart:convert';
import 'dart:io';

import 'package:electrical_core/electrical_core.dart';
import 'package:norms_data/norms_data.dart';

const _outDir = '../../verification/vectors';

void main() {
  Directory(_outDir).createSync(recursive: true);
  File('$_outDir/circuits.json').writeAsStringSync(_encode(circuitVectors()));
  File('$_outDir/projects.json').writeAsStringSync(_encode(projectVectors()));
  stdout.writeln('Wrote $_outDir/circuits.json and projects.json');
}

String _encode(Object json) => '${const JsonEncoder.withIndent(' ').convert(json)}\n';

/// Deterministic pseudo-random choice (LCG, fixed seed) — the grid must not change between runs.
final class _Choice() {
  int _state = 20261008;

  T pick<T>(List<T> values) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    // High bits: the low bits of an LCG have short periods.
    return values[(_state >> 16) % values.length];
  }
}

/// Single-circuit scenarios over a fixed grid.
Map<String, Object?> circuitVectors() {
  final choice = _Choice();
  final vectors = <Map<String, Object?>>[];
  const List<RoomKind> roomKinds = RoomKind.values;
  const methods = [
    'plaster_direct',
    'conduit_in_wall',
    'conduit_on_surface',
    'clipped_on_wall',
    'under_ceiling',
    'building_void',
    'thermal_insulation',
    'conduit_in_thermal_insulation',
    'perforated_tray',
    'ground_in_duct',
    'ground_direct',
  ];
  // kind, power W, phases, cos φ, inrush, connection, dedicated, quantity
  const List<(String, int, int, double, double, DeviceConnection, DedicatedLine, int)> loads = [
    ('lighting', 60, 1, 0.9, 1.0, DeviceConnection.fixed, DedicatedLine.no, 8),
    ('socket', 200, 1, 0.95, 1.0, DeviceConnection.socket, DedicatedLine.no, 6),
    ('kitchen_appliance', 2000, 1, 1.0, 1.0, DeviceConnection.socket, DedicatedLine.no, 1),
    ('washing_machine', 2200, 1, 0.9, 3.0, DeviceConnection.socket, DedicatedLine.recommended, 1),
    ('water_heater', 3500, 1, 1.0, 1.0, DeviceConnection.fixed, DedicatedLine.required, 1),
    ('oven', 3500, 1, 1.0, 1.0, DeviceConnection.fixed, DedicatedLine.required, 1),
    ('cooktop', 7200, 1, 0.98, 1.0, DeviceConnection.fixed, DedicatedLine.required, 1),
    ('electric_stove', 8500, 1, 1.0, 1.0, DeviceConnection.fixed, DedicatedLine.required, 1),
    ('pump', 1100, 1, 0.8, 6.0, DeviceConnection.fixed, DedicatedLine.required, 1),
    ('motor', 1500, 1, 0.8, 10.0, DeviceConnection.fixed, DedicatedLine.required, 1),
    ('floor_heating', 1500, 1, 1.0, 1.0, DeviceConnection.fixed, DedicatedLine.recommended, 1),
    ('ev_charger', 7400, 1, 0.99, 1.0, DeviceConnection.fixed, DedicatedLine.required, 1),
    ('heating_boiler', 12000, 3, 1.0, 1.0, DeviceConnection.fixed, DedicatedLine.required, 1),
    ('motor', 3000, 3, 0.8, 6.0, DeviceConnection.fixed, DedicatedLine.required, 1),
    ('sauna_heater', 9000, 3, 1.0, 1.0, DeviceConnection.fixed, DedicatedLine.required, 1),
    ('ev_charger', 22000, 3, 0.99, 1.0, DeviceConnection.fixed, DedicatedLine.required, 1),
  ];

  for (var i = 0; i < 400; i++) {
    final (String, int, int, double, double, DeviceConnection, DedicatedLine, int) load = choice
        .pick(loads);
    final (kind, power, phases, cos, inrush, connection, dedicated, quantity) = load;
    final ConductorMaterial material = choice.pick(ConductorMaterial.values);
    final RoomKind roomKind = choice.pick(roomKinds);
    final input = ProjectInput(
      objectType: choice.pick(ObjectType.values),
      supplyPhases: phases == 3 ? SupplyPhases.three : choice.pick(SupplyPhases.values),
      nominalVoltageId: choice.pick(const ['u220_380', 'u220_380', 'u230_400']),
      rcdStrategy: choice.pick(RcdStrategy.values),
      supply: SupplyInput(
        externalLoopImpedanceOhm: choice.pick(const [null, 0.2, 0.5, 0.8]),
        allowedPowerKw: choice.pick(const [null, 10.0, 15.0, 30.0]),
      ),
      cableDefaults: CableDefaults(
        material: material,
        insulation: choice.pick(Insulation.values),
        installationMethodId: choice.pick(methods),
        ambientTemperatureC: choice.pick(const [10.0, 25.0, 30.0, 35.0, 40.0]),
        groupedCircuits: choice.pick(const [1, 1, 2, 4, 6]),
        soilResistivityKMPerW: choice.pick(const [1.0, 2.5]),
        lengthM: choice.pick(const [null, 5.0, 15.0, 30.0, 60.0, 100.0]),
      ),
      rooms: [RoomInput(id: 'r1', name: 'Помещение', kind: roomKind)],
      devices: [
        DeviceInput(
          id: 'd1',
          roomId: 'r1',
          name: kind,
          kind: kind,
          powerW: power,
          quantity: choice.pick([quantity, (quantity / 2).ceil(), quantity]),
          phases: phases,
          cosPhi: cos,
          usageFactor: choice.pick(const [0.3, 0.7, 1.0]),
          inrushMultiple: inrush,
          connection: connection,
          dedicatedLine: dedicated,
        ),
      ],
    );
    vectors.add({'id': 'c${i + 1}', 'input': input.toJson(), 'expected': expectedOf(input)});
  }
  return {
    'description': 'Single-circuit vectors over a fixed pseudo-random grid (seed 20261008).',
    'algorithm_version': algorithmVersion,
    'vectors': vectors,
  };
}

/// Demo projects as multi-circuit vectors.
Map<String, Object?> projectVectors() => {
  'description': 'Demo projects.',
  'algorithm_version': algorithmVersion,
  'vectors': [
    for (final (id, input) in [
      ('one_room_apartment', DemoProjects.oneRoomApartment()),
      ('three_room_apartment', DemoProjects.threeRoomApartment()),
      ('house', DemoProjects.house()),
    ])
      {'id': id, 'input': input.toJson(), 'expected': expectedOf(input)},
  ],
};

/// Fields of the result that the oracle recomputes.
Map<String, Object?> expectedOf(ProjectInput input) {
  final ProjectResult r = calculateProject(input);
  return {
    'issues': [for (final i in r.issues) i.code],
    'incomer': {
      'installed_power_w': r.incomer.installedPowerW,
      'demand_by_devices_w': r.incomer.demandByDevicesW,
      'demand_normative_w': r.incomer.demandNormativeW,
      'cos_phi': r.incomer.cosPhi,
      if (input.supplyPhases == SupplyPhases.single) 'design_current_a': r.incomer.designCurrentA,
      if (input.supplyPhases == SupplyPhases.single) 'breaker_a': r.incomer.breakerA,
    },
    'fire_rcd': r.fireRcd != null,
    'circuits': [
      for (final c in r.circuits)
        {
          'id': c.id,
          'purpose': c.purpose.name,
          'device_ids': c.deviceIds,
          'phases': c.phases,
          'design_current_a': c.designCurrentA,
          'starting_current_a': c.startingCurrentA,
          'cos_phi': c.cosPhi,
          'breaker_a': c.protection.breakerA,
          'curve': c.protection.curve.name,
          'protection': c.protection.device.name,
          'section_mm2': c.cable.sectionMm2,
          'pe_section_mm2': c.cable.peSectionMm2,
          'ampacity_a': c.cable.ampacityA,
          'voltage_drop_percent': c.cable.voltageDropPercent,
          'voltage_drop_limit_percent': c.cable.voltageDropLimitPercent,
          'loop_impedance_ohm': c.cable.loopImpedanceOhm,
          'fault_current_min_a': c.cable.faultCurrentMinA,
          'status': c.status.name,
          'checks': {for (final k in c.allChecks) k.code.name: k.status.name},
        },
    ],
  };
}
