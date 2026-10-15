import 'package:norms_data/src/json_reading.dart';
import 'package:norms_data/src/table_lookup.dart';

/// Kitchen stove type, selects the row of СП 256 табл. 7.1.
enum StoveType(
  /// Key used in the dataset.
  final String key,
) {
  naturalGas('natural_gas'),
  liquefiedGasOrSolidFuel('liquefied_gas_or_solid_fuel'),
  electric('electric_8_5_kw'),
}

/// Residential loads, СП 256 раздел 7.1.
final class ResidentialLoads._({
  required final List<double> _apartments,
  required final Map<String, List<double?>> _specificLoad,
  required final List<double> _comfortDeclaredKw,
  required final List<double> _comfortKc,
  required final List<double> _simultaneityApartments,
  required final List<double> _simultaneityKo,

  /// Regional correction factor kп.к, табл. 7.5а.
  required final List<({int group, String regions, double k})> regionalKpk,

  /// Power factors of feeders, п. 7.1.12, keyed as in the dataset.
  required final Map<String, double> powerFactors,
}) {
  /// Parses the `sp256_residential_loads` dataset.
  factory fromJson(JsonMap json) {
    final JsonMap specific = object(json['specific_load_kw_per_apartment']);
    final JsonMap rows = object(specific['rows']);
    final JsonMap comfort = object(json['comfort_demand_factor']);
    final JsonMap simultaneity = object(json['comfort_simultaneity_factor']);
    final JsonMap pf = object(json['power_factor'])..remove('clause');
    return ResidentialLoads._(
      apartments: doubles(specific['apartments']),
      specificLoad: {for (final e in rows.entries) e.key: nullableDoubles(e.value)},
      comfortDeclaredKw: doubles(comfort['declared_power_kw']),
      comfortKc: doubles(comfort['kc']),
      simultaneityApartments: doubles(simultaneity['apartments']),
      simultaneityKo: doubles(simultaneity['ko_electric_stoves']),
      regionalKpk: [
        for (final g in objects(object(json['regional_correction_kpk'])['groups']))
          (group: g['group']! as int, regions: g['regions']! as String, k: toDouble(g['k'])),
      ],
      powerFactors: {for (final e in pf.entries) e.key: toDouble(e.value)},
    );
  }

  /// Specific design load, кВт/квартиру, табл. 7.1 (interpolated, примечание 1).
  ///
  /// The first column covers 1–5 apartments.
  double specificLoadKwPerApartment(StoveType stove, int apartments) => interpolateLinear(
    _apartments.map((a) => a == 1 ? 5.0 : a).toList(),
    _specificLoad[stove.key]!,
    apartments,
  );

  /// Specific load of summer cottages, кВт/домик, табл. 7.1 поз. 2.
  double summerCottageKw(int count) => interpolateLinear(
    _apartments.map((a) => a == 1 ? 5.0 : a).toList(),
    _specificLoad['summer_cottages']!,
    count,
  );

  /// Demand factor for an apartment of increased comfort by declared power, табл. 7.2.
  ///
  /// «До 14 кВт» → 0,8; «70 и более» → 0,45; interpolated between.
  double comfortDemandFactor(double declaredKw) =>
      interpolateLinear(_comfortDeclaredKw, _comfortKc, declaredKw);

  /// Simultaneity factor Kо for apartments of increased comfort, табл. 7.3.
  double comfortSimultaneityFactor(int apartments) => interpolateLinear(
    _simultaneityApartments.map((a) => a == 1 ? 5.0 : a).toList(),
    _simultaneityKo,
    apartments,
  );
}

