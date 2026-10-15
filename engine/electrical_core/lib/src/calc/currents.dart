import 'dart:math' as math;

import 'package:electrical_core/src/model/project_input.dart';

/// Phase current of a load as active and reactive components, A.
///
/// Summing components (not magnitudes) gives the vector sum of currents with different
/// power factors.
final class const CurrentVector(
  /// Active component, A.
  final double activeA,

  /// Reactive component, A.
  final double reactiveA,
) {
  /// Zero current.
  static const zero = CurrentVector(0, 0);

  /// Magnitude, A.
  double get magnitudeA => math.sqrt(activeA * activeA + reactiveA * reactiveA);

  /// Power factor of the resulting current; 1 for zero current.
  double get cosPhi => magnitudeA == 0 ? 1 : activeA / magnitudeA;

  /// Vector sum.
  CurrentVector operator +(CurrentVector other) =>
      CurrentVector(activeA + other.activeA, reactiveA + other.reactiveA);
}

/// Phase current of [device] (all its units).
///
/// Single-phase: I = P / (U0·cos φ). Three-phase: I = P / (√3·U·cos φ).
/// With [demand] the power is multiplied by the usage factor ku.
CurrentVector deviceCurrent(
  DeviceInput device, {
  required double phaseVoltageV,
  required double lineVoltageV,
  bool demand = false,
}) {
  final num power = device.totalPowerW * (demand ? device.usageFactor : 1);
  final double active = device.phases == 3
      ? power / (math.sqrt(3) * lineVoltageV)
      : power / phaseVoltageV;
  final double cos = device.cosPhi;
  final double tan = cos >= 1 ? 0.0 : math.sqrt(1 - cos * cos) / cos;
  return CurrentVector(active, active * tan);
}
