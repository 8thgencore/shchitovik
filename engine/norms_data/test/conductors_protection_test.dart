import 'package:norms_data/norms_data.dart';
import 'package:test/test.dart';

void main() {
  final norms = NormsData.embedded;

  group('conductors (ГОСТ 22483, ГОСТ Р 50571.5.54 A.54.1)', () {
    final c = norms.conductors;
    test('R20 reference values', () {
      expect(c.resistance20OhmPerKm(ConductorMaterial.copper, 1.5), 12.1);
      expect(c.resistance20OhmPerKm(ConductorMaterial.copper, 2.5), 7.41);
      expect(c.resistance20OhmPerKm(ConductorMaterial.aluminium, 16), 1.91);
      expect(c.resistance20OhmPerKm(ConductorMaterial.aluminium, 1.5), isNull);
    });
    test('α20 from β: copper 1/254,5, aluminium 1/248', () {
      expect(c.alpha20(ConductorMaterial.copper), closeTo(0.003929, 1e-6));
      expect(c.alpha20(ConductorMaterial.aluminium), closeTo(0.004032, 1e-6));
    });
    test('resistance at 70 °C', () {
      expect(
        c.resistanceOhmPerKm(ConductorMaterial.copper, 2.5, 70),
        closeTo(7.41 * (1 + 50 / 254.5), 1e-9),
      );
    });
    test('resistance decreases with section; aluminium/copper ratio ≈ 1,6', () {
      for (final m in ConductorMaterial.values) {
        double? previous;
        for (final s in c.sections) {
          final r = c.resistance20OhmPerKm(m, s);
          if (r == null) continue;
          if (previous != null) expect(r, lessThan(previous), reason: '$m $s');
          previous = r;
        }
      }
      for (final s in c.sections) {
        final cu = c.resistance20OhmPerKm(ConductorMaterial.copper, s)!;
        final al = c.resistance20OhmPerKm(ConductorMaterial.aluminium, s);
        if (al != null) expect(al / cu, inInclusiveRange(1.55, 1.70), reason: '$s');
      }
    });
    test('operating temperatures', () {
      expect(c.maxOperatingTemperatureC(Insulation.pvc), 70);
      expect(c.maxOperatingTemperatureC(Insulation.xlpe), 90);
    });
  });

  group('protective conductor, табл. 54.2 и A.54.4', () {
    final pe = norms.protectiveConductors;
    test('min section', () {
      expect(pe.minSectionMm2(2.5), 2.5);
      expect(pe.minSectionMm2(16), 16);
      expect(pe.minSectionMm2(25), 16);
      expect(pe.minSectionMm2(35), 16);
      expect(pe.minSectionMm2(70), 35);
    });
    test('k values', () {
      expect(pe.k(Insulation.pvc, ConductorMaterial.copper), 115);
      expect(pe.k(Insulation.pvc, ConductorMaterial.aluminium), 76);
      expect(pe.k(Insulation.xlpe, ConductorMaterial.copper), 143);
      expect(pe.k(Insulation.xlpe, ConductorMaterial.aluminium), 94);
    });
  });

  group('breakers and disconnection times', () {
    final b = norms.breakers;
    test('guaranteed instantaneous trip uses the upper bound', () {
      expect(b.guaranteedInstantaneousTripA(BreakerCurve.b, 16), 80);
      expect(b.guaranteedInstantaneousTripA(BreakerCurve.c, 16), 160);
      expect(b.guaranteedInstantaneousTripA(BreakerCurve.d, 16), 320);
    });
    test('rated current at or above', () {
      expect(b.ratedCurrentAtOrAbove(16), 16);
      expect(b.ratedCurrentAtOrAbove(16.1), 20);
      expect(b.ratedCurrentAtOrAbove(126), isNull);
    });
    test('conventional tripping current 1,45 In', () {
      expect(b.conventionalTrippingMultiple, 1.45);
    });
    test('TN 230 V disconnection times', () {
      final t = norms.disconnectionTimes;
      expect(t.maxTimeS(isFinalCircuit: true, hasSockets: true, ratedCurrentA: 63), 0.4);
      expect(t.maxTimeS(isFinalCircuit: true, hasSockets: false, ratedCurrentA: 32), 0.4);
      expect(t.maxTimeS(isFinalCircuit: true, hasSockets: false, ratedCurrentA: 40), 5);
      expect(t.maxTimeS(isFinalCircuit: false, hasSockets: false, ratedCurrentA: 25), 5);
    });
  });

  group('limits', () {
    test('voltage drop, СП 256 п. 8.23', () {
      final v = norms.voltageDropLimits;
      expect(v.limitPercent(lighting: true, lengthM: 30), 3);
      expect(v.limitPercent(lighting: false, lengthM: 100), 4);
      expect(v.limitPercent(lighting: false, lengthM: 120), closeTo(4.1, 1e-9));
      expect(v.limitPercent(lighting: false, lengthM: 300), closeTo(4.5, 1e-9));
    });
    test('voltage drop formula parameters, прил. G', () {
      final v = norms.voltageDropLimits;
      expect(v.formulaRho1[ConductorMaterial.copper], 0.0225);
      expect(v.formulaRho1[ConductorMaterial.aluminium], 0.036);
      expect(v.formulaLambdaOhmPerM, closeTo(0.00008, 1e-12));
      expect(v.formulaDefaultCosPhi, 0.8);
    });
    test('minimum sections, СП 256 табл. 15.3 и п. 10.2', () {
      final m = norms.minCrossSections;
      expect(m.groupLine(lighting: true, material: ConductorMaterial.copper), 1.5);
      expect(m.groupLine(lighting: false, material: ConductorMaterial.copper), 2.5);
      expect(m.groupLine(lighting: false, material: ConductorMaterial.aluminium), 4);
      expect(m.electricStoveCopper, 6);
    });
    test('nominal voltages', () {
      expect(norms.constants.voltage('u220_380').phaseV, 220);
      expect(norms.constants.voltage('u230_400').lineV, 400);
    });
  });
}
