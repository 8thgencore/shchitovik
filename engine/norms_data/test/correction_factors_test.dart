import 'package:norms_data/norms_data.dart';
import 'package:test/test.dart';

void main() {
  final norms = NormsData.embedded;

  group('temperature, B.52.14 / B.52.15', () {
    final t = norms.temperatureFactors;
    const air = CableEnvironment.air;
    const ground = CableEnvironment.ground;

    test('reference temperatures give 1,0', () {
      expect(t.factor(air, Insulation.pvc, 30), 1.0);
      expect(t.factor(ground, Insulation.xlpe, 20), 1.0);
    });
    test('tabulated values', () {
      expect(t.factor(air, Insulation.pvc, 25), 1.06);
      expect(t.factor(air, Insulation.xlpe, 50), 0.82);
      expect(t.factor(ground, Insulation.pvc, 30), 0.89);
    });
    test('between steps the hotter step is used', () {
      expect(t.factor(air, Insulation.pvc, 31), 0.94);
    });
    test('below the table the first step is used, above — no data', () {
      expect(t.factor(air, Insulation.pvc, -20), 1.22);
      expect(t.factor(air, Insulation.pvc, 65), isNull);
      expect(t.factor(air, Insulation.xlpe, 80), 0.41);
    });
    test('factor does not increase with temperature', () {
      for (final env in CableEnvironment.values) {
        for (final ins in Insulation.values) {
          double? previous;
          for (var temp = 10.0; temp <= 80; temp += 5) {
            final f = t.factor(env, ins, temp);
            if (f == null) break;
            if (previous != null) expect(f, lessThanOrEqualTo(previous), reason: '$env $ins $temp');
            previous = f;
          }
        }
      }
    });
  });

  group('grouping, B.52.17–B.52.19', () {
    final g = norms.grouping;
    test('bunched: 1 → 1,0; 3 → 0,70; 10 → column 12 = 0,45; 25 → no data', () {
      expect(g.air(AirGroupingArrangement.bunched, 1), 1.0);
      expect(g.air(AirGroupingArrangement.bunched, 3), 0.70);
      expect(g.air(AirGroupingArrangement.bunched, 10), 0.45);
      expect(g.air(AirGroupingArrangement.bunched, 25), isNull);
    });
    test('single circuit under a ceiling is already 0,95', () {
      expect(g.air(AirGroupingArrangement.singleLayerUnderCeiling, 1), 0.95);
    });
    test('single layer rows end at 9 circuits', () {
      expect(g.air(AirGroupingArrangement.singleLayerOnWall, 9), 0.70);
      expect(g.air(AirGroupingArrangement.singleLayerOnWall, 10), isNull);
    });
    test('ground tables', () {
      expect(g.directInGround(3, GroundSpacing.touching), 0.65);
      expect(g.directInGround(2, GroundSpacing.m05), 0.90);
      expect(g.inDucts(18, GroundSpacing.touching), 0.37);
      expect(g.inDucts(4, GroundSpacing.m1), 0.90);
    });
    test('air factors do not increase with the number of circuits', () {
      for (final a in AirGroupingArrangement.values) {
        double? previous;
        for (var n = 1; n <= 20; n++) {
          final f = g.air(a, n);
          if (f == null) break;
          if (previous != null) expect(f, lessThanOrEqualTo(previous), reason: '$a $n');
          previous = f;
        }
      }
    });
  });

  group('soil resistivity, B.52.16', () {
    final s = norms.soilFactors;
    test('reference 2,5 К·м/Вт gives 1,0', () {
      expect(s.factor(ReferenceMethod.d1, 2.5), 1.0);
      expect(s.factor(ReferenceMethod.d2, 2.5), 1.0);
    });
    test('between steps the higher resistivity is used', () {
      expect(s.factor(ReferenceMethod.d1, 2.7), 0.96);
      expect(s.factor(ReferenceMethod.d2, 1.2), 1.28);
      expect(s.factor(ReferenceMethod.d2, 3.5), isNull);
    });
  });

  test('installation methods reference known grouping rows', () {
    for (final m in norms.installationMethods) {
      if (m.environment == CableEnvironment.air) {
        expect(m.airArrangement, isNotNull, reason: m.id);
        expect(m.referenceMethod.isInGround, isFalse, reason: m.id);
      } else {
        expect(m.referenceMethod.isInGround, isTrue, reason: m.id);
        expect(m.groupingKey, anyOf('direct_in_ground', 'in_ducts_multicore'), reason: m.id);
      }
    }
  });
}
