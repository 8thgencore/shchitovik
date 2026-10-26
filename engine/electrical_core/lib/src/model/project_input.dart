import 'package:electrical_core/src/model/enums.dart';
import 'package:electrical_core/src/model/json.dart';
import 'package:meta/meta.dart';
import 'package:norms_data/norms_data.dart';

/// Marker for "argument not passed" in `copyWith` methods with nullable fields.
const Object unset = _Unset();

final class const _Unset();

/// Everything the user entered about a project; the only persisted state besides selections.
///
/// Calculation results are derived from it by `calculateProject`.
@immutable
final class const ProjectInput({
  /// Object type.
  required final ObjectType objectType,

  /// Single- or three-phase supply.
  required final SupplyPhases supplyPhases,

  /// Nominal voltage option id (`u220_380` or `u230_400`).
  final String nominalVoltageId = defaultNominalVoltageId,

  /// Fuel of the kitchen stove; `null` – derived from the devices (electric if any stove/cooktop).
  final CookingFuel? cookingFuel,

  /// How RCDs are arranged.
  final RcdStrategy rcdStrategy = RcdStrategy.rcboPerCircuit,

  /// Fire-protection RCD at the input; `null` – automatic (houses and garages).
  final bool? fireRcdAtInput,

  /// Profile of a commercial object; selects СП 256 demand factors.
  final CommercialProfile? commercialProfile,

  /// Supply data.
  final SupplyInput supply = const SupplyInput(),

  /// Cable parameters used unless a circuit overrides them.
  final CableDefaults cableDefaults = const CableDefaults(),

  /// Rooms.
  final List<RoomInput> rooms = const [],

  /// Electrical receivers.
  final List<DeviceInput> devices = const [],

  /// Per-circuit settings and expert overrides keyed by stable circuit id.
  final Map<String, CircuitSettings> circuitSettings = const {},
}) {
  /// Parses JSON produced by [toJson].
  factory fromJson(Json json) => ProjectInput(
    objectType: enumByName(ObjectType.values, json['object_type']),
    supplyPhases: enumByName(SupplyPhases.values, json['supply_phases']),
    nominalVoltageId: json['nominal_voltage_id'] as String? ?? defaultNominalVoltageId,
    cookingFuel: enumByNameOrNull(CookingFuel.values, json['cooking_fuel']),
    rcdStrategy:
        enumByNameOrNull(RcdStrategy.values, json['rcd_strategy']) ?? RcdStrategy.rcboPerCircuit,
    fireRcdAtInput: json['fire_rcd_at_input'] as bool?,
    commercialProfile: enumByNameOrNull(CommercialProfile.values, json['commercial_profile']),
    supply: json['supply'] == null
        ? const SupplyInput()
        : SupplyInput.fromJson(json['supply']! as Json),
    cableDefaults: json['cable_defaults'] == null
        ? const CableDefaults()
        : CableDefaults.fromJson(json['cable_defaults']! as Json),
    rooms: [
      for (final r in (json['rooms'] as List<Object?>? ?? const [])) RoomInput.fromJson(r! as Json),
    ],
    devices: [
      for (final d in (json['devices'] as List<Object?>? ?? const []))
        DeviceInput.fromJson(d! as Json),
    ],
    circuitSettings: {
      for (final e in (json['circuit_settings'] as Json? ?? const {}).entries)
        e.key: CircuitSettings.fromJson(e.value! as Json),
    },
  );

  /// Default nominal voltage: 220/380 В (СП 256, п. 8.23; ГОСТ 32144).
  static const defaultNominalVoltageId = 'u220_380';

  /// Serializes to JSON; keys are stable and snake_case.
  Json toJson() => compact({
    'object_type': objectType.name,
    'supply_phases': supplyPhases.name,
    'nominal_voltage_id': nominalVoltageId,
    'cooking_fuel': cookingFuel?.name,
    'rcd_strategy': rcdStrategy.name,
    'fire_rcd_at_input': fireRcdAtInput,
    'commercial_profile': commercialProfile?.name,
    'supply': supply.toJson(),
    'cable_defaults': cableDefaults.toJson(),
    'rooms': [for (final r in rooms) r.toJson()],
    'devices': [for (final d in devices) d.toJson()],
    'circuit_settings': {for (final e in circuitSettings.entries) e.key: e.value.toJson()},
  });

  /// Returns a copy with the given fields replaced; pass `null` explicitly to clear an
  /// optional field.
  ProjectInput copyWith({
    ObjectType? objectType,
    SupplyPhases? supplyPhases,
    String? nominalVoltageId,
    Object? cookingFuel = unset,
    RcdStrategy? rcdStrategy,
    Object? fireRcdAtInput = unset,
    Object? commercialProfile = unset,
    SupplyInput? supply,
    CableDefaults? cableDefaults,
    List<RoomInput>? rooms,
    List<DeviceInput>? devices,
    Map<String, CircuitSettings>? circuitSettings,
  }) => ProjectInput(
    objectType: objectType ?? this.objectType,
    supplyPhases: supplyPhases ?? this.supplyPhases,
    nominalVoltageId: nominalVoltageId ?? this.nominalVoltageId,
    cookingFuel: identical(cookingFuel, unset) ? this.cookingFuel : cookingFuel as CookingFuel?,
    rcdStrategy: rcdStrategy ?? this.rcdStrategy,
    fireRcdAtInput: identical(fireRcdAtInput, unset)
        ? this.fireRcdAtInput
        : fireRcdAtInput as bool?,
    commercialProfile: identical(commercialProfile, unset)
        ? this.commercialProfile
        : commercialProfile as CommercialProfile?,
    supply: supply ?? this.supply,
    cableDefaults: cableDefaults ?? this.cableDefaults,
    rooms: rooms ?? this.rooms,
    devices: devices ?? this.devices,
    circuitSettings: circuitSettings ?? this.circuitSettings,
  );
}

