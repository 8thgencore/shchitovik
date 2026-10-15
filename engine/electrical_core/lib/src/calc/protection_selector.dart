import 'package:electrical_core/src/calc/tolerance.dart';
import 'package:electrical_core/src/model/enums.dart';
import 'package:electrical_core/src/model/project_input.dart';
import 'package:electrical_core/src/model/project_result.dart';
import 'package:norms_data/norms_data.dart';

/// Maximum rating of a breaker protecting socket-outlets, A (outlets 10(16) A, СП 256 п. 15.28).
const double socketBreakerLimitA = 16;

/// Minimum automatic ratings by purpose, A.
const Map<CircuitPurpose, double> minimumBreakerA = {
  CircuitPurpose.lighting: 10.0,
  CircuitPurpose.power: 16.0,
  CircuitPurpose.dedicated: 10.0,
};

/// Why a circuit needs a 30 mA RCD; empty if it does not.
///
/// - Socket-outlets: additional protection, ГОСТ Р 50571.4.41 411.3.3; СП 256 А.4.11.
/// - Bathrooms, showers, saunas: all circuits of the location, ГОСТ Р 50571.7.701, 701.411.3.3.
/// - Outdoor: СП 256 А.1.6 (outdoor sockets), А.5.4; ПУЭ 7.1.
/// - Heating cables: ГОСТ Р 50571.7.753.
/// - EV charging: ГОСТ Р 50571.7.722 (type A with DC 6 mA detection or type B).
List<String> rcdReasons({required List<DeviceInput> devices, required List<RoomInput> rooms}) {
  final reasons = <String>[];
  if (devices.any((d) => d.connection == DeviceConnection.socket)) {
    reasons.add('розеточная сеть (ГОСТ Р 50571.4.41, 411.3.3; СП 256, А.4.11)');
  }
  if (rooms.any((r) => r.kind == RoomKind.bathroom)) {
    reasons.add('ванная/душевая/сауна (ГОСТ Р 50571.7.701, 701.411.3.3)');
  }
  if (rooms.any((r) => r.kind == RoomKind.outdoor)) {
    reasons.add('наружная установка (СП 256, А.1.6, А.5.4)');
  }
  if (devices.any((d) => d.kind == 'floor_heating')) {
    reasons.add('нагревательный кабель (ГОСТ Р 50571.7.753)');
  }
  if (devices.any((d) => d.kind == 'ev_charger')) {
    reasons.add(
      'зарядка электромобиля (ГОСТ Р 50571.7.722), нужен тип A с контролем DC 6 мА или тип B',
    );
  }
  return reasons;
}

/// Breaker rating and curve choice for a circuit.
final class const BreakerChoice({
  /// Rated current In, A.
  required final double ratedA,

  /// Acceptable curves in order of preference; the cable selection may fall back to the next.
  required final List<BreakerCurve> curves,

  /// Protection checks.
  required final List<Check> checks,
});

/// Selects the breaker of a circuit.
///
/// In: the smallest rating ≥ IB and ≥ the purpose minimum ([minimumBreakerA]).
/// Curve: C by default; D if the starting current reaches the lower instantaneous bound of C
/// (5·In); B is offered as a fallback when C cannot meet the fault-loop condition and the
/// starting current stays below 3·In. Manual values are respected and only checked.
BreakerChoice selectBreaker({
  required NormsData norms,
  required CircuitPurpose purpose,
  required bool socketCircuit,
  required double designCurrentA,
  required double startingCurrentA,
  double? manualRatedA,
  BreakerCurve? manualCurve,
}) {
  final BreakerData breakers = norms.breakers;
  final double minimum = minimumBreakerA[purpose]!;
  final required = designCurrentA > minimum ? designCurrentA : minimum;
  final double rated =
      manualRatedA ?? breakers.ratedCurrentAtOrAbove(required) ?? breakers.ratedCurrents.last;
  final checks = <Check>[];

  final bool loadOk = lessOrEqual(designCurrentA, rated);
  checks.add(
    Check(
      code: CheckCode.loadVsBreaker,
      status: loadOk ? CheckStatus.passed : CheckStatus.failed,
      message: loadOk
          ? 'IB = ${fmt(designCurrentA)} А ≤ In = ${fmt(rated, 0)} А'
          : 'Расчётный ток ${fmt(designCurrentA)} А больше номинала автомата ${fmt(rated, 0)} А',
      value: designCurrentA,
      limit: rated,
      reference: 'ГОСТ Р 50571.4.43, 433.1',
    ),
  );

  if (socketCircuit) {
    final bool ok = lessOrEqual(rated, socketBreakerLimitA);
    checks.add(
      Check(
        code: CheckCode.socketRating,
        status: ok ? CheckStatus.passed : CheckStatus.failed,
        message: ok
            ? 'Розетки защищены автоматом не более 16 А'
            : 'Розетки на 16 А нельзя защищать автоматом ${fmt(rated, 0)} А: подключите приёмник стационарно',
        value: rated,
        limit: socketBreakerLimitA,
        reference: 'СП 256, п. 15.28',
      ),
    );
  }

  bool startsWith(BreakerCurve curve) =>
      startingCurrentA < breakers.instantaneousTripMultiple(curve).min * rated - epsilon;

  final List<BreakerCurve> curves;
  if (manualCurve != null) {
    curves = [manualCurve];
  } else if (startsWith(BreakerCurve.c)) {
    curves = [BreakerCurve.c, if (startsWith(BreakerCurve.b)) BreakerCurve.b];
  } else {
    curves = [BreakerCurve.d];
  }
  final bool startOk = startsWith(curves.first);
  checks.add(
    Check(
      code: CheckCode.startingCurrent,
      status: startOk ? CheckStatus.passed : CheckStatus.failed,
      message: startOk
          ? 'Пусковой ток ${fmt(startingCurrentA)} А ниже порога мгновенного расцепления'
          : 'Пусковой ток ${fmt(startingCurrentA)} А вызовет срабатывание автомата '
                '${curves.first.name.toUpperCase()}${fmt(rated, 0)}',
      value: startingCurrentA,
      limit: breakers.instantaneousTripMultiple(curves.first).min * rated,
      reference: 'ГОСТ IEC 60898-1 (характеристики B, C, D)',
    ),
  );

  return BreakerChoice(ratedA: rated, curves: curves, checks: checks);
}
