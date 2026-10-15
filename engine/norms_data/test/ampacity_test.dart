import 'package:norms_data/norms_data.dart';
import 'package:test/test.dart';

/// Reference values typed from the text of ГОСТ Р 50571.5.52-2011, not from data/*.json.
void main() {
  final AmpacityTable table = NormsData.embedded.ampacity;

  double? current(
    Insulation i,
    ConductorMaterial m,
    int loaded,
    ReferenceMethod method,
    double s,
  ) => table.currentA(
    insulation: i,
    material: m,
    loadedConductors: loaded,
    method: method,
    sectionMm2: s,
  );

  const ConductorMaterial cu = ConductorMaterial.copper;
  const ConductorMaterial al = ConductorMaterial.aluminium;
  const Insulation pvc = Insulation.pvc;
  const Insulation xlpe = Insulation.xlpe;

  final cases = <(String, double?, double?)>[
    ('B.52.2 Cu 1,5 A1', current(pvc, cu, 2, ReferenceMethod.a1, 1.5), 14.5),
    ('B.52.2 Cu 2,5 B1', current(pvc, cu, 2, ReferenceMethod.b1, 2.5), 24),
    ('B.52.2 Cu 2,5 C', current(pvc, cu, 2, ReferenceMethod.c, 2.5), 27),
    ('B.52.2 Cu 4 B2', current(pvc, cu, 2, ReferenceMethod.b2, 4), 30),
    ('B.52.2 Cu 16 D2', current(pvc, cu, 2, ReferenceMethod.d2, 16), 83),
    ('B.52.2 Cu 70 C', current(pvc, cu, 2, ReferenceMethod.c, 70), 213),
    ('B.52.2 Al 16 D2', current(pvc, al, 2, ReferenceMethod.d2, 16), 63),
    ('B.52.2 Al 2,5 D2 (нет данных)', current(pvc, al, 2, ReferenceMethod.d2, 2.5), null),
    ('B.52.2 Al 1,5 (нет данных)', current(pvc, al, 2, ReferenceMethod.c, 1.5), null),
    ('B.52.3 Cu 2,5 C', current(xlpe, cu, 2, ReferenceMethod.c, 2.5), 33),
    ('B.52.3 Al 25 C', current(xlpe, al, 2, ReferenceMethod.c, 25), 101),
    ('B.52.4 Cu 2,5 C', current(pvc, cu, 3, ReferenceMethod.c, 2.5), 24),
    ('B.52.4 Cu 6 B2', current(pvc, cu, 3, ReferenceMethod.b2, 6), 34),
    ('B.52.4 Al 120 D1', current(pvc, al, 3, ReferenceMethod.d1, 120), 150),
    ('B.52.5 Cu 10 B1', current(xlpe, cu, 3, ReferenceMethod.b1, 10), 66),
    ('B.52.10 Cu 1,5 E 2 нагр.', current(pvc, cu, 2, ReferenceMethod.e, 1.5), 22),
    ('B.52.11 Al 16 E 3 нагр.', current(pvc, al, 3, ReferenceMethod.e, 16), 61),
    ('B.52.12 Cu 2,5 E 3 нагр.', current(xlpe, cu, 3, ReferenceMethod.e, 2.5), 32),
    (
      'B.52.12 Cu 50 E 3 нагр. (errata 102 → 192)',
      current(xlpe, cu, 3, ReferenceMethod.e, 50),
      192,
    ),
  ];
  for (final (name, actual, expected) in cases) {
    test(name, () => expect(actual, expected));
  }

  group('invariants over all columns', () {
    final List<double> sections = table.sections;

    test('current does not decrease with section', () {
      for (final Insulation i in Insulation.values) {
        for (final ConductorMaterial m in ConductorMaterial.values) {
          for (final loaded in const [2, 3]) {
            for (final ReferenceMethod method in ReferenceMethod.values) {
              double? previous;
              for (final s in sections) {
                final double? value = current(i, m, loaded, method, s);
                if (value == null) continue;
                if (previous != null) {
                  expect(value, greaterThanOrEqualTo(previous), reason: '$i $m $loaded $method $s');
                }
                previous = value;
              }
            }
          }
        }
      }
    });

    test('XLPE ≥ PVC, two loaded ≥ three loaded, copper > aluminium', () {
      for (final ReferenceMethod method in ReferenceMethod.values) {
        for (final s in sections) {
          for (final ConductorMaterial m in ConductorMaterial.values) {
            for (final loaded in const [2, 3]) {
              final double? p = current(pvc, m, loaded, method, s);
              final double? x = current(xlpe, m, loaded, method, s);
              if (p != null && x != null) {
                expect(x, greaterThanOrEqualTo(p), reason: '$m $loaded $method $s');
              }
            }
            for (final Insulation i in Insulation.values) {
              final double? two = current(i, m, 2, method, s);
              final double? three = current(i, m, 3, method, s);
              if (two != null && three != null) {
                expect(two, greaterThanOrEqualTo(three), reason: '$i $m $method $s');
              }
            }
          }
          for (final Insulation i in Insulation.values) {
            for (final loaded in const [2, 3]) {
              final double? c = current(i, cu, loaded, method, s);
              final double? a = current(i, al, loaded, method, s);
              if (c != null && a != null) {
                expect(c, greaterThan(a), reason: '$i $loaded $method $s');
              }
            }
          }
        }
      }
    });
  });
}
