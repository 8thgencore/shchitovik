import 'package:norms_data/norms_data.dart';
import 'package:test/test.dart';

void main() {
  final norms = NormsData.embedded;

  group('residential, СП 256 табл. 7.1–7.3', () {
    final r = norms.residentialLoads;
    test('one apartment (column 1–5)', () {
      expect(r.specificLoadKwPerApartment(StoveType.naturalGas, 1), 4.5);
      expect(r.specificLoadKwPerApartment(StoveType.electric, 5), 10);
      expect(r.specificLoadKwPerApartment(StoveType.liquefiedGasOrSolidFuel, 3), 6);
    });
    test('interpolation between 6 and 9 apartments', () {
      expect(r.specificLoadKwPerApartment(StoveType.electric, 7), closeTo(5.1 - 1.3 / 3, 1e-9));
    });
    test('comfort demand factor, табл. 7.2', () {
      expect(r.comfortDemandFactor(10), 0.8);
      expect(r.comfortDemandFactor(14), 0.8);
      expect(r.comfortDemandFactor(25), closeTo(0.625, 1e-9));
      expect(r.comfortDemandFactor(100), 0.45);
    });
    test('simultaneity, табл. 7.3', () {
      expect(r.comfortSimultaneityFactor(1), 1.0);
      expect(r.comfortSimultaneityFactor(6), 0.51);
    });
    test('regional factor and power factors', () {
      expect(r.regionalKpk.first.k, 0.81);
      expect(r.regionalKpk.where((g) => g.group >= 2).every((g) => g.k == 0.91), isTrue);
      expect(r.powerFactors['apartments_electric_stoves'], 0.98);
    });
  });

  group('public, СП 256 табл. 7.6–7.8', () {
    final p = norms.publicLoads;
    test('lighting demand factor with interpolation', () {
      expect(p.lightingDemandFactor(3, 5), 1.0);
      expect(p.lightingDemandFactor(3, 7.5), closeTo(0.975, 1e-9));
    });
    test('power demand factor', () {
      expect(p.powerDemandFactor(11, 1), 1.0);
      expect(p.powerDemandFactor(11, 3), 0.5);
      expect(p.powerDemandFactor(11, 4), closeTo(0.35, 1e-9));
      expect(p.powerDemandFactor(11, 10), 0.2);
      expect(p.powerDemandFactor(1, 2), isNull);
    });
    test('specific loads and socket factors', () {
      expect(p.specificLoads.firstWhere((s) => s.item == 21).value, 0.054);
      expect(p.socketRows.first.group, 1.0);
      expect(p.socketPowerKw, 0.06);
    });
  });
}