/// Profile of a commercial object (selects rows of СП 256 табл. 7.6–7.8).
enum CommercialProfile() {
  /// Office, administration (табл. 7.6 поз. 3, 7.7 поз. 1, 7.8 поз. 4).
  office,

  /// Shop (табл. 7.6 поз. 3, 7.7 поз. 2, 7.8 поз. 4).
  shop,

  /// Café, canteen (табл. 7.6 поз. 2, 7.7 поз. 2, 7.8 поз. 1/7.9).
  catering,

  /// Hairdresser, atelier, repair shop (табл. 7.6 поз. 3, 7.7 поз. 2, 7.8 поз. 15).
  services,

  /// Workshop with machine tools (табл. 7.6 поз. 2, 7.8 поз. 11).
  workshop,
}

/// Supply (input) data.
@immutable
final class const SupplyInput({
  /// Allowed (contracted) power from the technical conditions, кВт.
  final double? allowedPowerKw,

  /// Rated current of an existing incomer breaker, A; `null` – selected by the calculation.
  final double? incomerBreakerA,

  /// Phase–protective conductor loop impedance upstream of the panel (Zвнеш), Ом;
  /// `null` – a conservative default is assumed and the result requires review.
  final double? externalLoopImpedanceOhm,

  /// Incomer cable from the metering point to the panel; `null` – not calculated.
  final CircuitSettings? incomerCable,
}) {
  /// Parses JSON produced by [toJson].
  factory fromJson(Json json) => SupplyInput(
    allowedPowerKw: doubleOrNull(json['allowed_power_kw']),
    incomerBreakerA: doubleOrNull(json['incomer_breaker_a']),
    externalLoopImpedanceOhm: doubleOrNull(json['external_loop_impedance_ohm']),
    incomerCable: json['incomer_cable'] == null
        ? null
        : CircuitSettings.fromJson(json['incomer_cable']! as Json),
  );

  /// Returns a copy with the given fields replaced; pass `null` explicitly to clear an
  /// optional field.
  SupplyInput copyWith({
    Object? allowedPowerKw = unset,
    Object? incomerBreakerA = unset,
    Object? externalLoopImpedanceOhm = unset,
    Object? incomerCable = unset,
  }) => SupplyInput(
    allowedPowerKw: identical(allowedPowerKw, unset)
        ? this.allowedPowerKw
        : allowedPowerKw as double?,
    incomerBreakerA: identical(incomerBreakerA, unset)
        ? this.incomerBreakerA
        : incomerBreakerA as double?,
    externalLoopImpedanceOhm: identical(externalLoopImpedanceOhm, unset)
        ? this.externalLoopImpedanceOhm
        : externalLoopImpedanceOhm as double?,
    incomerCable: identical(incomerCable, unset)
        ? this.incomerCable
        : incomerCable as CircuitSettings?,
  );

  /// Serializes to JSON.
  Json toJson() => compact({
    'allowed_power_kw': allowedPowerKw,
    'incomer_breaker_a': incomerBreakerA,
    'external_loop_impedance_ohm': externalLoopImpedanceOhm,
    'incomer_cable': incomerCable?.toJson(),
  });
}

