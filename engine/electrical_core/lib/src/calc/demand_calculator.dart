import 'dart:math' as math;

import 'package:electrical_core/src/calc/tolerance.dart';
import 'package:electrical_core/src/model/enums.dart';
import 'package:electrical_core/src/model/project_input.dart';
import 'package:norms_data/norms_data.dart';

/// Normative design load of the object.
final class const NormativeDemand({
  /// Design active power, Вт.
  required final double powerW,

  /// Power factor of the input.
  required final double cosPhi,

  /// How the value was obtained (Russian, with references).
  required final String method,
});

/// Kinds counted as sanitary, refrigeration and air-conditioning equipment (СП 256 табл. 7.5).
const _sanitaryKinds = {'refrigeration', 'air_conditioner', 'ventilation', 'pump'};

/// Kinds counted as thermal catering equipment (СП 256 табл. 7.9, примечание 1).
const _cateringThermalKinds = {
  'oven',
  'electric_stove',
  'cooktop',
  'kitchen_appliance',
  'water_heater',
};

/// Kinds of electric cooking appliances.
const electricCookingKinds = {'electric_stove', 'cooktop'};

/// Calculates the normative design load of the input.
///
/// Apartments and houses (СП 256, 7.1): the load of an apartment of increased comfort –
/// declared power × Kс by табл. 7.2 (примечание 4 к табл. 7.1), but not less than the
/// specific load of табл. 7.1 for one apartment with the given stove type (примечание 11
/// for single-family houses). The declared power is the allowed power of the technical
/// conditions; without it the installed power is used (an upper estimate, flagged by the
/// caller as an assumption). Табл. 7.1 alone does not include electric heating, water
/// heaters and air conditioners (примечание 6), which are typical for the app's users.
///
/// Garages, workshops and commercial premises (СП 256, 7.2): lighting × Kс.о (табл. 7.6),
/// other receivers × Kс by табл. 7.8 (or табл. 7.5 / 7.9 where табл. 7.8 refers to them);
/// the mismatch factor K of табл. 7.11 is taken as 1 (conservative). The result is not less
/// than the largest receiver (табл. 7.8, примечание 1).
NormativeDemand normativeDemand(ProjectInput input, List<DeviceInput> devices, NormsData norms) {
  final double installed = devices.fold<double>(0, (s, d) => s + d.totalPowerW);
  switch (input.objectType) {
    case ObjectType.apartment:
    case ObjectType.house:
      final ResidentialLoads residential = norms.residentialLoads;
      final bool hasElectricCooking = devices.any((d) => electricCookingKinds.contains(d.kind));
      final CookingFuel fuel =
          input.cookingFuel ?? (hasElectricCooking ? CookingFuel.electric : CookingFuel.naturalGas);
      final StoveType stove = switch (fuel) {
        CookingFuel.naturalGas => StoveType.naturalGas,
        CookingFuel.liquefiedGasOrSolidFuel => StoveType.liquefiedGasOrSolidFuel,
        CookingFuel.electric => StoveType.electric,
      };
      final double specific = residential.specificLoadKwPerApartment(stove, 1) * 1000;
      final double? allowed = input.supply.allowedPowerKw;
      final double declared = allowed != null ? allowed * 1000 : installed;
      final double kc = residential.comfortDemandFactor(declared / 1000);
      final double comfort = declared * kc;
      final bool hasAirConditioners = devices.any((d) => d.kind == 'air_conditioner');
      final double pf =
          residential.powerFactors[switch ((fuel == CookingFuel.electric, hasAirConditioners)) {
            (true, false) => 'apartments_electric_stoves',
            (true, true) => 'apartments_electric_stoves_with_air_conditioners',
            (false, false) => 'apartments_gas_or_solid_fuel_stoves',
            (false, true) => 'apartments_gas_or_solid_fuel_stoves_with_air_conditioners',
          }]!;
      final bool useComfort = comfort >= specific;
      return NormativeDemand(
        powerW: useComfort ? comfort : specific,
        cosPhi: pf,
        method: useComfort
            ? '${allowed != null ? 'Pзаявл' : 'Pуст'} = ${fmt(declared / 1000, 2)} кВт × Kс = ${fmt(kc, 3)} '
                  '(СП 256, табл. 7.2, прим. 4 к табл. 7.1)'
            : 'Удельная нагрузка ${fmt(specific / 1000, 2)} кВт на квартиру (СП 256, табл. 7.1)',
      );
    case ObjectType.garageWorkshop:
    case ObjectType.commercial:
      return _publicDemand(input, devices, norms, installed);
  }
}