/// Public building loads used for small commercial objects, СП 256 раздел 7.2 and табл. 7.5.
final class PublicLoads._({
  /// Installed lighting power columns of табл. 7.6, кВт («до 5» … «св. 500»).
  required final List<double> lightingInstalledKw,

  /// Rows of табл. 7.6.
  required final List<({int item, String organization, List<double?> kc})> lightingRows,

  /// Rows of табл. 7.7.
  required final List<
    ({int item, String organization, double group, double feeder, double buildingInput})
  >
  socketRows,

  /// Installed power of one socket-outlet, кВт (п. 7.2.4).
  required final double socketPowerKw,

  /// Rows of табл. 7.8; `upTo3`/`over5` are null when the row refers to another table.
  required final List<({int item, String loads, double? upTo3, double? over5, String? reference})>
  powerRows,

  /// Receiver count columns of табл. 7.5.
  required final List<double> sanitaryReceivers,

  /// Rows of табл. 7.5 by share of sanitary/refrigeration equipment.
  required final List<({String sharePercent, List<double?> kc})> sanitaryRows,

  /// Rows of табл. 7.14 (enlarged specific loads for estimates).
  required final List<({int item, String? group, String building, String unit, double value})>
  specificLoads,

  /// Rows of табл. 7.12 as text (some values are ranges).
  required final List<({String consumer, String cosPhi})> powerFactorRows,
  required final List<double> _cateringReceivers,
  required final List<double> _cateringKc,
}) {
  /// Parses the `sp256_public_loads` dataset.
  factory fromJson(JsonMap json) {
    final JsonMap lighting = object(json['lighting_demand_factor']);
    final JsonMap sockets = object(json['socket_demand_factor']);
    final JsonMap sanitary = object(json['sanitary_demand_factor']);
    final JsonMap catering = object(json['catering_demand_factor']);
    return PublicLoads._(
      cateringReceivers: doubles(catering['x']),
      cateringKc: doubles(catering['y']),
      lightingInstalledKw: doubles(lighting['installed_kw']),
      lightingRows: [
        for (final r in objects(lighting['rows']))
          (
            item: r['item']! as int,
            organization: r['organization']! as String,
            kc: nullableDoubles(r['kc']),
          ),
      ],
      socketPowerKw: toDouble(sockets['socket_power_kw']),
      socketRows: [
        for (final r in objects(sockets['rows']))
          (
            item: r['item']! as int,
            organization: r['organization']! as String,
            group: toDouble(r['kc_group']),
            feeder: toDouble(r['kc_feeder']),
            buildingInput: toDouble(r['kc_building_input']),
          ),
      ],
      powerRows: [
        for (final r in objects(object(json['power_demand_factor'])['rows']))
          (
            item: r['item']! as int,
            loads: r['loads']! as String,
            upTo3: (r['kc_up_to_3'] is num) ? toDouble(r['kc_up_to_3']) : null,
            over5: (r['kc_over_5'] is num) ? toDouble(r['kc_over_5']) : null,
            reference: r['kc_up_to_3'] is String ? r['kc_up_to_3']! as String : null,
          ),
      ],
      sanitaryReceivers: doubles(sanitary['receivers']),
      sanitaryRows: [
        for (final r in objects(sanitary['rows']))
          (sharePercent: r['share_percent']! as String, kc: nullableDoubles(r['kc'])),
      ],
      specificLoads: [
        for (final r in objects(object(json['specific_loads'])['rows']))
          (
            item: r['item']! as int,
            group: r['group'] as String?,
            building: r['building']! as String,
            unit: r['unit']! as String,
            value: toDouble(r['specific_load']),
          ),
      ],
      powerFactorRows: [
        for (final r in objects(object(json['power_factor'])['rows']))
          (consumer: r['consumer']! as String, cosPhi: r['cos_phi']! as String),
      ],
    );
  }

  /// Demand factor of thermal catering equipment, табл. 7.9, interpolated by the number of
  /// receivers (примечание 4); one receiver → 1.
  double cateringDemandFactor(int receivers) =>
      receivers <= 1 ? 1 : interpolateLinear(_cateringReceivers, _cateringKc, receivers);

  /// Lighting demand factor Kс.о, табл. 7.6 item [item], interpolated by [installedKw].
  double lightingDemandFactor(int item, double installedKw) => interpolateLinear(
    lightingInstalledKw,
    lightingRows.firstWhere((r) => r.item == item).kc,
    installedKw,
  );

  /// Demand factor of табл. 7.8 item [item] for [receivers] working receivers.
  ///
  /// One receiver → 1 (примечание 2). Between «до 3» and «св. 5» the value is interpolated
  /// over 3…5 receivers; `null` if the row refers to another table.
  double? powerDemandFactor(int item, int receivers) {
    final ({int item, String loads, double? over5, String? reference, double? upTo3}) row =
        powerRows.firstWhere((r) => r.item == item);
    if (row.upTo3 == null || row.over5 == null) return null;
    if (receivers <= 1) return 1;
    return interpolateLinear(const [3, 5], [row.upTo3, row.over5], receivers);
  }
}