/// Cable parameters used by default for all circuits.
@immutable
final class const CableDefaults({
  /// Conductor material.
  final ConductorMaterial material = ConductorMaterial.copper,

  /// Insulation.
  final Insulation insulation = Insulation.pvc,

  /// Installation method id (`norms_data` installation_methods).
  final String installationMethodId = 'plaster_direct',

  /// Ambient temperature, °C (air or ground depending on the method).
  final double ambientTemperatureC = 30,

  /// Number of circuits laid together (grouping factor).
  final int groupedCircuits = 1,

  /// Soil thermal resistivity, К·м/Вт (cables in the ground).
  final double soilResistivityKMPerW = 2.5,

  /// Default circuit length, m; `null` – circuits without a length are preliminary.
  final double? lengthM,
}) {
  /// Parses JSON produced by [toJson].
  factory fromJson(Json json) => CableDefaults(
    material:
        enumByNameOrNull(ConductorMaterial.values, json['material']) ?? ConductorMaterial.copper,
    insulation: enumByNameOrNull(Insulation.values, json['insulation']) ?? Insulation.pvc,
    installationMethodId: json['installation_method_id'] as String? ?? 'plaster_direct',
    ambientTemperatureC: doubleOrNull(json['ambient_temperature_c']) ?? 30,
    groupedCircuits: json['grouped_circuits'] as int? ?? 1,
    soilResistivityKMPerW: doubleOrNull(json['soil_resistivity_k_m_per_w']) ?? 2.5,
    lengthM: doubleOrNull(json['length_m']),
  );

  /// Returns a copy with the given fields replaced; pass `null` explicitly to clear an
  /// optional field.
  CableDefaults copyWith({
    ConductorMaterial? material,
    Insulation? insulation,
    String? installationMethodId,
    double? ambientTemperatureC,
    int? groupedCircuits,
    double? soilResistivityKMPerW,
    Object? lengthM = unset,
  }) => CableDefaults(
    material: material ?? this.material,
    insulation: insulation ?? this.insulation,
    installationMethodId: installationMethodId ?? this.installationMethodId,
    ambientTemperatureC: ambientTemperatureC ?? this.ambientTemperatureC,
    groupedCircuits: groupedCircuits ?? this.groupedCircuits,
    soilResistivityKMPerW: soilResistivityKMPerW ?? this.soilResistivityKMPerW,
    lengthM: identical(lengthM, unset) ? this.lengthM : lengthM as double?,
  );

  /// Serializes to JSON.
  Json toJson() => compact({
    'material': material.name,
    'insulation': insulation.name,
    'installation_method_id': installationMethodId,
    'ambient_temperature_c': ambientTemperatureC,
    'grouped_circuits': groupedCircuits,
    'soil_resistivity_k_m_per_w': soilResistivityKMPerW,
    'length_m': lengthM,
  });
}

/// Room.
@immutable
final class const RoomInput({
  /// Stable id (UUID).
  required final String id,

  /// Name shown to the user.
  required final String name,

  /// Kind; drives special-location rules.
  required final RoomKind kind,
}) {
  /// Parses JSON produced by [toJson].
  factory fromJson(Json json) => RoomInput(
    id: json['id']! as String,
    name: json['name']! as String,
    kind: enumByName(RoomKind.values, json['kind']),
  );

  /// Returns a copy with the given fields replaced; pass `null` explicitly to clear an
  /// optional field.
  RoomInput copyWith({
    String? id,
    String? name,
    RoomKind? kind,
  }) => RoomInput(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
  );

  /// Serializes to JSON.
  Json toJson() => {'id': id, 'name': name, 'kind': kind.name};
}

/// Catalog kinds that are always on in files written before [DeviceInput.alwaysOn] existed.
const alwaysOnDeviceKinds = {'refrigeration', 'leak_protection'};