NormativeDemand _publicDemand(
  ProjectInput input,
  List<DeviceInput> devices,
  NormsData norms,
  double installed,
) {
  final PublicLoads loads = norms.publicLoads;
  final CommercialProfile profile =
      input.commercialProfile ??
      (input.objectType == ObjectType.garageWorkshop
          ? CommercialProfile.workshop
          : CommercialProfile.office);
  final int lightingRow = switch (profile) {
    CommercialProfile.catering || CommercialProfile.workshop => 2,
    _ => 3,
  };
  final List<DeviceInput> lighting = devices.where((d) => d.kind == 'lighting').toList();
  final List<DeviceInput> power = devices.where((d) => d.kind != 'lighting').toList();
  final double lightingInstalled = lighting.fold<double>(0, (s, d) => s + d.totalPowerW);
  final double kcLight = lightingInstalled == 0
      ? 1.0
      : loads.lightingDemandFactor(lightingRow, lightingInstalled / 1000);
  final parts = <String>[
    'освещение ${fmt(lightingInstalled / 1000, 2)} кВт × Kс.о = ${fmt(kcLight, 3)} (табл. 7.6, поз. $lightingRow)',
  ];
  double total = lightingInstalled * kcLight;

  double powerKc(List<DeviceInput> group, String label) {
    final int count = group.fold<int>(0, (s, d) => s + d.quantity);
    final double groupPower = group.fold<double>(0, (s, d) => s + d.totalPowerW);
    if (count == 0) {
      return 0;
    }
    double kc;
    String source;
    switch (profile) {
      case CommercialProfile.workshop:
        kc = loads.powerDemandFactor(11, count)!;
        source = 'табл. 7.8, поз. 11';
      case CommercialProfile.services:
        kc = loads.powerDemandFactor(15, count)!;
        source = 'табл. 7.8, поз. 15';
      case CommercialProfile.office:
      case CommercialProfile.shop:
      case CommercialProfile.catering:
        final double sanitary = group
            .where((d) => _sanitaryKinds.contains(d.kind))
            .fold<double>(0, (s, d) => s + d.totalPowerW);
        final num share = groupPower == 0 ? 0 : sanitary / groupPower * 100;
        final rowIndex = share >= 85
            ? 0
            : share >= 75
            ? 1
            : share >= 50
            ? 2
            : share >= 25
            ? 3
            : 4;
        final ({List<double?> kc, String sharePercent}) row = loads.sanitaryRows[rowIndex];
        kc = count <= 1 ? 1 : interpolateLinear(loads.sanitaryReceivers, row.kc, count);
        source = 'табл. 7.5, строка «${row.sharePercent} %» (по табл. 7.8)';
    }
    parts.add('$label ${fmt(groupPower / 1000, 2)} кВт × Kс = ${fmt(kc, 3)} ($source)');
    return groupPower * kc;
  }

  if (profile == CommercialProfile.catering) {
    final List<DeviceInput> thermal = power
        .where((d) => _cateringThermalKinds.contains(d.kind))
        .toList();
    final List<DeviceInput> other = power
        .where((d) => !_cateringThermalKinds.contains(d.kind))
        .toList();
    final int thermalCount = thermal.fold<int>(0, (s, d) => s + d.quantity);
    final double thermalPower = thermal.fold<double>(0, (s, d) => s + d.totalPowerW);
    final double kcThermal = loads.cateringDemandFactor(thermalCount);
    parts.add(
      'тепловое оборудование ${fmt(thermalPower / 1000, 2)} кВт × Kс = ${fmt(kcThermal, 3)} (табл. 7.9)',
    );
    total += thermalPower * kcThermal + powerKc(other, 'прочее');
  } else {
    total += powerKc(power, 'силовые приёмники');
  }

  final double largest = devices.fold<double>(0, (m, d) => d.powerW > m ? d.powerW.toDouble() : m);
  if (total < largest) {
    total = largest;
    parts.add('не менее мощности наибольшего приёмника (табл. 7.8, прим. 1)');
  }

  final double cos = _weightedCosPhi(devices);
  return NormativeDemand(
    powerW: total,
    cosPhi: cos,
    method: 'СП 256, 7.2: ${parts.join('; ')}; K по табл. 7.11 принят равным 1',
  );
}

/// Power factor of the total expected load: P / √(P² + Q²), Q = Σ P·tg φ.
double _weightedCosPhi(List<DeviceInput> devices) {
  var p = 0.0;
  var q = 0.0;
  for (final d in devices) {
    final double power = d.totalPowerW * d.usageFactor;
    p += power;
    q += d.cosPhi >= 1 ? 0 : power * math.sqrt(1 - d.cosPhi * d.cosPhi) / d.cosPhi;
  }
  return p <= epsilon ? 1 : p / math.sqrt(p * p + q * q);
}
