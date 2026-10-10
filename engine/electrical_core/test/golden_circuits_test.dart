import 'dart:math' as math;

import 'package:electrical_core/electrical_core.dart';
import 'package:norms_data/norms_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

/// Hand-calculated scenarios. Expected numbers are derived here from the formulas of the
/// norms with explicit constants, independently of the implementation.
void main() {
  const u0 = 220.0;
  const cmin = 0.95;
  // ГОСТ 22483: R20 Cu; α from β = 234,5 (ГОСТ Р 50571.5.54, A.54.1); PVC 70 °C.
  double rCu70(double r20) => r20 * (1 + 50 / 254.5);

  group('water heater 3500 W, 25 m, conduit in a wall (B2), Zвнеш = 0,5 Ом', () {
    final result = calculateProject(
      singleRoomProject(
        [device('heater', powerW: 3500, kind: 'water_heater')],
        lengthM: 25,
        externalLoopImpedanceOhm: 0.5,
        installationMethodId: 'conduit_in_wall',
      ),
    );
    final c = result.circuits.single;
    const ib = 3500 / u0;

    test('design current IB = P / U0 = 15,91 A → C16', () {
      expect(c.designCurrentA, closeTo(ib, 1e-9));
      expect(c.protection.breakerA, 16);
      expect(c.protection.curve, BreakerCurve.c);
    });

    test('1,5 mm² fails voltage drop (5,42 %), 2,5 mm² passes (3,25 %)', () {
      const vd15 = 100 * 2 * (0.0225 * 25 / 1.5 * 1.0) * ib / u0;
      const vd25 = 100 * 2 * (0.0225 * 25 / 2.5 * 1.0) * ib / u0;
      expect(vd15, greaterThan(4));
      expect(vd25, lessThan(4));
      expect(c.cable.sectionMm2, 2.5);
      expect(c.cable.voltageDropPercent, closeTo(vd25, 1e-9));
      expect(c.cable.voltageDropPercent, closeTo(3.2541, 1e-4));
    });

    test('Iz = 23 A (B.52.2, B2, Cu PVC, 2,5 mm²) ≥ In', () {
      expect(c.cable.ampacityA, 23);
      expect(checkOf(c, CheckCode.breakerVsAmpacity).status, CheckStatus.passed);
    });

    test('fault loop: Iк.мин = 0,95·U0 / (Zвнеш + Zлинии) ≥ 10·In', () {
      final r = 2 * rCu70(7.41) * 25 / 1000;
      const x = 2 * 0.08 * 25 / 1000;
      final zs = 0.5 + math.sqrt(r * r + x * x);
      expect(c.cable.loopImpedanceOhm, closeTo(zs, 1e-9));
      expect(c.cable.faultCurrentMinA, closeTo(cmin * u0 / zs, 1e-6));
      expect(c.cable.faultCurrentMinA, closeTo(221.56, 0.01));
      expect(c.cable.instantaneousTripA, 160);
      expect(checkOf(c, CheckCode.faultDisconnection).status, CheckStatus.passed);
    });

    test('measured Zвнеш and all checks passed → status passed', () {
      expect(c.status, CalculationStatus.passed);
      expect(c.cable.label, '3×2,5');
    });
  });

  group('long socket line 80 m: C16 cannot clear a fault, B16 can', () {
    final result = calculateProject(
      singleRoomProject(
        [
          device(
            'sockets',
            powerW: 200,
            quantity: 3,
            kind: 'socket',
            cosPhi: 0.95,
            connection: DeviceConnection.socket,
            dedicatedLine: DedicatedLine.no,
          ),
        ],
        lengthM: 80,
        externalLoopImpedanceOhm: 0.5,
      ),
    );
    final c = result.circuits.single;

    test('Iк.мин ≈ 108,9 A < 160 A (C16) but ≥ 80 A (B16)', () {
      final r = 2 * rCu70(7.41) * 80 / 1000;
      const x = 2 * 0.08 * 80 / 1000;
      final ik = cmin * u0 / (0.5 + math.sqrt(r * r + x * x));
      expect(ik, closeTo(108.93, 0.01));
      expect(c.protection.label, 'B16');
      expect(c.cable.sectionMm2, 2.5);
      expect(c.cable.faultCurrentMinA, closeTo(ik, 1e-6));
    });

    test('socket circuit gets an RCBO 30 mA', () {
      expect(c.protection.device, ProtectionDevice.rcbo);
      expect(c.protection.rcd!.residualMa, 30);
      expect(c.purpose, CircuitPurpose.power);
    });
  });

  group('motor with 10× starting current needs curve D', () {
    final result = calculateProject(
      singleRoomProject(
        [device('motor', powerW: 1500, kind: 'motor', cosPhi: 0.8, inrushMultiple: 10)],
        lengthM: 5,
        externalLoopImpedanceOhm: 0.2,
      ),
    );
    final c = result.circuits.single;

    test('IB = 8,52 A, start 85,2 A ≥ 5·10 A → D10', () {
      expect(c.designCurrentA, closeTo(1500 / (u0 * 0.8), 1e-9));
      expect(c.startingCurrentA, closeTo(10 * 1500 / (u0 * 0.8), 1e-9));
      expect(c.protection.label, 'D10');
      expect(checkOf(c, CheckCode.startingCurrent).status, CheckStatus.passed);
    });

    test('fixed equipment line may be 1,5 mm² (ГОСТ Р 50571.5.52 табл. 52.2)', () {
      expect(c.cable.sectionMm2, 1.5);
      expect(c.status, CalculationStatus.passed);
    });
  });

  test('three-phase current I = P / (√3·U·cos φ)', () {
    final result = calculateProject(
      singleRoomProject(
        [device('boiler', powerW: 12000, phases: 3, kind: 'heating_boiler')],
        supply: SupplyPhases.three,
        lengthM: 10,
        externalLoopImpedanceOhm: 0.3,
      ),
    );
    final c = result.circuits.single;
    expect(c.designCurrentA, closeTo(12000 / (math.sqrt(3) * 380), 1e-9));
    expect(c.phases, 3);
    expect(c.phase, isNull);
    expect(c.cable.cores, 5);
    expect(c.protection.poles, 3);
  });
}