/// Electrical receiver (or several identical ones, see [quantity]).
@immutable
final class const DeviceInput({
  /// Stable id (UUID).
  required final String id,

  /// Room the device is in.
  required final String roomId,

  /// Name.
  required final String name,

  /// Kind from the device catalog (e.g. `lighting`, `water_heater`).
  required final String kind,

  /// Rated active power of one unit, Вт.
  required final int powerW,

  /// Number of identical units.
  final int quantity = 1,

  /// 1 or 3.
  final int phases = 1,

  /// Power factor.
  final double cosPhi = 1,

  /// Usage factor ku for the «by devices» input estimate.
  final double usageFactor = 1,

  /// Starting current multiple.
  final double inrushMultiple = 1,

  /// Socket or fixed connection.
  final DeviceConnection connection = DeviceConnection.socket,

  /// Dedicated circuit policy.
  final DedicatedLine dedicatedLine = DedicatedLine.no,

  /// Whether the device stays powered when the load switch is off (a non-switchable line).
  final bool alwaysOn = false,
}) {
  /// Creates a device from a catalog template.
  factory fromTemplate(
    DeviceTemplate t, {
    required String id,
    required String roomId,
    int quantity = 1,
  }) => DeviceInput(
    id: id,
    roomId: roomId,
    name: t.name,
    kind: t.kind,
    powerW: t.powerW,
    quantity: quantity,
    phases: t.phases,
    cosPhi: t.cosPhi,
    usageFactor: t.usageFactor,
    inrushMultiple: t.inrushMultiple,
    connection: t.connection,
    dedicatedLine: t.dedicatedLine,
    alwaysOn: t.alwaysOn,
  );

  /// Parses JSON produced by [toJson].
  factory fromJson(Json json) => DeviceInput(
    id: json['id']! as String,
    roomId: json['room_id']! as String,
    name: json['name']! as String,
    kind: json['kind']! as String,
    powerW: json['power_w']! as int,
    quantity: json['quantity'] as int? ?? 1,
    phases: json['phases'] as int? ?? 1,
    cosPhi: doubleOrNull(json['cos_phi']) ?? 1,
    usageFactor: doubleOrNull(json['usage_factor']) ?? 1,
    inrushMultiple: doubleOrNull(json['inrush_multiple']) ?? 1,
    connection:
        enumByNameOrNull(DeviceConnection.values, json['connection']) ?? DeviceConnection.socket,
    dedicatedLine:
        enumByNameOrNull(DedicatedLine.values, json['dedicated_line']) ?? DedicatedLine.no,
    alwaysOn: json['always_on'] as bool? ?? alwaysOnDeviceKinds.contains(json['kind']),
  );

  /// Total rated power of all units, Вт.
  int get totalPowerW => powerW * quantity;

  /// Returns a copy with the given fields replaced; pass `null` explicitly to clear an
  /// optional field.
  DeviceInput copyWith({
    String? id,
    String? roomId,
    String? name,
    String? kind,
    int? powerW,
    int? quantity,
    int? phases,
    double? cosPhi,
    double? usageFactor,
    double? inrushMultiple,
    DeviceConnection? connection,
    DedicatedLine? dedicatedLine,
    bool? alwaysOn,
  }) => DeviceInput(
    id: id ?? this.id,
    roomId: roomId ?? this.roomId,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    powerW: powerW ?? this.powerW,
    quantity: quantity ?? this.quantity,
    phases: phases ?? this.phases,
    cosPhi: cosPhi ?? this.cosPhi,
    usageFactor: usageFactor ?? this.usageFactor,
    inrushMultiple: inrushMultiple ?? this.inrushMultiple,
    connection: connection ?? this.connection,
    dedicatedLine: dedicatedLine ?? this.dedicatedLine,
    alwaysOn: alwaysOn ?? this.alwaysOn,
  );

  /// Serializes to JSON.
  Json toJson() => {
    'id': id,
    'room_id': roomId,
    'name': name,
    'kind': kind,
    'power_w': powerW,
    'quantity': quantity,
    'phases': phases,
    'cos_phi': cosPhi,
    'usage_factor': usageFactor,
    'inrush_multiple': inrushMultiple,
    'connection': connection.name,
    'dedicated_line': dedicatedLine.name,
    'always_on': alwaysOn,
  };
}

