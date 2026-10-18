import 'package:norms_data/src/enums.dart';
import 'package:norms_data/src/json_reading.dart';

/// Conductor resistance and material constants (ГОСТ 22483, ГОСТ Р 50571.5.54 табл. A.54.1).
final class ConductorData._({
  /// Cross-sections covered, mm², ascending.
  required final List<double> sections,
  required final Map<ConductorMaterial, List<double?>> _resistance20,
  required final Map<ConductorMaterial, double> _beta,

  /// Inductive reactance of a multicore cable, Ом/км (engineering assumption, CLC/TR 50480).
  required final double reactanceOhmPerKm,
  required final Map<Insulation, double> _maxOperatingTemperature,
  required final Map<Insulation, double> _shortCircuitFinalTemperature,
}) {
  /// Parses the `conductors` dataset.
  factory fromJson(JsonMap json) {
    final JsonMap resistance = object(json['resistance_20c_ohm_per_km']);
    final JsonMap materials = object(json['materials']);
    final JsonMap maxTemp = object(json['max_operating_temperature_c']);
    final JsonMap scTemp = object(json['short_circuit_final_temperature_c']);
    return ConductorData._(
      sections: doubles(json['sections_mm2']),
      resistance20: {
        for (final m in ConductorMaterial.values) m: nullableDoubles(resistance[m.key]),
      },
      beta: {
        for (final m in ConductorMaterial.values) m: toDouble(object(materials[m.key])['beta_c']),
      },
      reactanceOhmPerKm: toDouble(object(json['reactance_ohm_per_km'])['multicore_cable']),
      maxOperatingTemperature: {for (final i in Insulation.values) i: toDouble(maxTemp[i.key])},
      shortCircuitFinalTemperature: {for (final i in Insulation.values) i: toDouble(scTemp[i.key])},
    );
  }

  /// Maximum DC resistance at 20 °C, Ом/км, or `null` if not tabulated.
  double? resistance20OhmPerKm(ConductorMaterial material, double sectionMm2) {
    final int index = sections.indexOf(sectionMm2);
    return index < 0 ? null : _resistance20[material]![index];
  }

  /// Temperature coefficient of resistance at 20 °C, 1/°C: α = 1 / (β + 20).
  double alpha20(ConductorMaterial material) => 1 / (_beta[material]! + 20);

  /// Resistance at [temperatureC], Ом/км: R20 · (1 + α·(T − 20)).
  double? resistanceOhmPerKm(ConductorMaterial material, double sectionMm2, double temperatureC) {
    final double? r20 = resistance20OhmPerKm(material, sectionMm2);
    if (r20 == null) {
      return null;
    }
    return r20 * (1 + alpha20(material) * (temperatureC - 20));
  }

  /// Maximum continuous operating temperature of the insulation, °C (ГОСТ Р 50571.5.52, табл. 52.1).
  double maxOperatingTemperatureC(Insulation insulation) => _maxOperatingTemperature[insulation]!;

  /// Final temperature under short circuit, °C (ГОСТ Р 50571.5.54, табл. A.54.4).
  double shortCircuitFinalTemperatureC(Insulation insulation) =>
      _shortCircuitFinalTemperature[insulation]!;
}

/// Protective conductor sizing (ГОСТ Р 50571.5.54, табл. 54.2, A.54.4).
final class ProtectiveConductorData._(final Map<(Insulation, ConductorMaterial), double> _k) {
  /// Parses the `protective_conductors` dataset.
  factory fromJson(JsonMap json) {
    final JsonMap k = object(json['k_cable_core']);
    return ProtectiveConductorData._({
      for (final i in Insulation.values)
        for (final m in ConductorMaterial.values) (i, m): toDouble(object(k[i.key])[m.key]),
    });
  }

  /// Minimum PE section of the same material as the line conductor, табл. 54.2:
  /// S ≤ 16 → S; 16 < S ≤ 35 → 16; S > 35 → S/2 (the caller rounds up to a standard section).
  double minSectionMm2(double phaseSectionMm2) {
    if (phaseSectionMm2 <= 16) {
      return phaseSectionMm2;
    }
    if (phaseSectionMm2 <= 35) {
      return 16;
    }
    return phaseSectionMm2 / 2;
  }

  /// Factor k for a PE conductor that is a cable core, табл. A.54.4, А·с^½/мм².
  double k(Insulation insulation, ConductorMaterial material) => _k[(insulation, material)]!;
}
