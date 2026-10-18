import 'package:norms_data/src/json_reading.dart';

/// Tripping characteristic of a circuit-breaker (ГОСТ IEC 60898-1).
enum BreakerCurve() {
  b,
  c,
  d,
}

/// Circuit-breaker and RCD reference data.
final class BreakerData._({
  /// Rated currents of modular breakers, A, ascending.
  required final List<double> ratedCurrents,
  required final Map<BreakerCurve, ({double min, double max})> _instantaneous,

  /// Conventional tripping current multiple I2 / In.
  required final double conventionalTrippingMultiple,

  /// Rated residual operating currents of RCDs, mA.
  required final List<double> rcdRatedResidualMa,

  /// Rated currents of RCDs, A.
  required final List<double> rcdRatedCurrents,
}) {
  /// Parses the `breakers` dataset.
  factory fromJson(JsonMap json) {
    final JsonMap inst = object(json['instantaneous_trip_multiple']);
    return BreakerData._(
      ratedCurrents: doubles(json['rated_currents_a']),
      instantaneous: {
        for (final curve in BreakerCurve.values)
          curve: (
            min: toDouble(object(inst[curve.name.toUpperCase()])['min']),
            max: toDouble(object(inst[curve.name.toUpperCase()])['max']),
          ),
      },
      conventionalTrippingMultiple: toDouble(json['conventional_tripping_multiple']),
      rcdRatedResidualMa: doubles(json['rcd_rated_residual_ma']),
      rcdRatedCurrents: doubles(json['rcd_rated_currents_a']),
    );
  }

  /// Range of the instantaneous tripping current as a multiple of In.
  ({double min, double max}) instantaneousTripMultiple(BreakerCurve curve) =>
      _instantaneous[curve]!;

  /// Current that guarantees instantaneous tripping (upper bound of the range), A.
  double guaranteedInstantaneousTripA(BreakerCurve curve, double ratedCurrentA) =>
      _instantaneous[curve]!.max * ratedCurrentA;

  /// Smallest rated current not less than [currentA], or `null` above the range.
  double? ratedCurrentAtOrAbove(double currentA) {
    for (final double r in ratedCurrents) {
      if (r >= currentA) {
        return r;
      }
    }
    return null;
  }
}

/// Maximum disconnection times in a TN system (ГОСТ Р 50571.4.41-2022 табл. 41.1, ПУЭ 1.7.79).
final class DisconnectionTimes._({
  /// Final circuits within the limits, U0 = 230 В, с.
  required final double finalCircuitS,

  /// Distribution circuits and final circuits above the limits, с.
  required final double distributionCircuitS,

  /// Final circuits with socket-outlets up to this rated current get [finalCircuitS].
  required final double finalWithSocketsLimitA,

  /// Final circuits with fixed equipment only up to this rated current get [finalCircuitS].
  required final double finalFixedOnlyLimitA,
}) {
  /// Parses the `disconnection_times` dataset.
  factory fromJson(JsonMap json) {
    final JsonMap tn = object(object(json['tn'])['u0_120_to_230_v']);
    final JsonMap limits = object(json['final_circuit_limits_a']);
    return DisconnectionTimes._(
      finalCircuitS: toDouble(tn['final_circuit_s']),
      distributionCircuitS: toDouble(tn['distribution_circuit_s']),
      finalWithSocketsLimitA: toDouble(limits['with_sockets']),
      finalFixedOnlyLimitA: toDouble(limits['fixed_equipment_only']),
    );
  }

  /// Maximum disconnection time for a circuit, с.
  double maxTimeS({
    required bool isFinalCircuit,
    required bool hasSockets,
    required double ratedCurrentA,
  }) {
    if (!isFinalCircuit) {
      return distributionCircuitS;
    }
    final double limit = hasSockets ? finalWithSocketsLimitA : finalFixedOnlyLimitA;
    return ratedCurrentA <= limit ? finalCircuitS : distributionCircuitS;
  }
}