/// Per-circuit settings; every non-null field overrides the automatic value.
///
/// [lengthM], [installationMethodId], [ambientTemperatureC], [groupedCircuits], [material]
/// and [insulation] describe the installation. [sectionMm2], [breakerA], [curve],
/// [protection] and [phase] are expert overrides of the calculated values.
@immutable
final class const CircuitSettings({
  /// Cable length, m.
  final double? lengthM,

  /// Installation method id.
  final String? installationMethodId,

  /// Ambient temperature, °C.
  final double? ambientTemperatureC,

  /// Number of circuits laid together.
  final int? groupedCircuits,

  /// Conductor material.
  final ConductorMaterial? material,

  /// Insulation.
  final Insulation? insulation,

  /// Manual cross-section, mm².
  final double? sectionMm2,

  /// Manual breaker rating, A.
  final double? breakerA,

  /// Manual tripping curve.
  final BreakerCurve? curve,

  /// Manual protection device type.
  final ProtectionDevice? protection,

  /// Manual phase (three-phase supply only).
  final Phase? phase,
}) {
  /// Parses JSON produced by [toJson].
  factory fromJson(Json json) => CircuitSettings(
    lengthM: doubleOrNull(json['length_m']),
    installationMethodId: json['installation_method_id'] as String?,
    ambientTemperatureC: doubleOrNull(json['ambient_temperature_c']),
    groupedCircuits: json['grouped_circuits'] as int?,
    material: enumByNameOrNull(ConductorMaterial.values, json['material']),
    insulation: enumByNameOrNull(Insulation.values, json['insulation']),
    sectionMm2: doubleOrNull(json['section_mm2']),
    breakerA: doubleOrNull(json['breaker_a']),
    curve: enumByNameOrNull(BreakerCurve.values, json['curve']),
    protection: enumByNameOrNull(ProtectionDevice.values, json['protection']),
    phase: enumByNameOrNull(Phase.values, json['phase']),
  );

  /// Whether any calculated value is overridden manually.
  bool get hasManualOverride =>
      sectionMm2 != null ||
      breakerA != null ||
      curve != null ||
      protection != null ||
      phase != null;

  /// Returns a copy with the given fields replaced; pass `null` explicitly to clear an
  /// optional field.
  CircuitSettings copyWith({
    Object? lengthM = unset,
    Object? installationMethodId = unset,
    Object? ambientTemperatureC = unset,
    Object? groupedCircuits = unset,
    Object? material = unset,
    Object? insulation = unset,
    Object? sectionMm2 = unset,
    Object? breakerA = unset,
    Object? curve = unset,
    Object? protection = unset,
    Object? phase = unset,
  }) => CircuitSettings(
    lengthM: identical(lengthM, unset) ? this.lengthM : lengthM as double?,
    installationMethodId: identical(installationMethodId, unset)
        ? this.installationMethodId
        : installationMethodId as String?,
    ambientTemperatureC: identical(ambientTemperatureC, unset)
        ? this.ambientTemperatureC
        : ambientTemperatureC as double?,
    groupedCircuits: identical(groupedCircuits, unset)
        ? this.groupedCircuits
        : groupedCircuits as int?,
    material: identical(material, unset) ? this.material : material as ConductorMaterial?,
    insulation: identical(insulation, unset) ? this.insulation : insulation as Insulation?,
    sectionMm2: identical(sectionMm2, unset) ? this.sectionMm2 : sectionMm2 as double?,
    breakerA: identical(breakerA, unset) ? this.breakerA : breakerA as double?,
    curve: identical(curve, unset) ? this.curve : curve as BreakerCurve?,
    protection: identical(protection, unset) ? this.protection : protection as ProtectionDevice?,
    phase: identical(phase, unset) ? this.phase : phase as Phase?,
  );

  /// Serializes to JSON.
  Json toJson() => compact({
    'length_m': lengthM,
    'installation_method_id': installationMethodId,
    'ambient_temperature_c': ambientTemperatureC,
    'grouped_circuits': groupedCircuits,
    'material': material?.name,
    'insulation': insulation?.name,
    'section_mm2': sectionMm2,
    'breaker_a': breakerA,
    'curve': curve?.name,
    'protection': protection?.name,
    'phase': phase?.name,
  });
}
