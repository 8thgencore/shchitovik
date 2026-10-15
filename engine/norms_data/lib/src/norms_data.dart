import 'dart:convert';

import 'package:norms_data/src/ampacity.dart';
import 'package:norms_data/src/conductors.dart';
import 'package:norms_data/src/correction_factors.dart';
import 'package:norms_data/src/documents.dart';
import 'package:norms_data/src/generated/embedded_datasets.dart';
import 'package:norms_data/src/installation_methods.dart';
import 'package:norms_data/src/json_reading.dart';
import 'package:norms_data/src/limits.dart';
import 'package:norms_data/src/protection.dart';
import 'package:norms_data/src/reference_catalogs.dart';
import 'package:norms_data/src/sp256_loads.dart';

/// All normative tables and reference catalogs.
///
/// Immutable; use [NormsData.embedded] in production and [NormsData.fromDatasets] in tests.
final class NormsData._(final Map<String, JsonMap> _raw) {
  /// Builds from decoded datasets keyed by name (see `data/*.json`).
  factory fromDatasets(Map<String, JsonMap> datasets) => NormsData._(datasets);

  /// Datasets embedded at build time, parsed once.
  static final NormsData embedded = NormsData._({
    for (final e in embeddedDatasets.entries) e.key: jsonDecode(e.value) as JsonMap,
  });

  /// ГОСТ Р 50571.5.52 табл. B.52.2–B.52.5, B.52.10–B.52.13.
  final AmpacityTable ampacity = AmpacityTable.fromJson(_raw['ampacity']!);

  /// ГОСТ Р 50571.5.52 табл. B.52.14–B.52.15.
  final TemperatureFactors temperatureFactors = TemperatureFactors.fromJson(
    _raw['temperature_factors']!,
  );

  /// ГОСТ Р 50571.5.52 табл. B.52.16.
  final SoilResistivityFactors soilFactors = SoilResistivityFactors.fromJson(
    _raw['soil_resistivity_factors']!,
  );

  /// ГОСТ Р 50571.5.52 табл. B.52.17–B.52.19.
  final GroupingFactors grouping = GroupingFactors.fromJson(_raw['grouping_factors']!);

  /// User-facing installation methods.
  final List<InstallationMethod> installationMethods = [
    for (final m in objects(_raw['installation_methods']!['methods']))
      InstallationMethod.fromJson(m),
  ];

  /// Conductor resistance and material constants.
  final ConductorData conductors = ConductorData.fromJson(_raw['conductors']!);

  /// PE sizing.
  final ProtectiveConductorData protectiveConductors = ProtectiveConductorData.fromJson(
    _raw['protective_conductors']!,
  );

  /// Breakers and RCDs.
  final BreakerData breakers = BreakerData.fromJson(_raw['breakers']!);

  /// Maximum disconnection times.
  final DisconnectionTimes disconnectionTimes = DisconnectionTimes.fromJson(
    _raw['disconnection_times']!,
  );

  /// Voltage drop limits.
  final VoltageDropLimits voltageDropLimits = VoltageDropLimits.fromJson(
    _raw['voltage_drop_limits']!,
  );

  /// Minimum cross-sections.
  final MinCrossSections minCrossSections = MinCrossSections.fromJson(_raw['min_cross_sections']!);

  /// Nominal voltages and standard series.
  final ElectricalConstants constants = ElectricalConstants.fromJson(_raw['electrical_constants']!);

  /// СП 256 residential loads.
  final ResidentialLoads residentialLoads = ResidentialLoads.fromJson(
    _raw['sp256_residential_loads']!,
  );

  /// СП 256 public building loads.
  final PublicLoads publicLoads = PublicLoads.fromJson(_raw['sp256_public_loads']!);

  /// Typical receivers.
  final List<DeviceTemplate> devices = [
    for (final d in objects(_raw['device_catalog']!['devices'])) DeviceTemplate.fromJson(d),
  ];

  /// Room templates.
  final List<RoomTemplate> roomTemplates = [
    for (final r in objects(_raw['room_templates']!['rooms'])) RoomTemplate.fromJson(r),
  ];

  /// Normative documents registry.
  final List<NormativeDocument> documents = [
    for (final d in objects(_raw['documents']!['documents'])) NormativeDocument.fromJson(d),
  ];

  /// Dataset versions keyed by dataset name; stored with calculation results.
  Map<String, String> get datasetVersions => {
    for (final e in _raw.entries) e.key: e.value['dataset_version']! as String,
  };

  /// Installation method by [id].
  InstallationMethod installationMethod(String id) =>
      installationMethods.firstWhere((m) => m.id == id);

  /// Receiver template by [id].
  DeviceTemplate device(String id) => devices.firstWhere((d) => d.id == id);
}
