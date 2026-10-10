import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:test/test.dart';

void main() {
  final catalog = EstimateCatalog.embedded;
  final apartment = DemoProjects.oneRoomApartment();
  final apartmentResult = calculateProject(apartment);

  test('price range arithmetic', () {
    const a = PriceRange(minKopecks: 100, typicalKopecks: 200, maxKopecks: 300);
    expect(a + a, const PriceRange(minKopecks: 200, typicalKopecks: 400, maxKopecks: 600));
    expect(a.times(1.5), const PriceRange(minKopecks: 150, typicalKopecks: 300, maxKopecks: 450));
  });

  group('slots', () {
    test(
      'one slot per circuit with the default RCBO strategy, incomer first (2P on single phase)',
      () {
        final slots = slotsFor(apartment, apartmentResult);
        expect(slots.first.id, 'incomer/mcb');
        expect(slots.first.requirement.poles, 2);
        expect(slots.length, apartmentResult.circuits.length + 1);
      },
    );

    test('MCB + RCD strategy adds RCD slots rated not below the breaker', () {
      final input = apartment.copyWith(rcdStrategy: RcdStrategy.rcdPerCircuit);
      final result = calculateProject(input);
      final slots = slotsFor(input, result);
      final rcd = slots.where((s) => s.id.endsWith('/rcd'));
      expect(rcd.length, result.circuits.where((c) => c.protection.rcd != null).length);
      for (final s in rcd) {
        final circuit = result.circuits.firstWhere((c) => c.id == s.circuitId);
        expect(s.requirement.ratedCurrentA, greaterThanOrEqualTo(circuit.protection.breakerA));
      }
    });

    test('house: three-phase incomer 3P and selective fire RCD 4P', () {
      final house = DemoProjects.house();
      final slots = slotsFor(house, calculateProject(house));
      expect(slots.first.requirement.poles, 3);
      final fire = slots.firstWhere((s) => s.id == 'incomer/rcd').requirement;
      expect(fire.selective, isTrue);
      expect(fire.leakageMa, 300);
      expect(fire.poles, 4);
    });
  });

  group('estimate', () {
    final standard = calculateEstimate(apartment, apartmentResult, const EstimateInput());

    test('totals are the sums of the lines and min ≤ typical ≤ max', () {
      final sum = standard.lines.fold(PriceRange.zero, (s, l) => s + l.total);
      expect(standard.total, sum);
      expect(standard.total.minKopecks, lessThanOrEqualTo(standard.total.typicalKopecks));
      expect(standard.total.typicalKopecks, lessThanOrEqualTo(standard.total.maxKopecks));
    });

    test('scenario picks the manufacturer segment', () {
      Set<Tier> tiers(EstimateScenario scenario) {
        final e = calculateEstimate(apartment, apartmentResult, EstimateInput(scenario: scenario));
        return {
          for (final l in e.lines.where((l) => l.productId != null))
            catalog.manufacturers[catalog.product(l.productId!)!.manufacturerId]!.tier,
        };
      }

      expect(tiers(EstimateScenario.economy), {Tier.budget});
      expect(tiers(EstimateScenario.standard), {Tier.mid});
      expect(tiers(EstimateScenario.premium), {Tier.premium});
    });

    test('economy < standard < premium', () {
      int total(EstimateScenario s) => calculateEstimate(
        apartment,
        apartmentResult,
        EstimateInput(scenario: s),
      ).total.typicalKopecks;
      expect(total(EstimateScenario.economy), lessThan(total(EstimateScenario.standard)));
      expect(total(EstimateScenario.standard), lessThan(total(EstimateScenario.premium)));
    });

    test('cable: price per metre × length × reserve', () {
      final circuit = apartmentResult.circuits.first;
      final line = standard.lines.firstWhere((l) => l.id == 'cable/${circuit.id}');
      final item = catalog.cables.firstWhere(
        (i) => i.markId == 'vvgng_a_ls' && i.cores == 3 && i.sectionMm2 == circuit.cable.sectionMm2,
      );
      expect(line.quantity, closeTo(circuit.cable.lengthM! * 1.1, 1e-9));
      expect(line.total, item.pricePerM.times(circuit.cable.lengthM! * 1.1));
    });

    test('voltage relay included by default, SPD only for houses', () {
      expect(standard.lines.map((l) => l.id), contains('aux/voltage_relay'));
      expect(standard.lines.map((l) => l.id), isNot(contains('aux/spd')));
      final house = DemoProjects.house();
      final houseEstimate = calculateEstimate(
        house,
        calculateProject(house),
        const EstimateInput(),
      );
      expect(houseEstimate.lines.map((l) => l.id), contains('aux/spd'));
    });

    test('three-phase RCBO is not in the catalog: fallback price with a warning', () {
      final house = DemoProjects.house();
      final e = calculateEstimate(house, calculateProject(house), const EstimateInput());
      final sauna = e.lines.firstWhere(
        (l) => l.requirement?.function == ApparatusFunction.rcbo && l.requirement!.poles == 4,
      );
      expect(sauna.source, PriceSource.fallback);
      expect(sauna.total.typicalKopecks, greaterThan(0));
      expect(e.warnings.map((w) => w.code), contains('fallback_price'));
    });

    test('missing length excludes the cable line from the total', () {
      final input = apartment.copyWith(cableDefaults: const CableDefaults());
      final e = calculateEstimate(input, calculateProject(input), const EstimateInput());
      final cables = e.lines.where((l) => l.category == EstimateCategory.cable);
      expect(
        cables.every((l) => l.missing.contains('длина') && l.total == PriceRange.zero),
        isTrue,
      );
      expect(e.cableTotal, PriceRange.zero);
      expect(e.warnings.map((w) => w.code), contains('cable_data_missing'));
    });
  });

  group('selections', () {
    final slot = slotsFor(apartment, apartmentResult).firstWhere((s) => s.id.endsWith('/rcbo'));
    final chosen = compatibleProducts(slot.requirement, catalog).last.product;

    test('a compatible selection is used with its snapshot price', () {
      final e = calculateEstimate(
        apartment,
        apartmentResult,
        EstimateInput(
          selections: {
            slot.id: ApparatusSelection(product: chosen, catalogVersion: catalog.catalogVersion),
          },
        ),
      );
      final line = e.lines.firstWhere((l) => l.id == slot.id);
      expect(line.productId, chosen.id);
      expect(line.source, PriceSource.selection);
      expect(line.total, chosen.price);
    });

    test('user price overrides the catalog price', () {
      const price = PriceRange.exact(123400);
      final e = calculateEstimate(
        apartment,
        apartmentResult,
        EstimateInput(
          selections: {
            slot.id: ApparatusSelection(
              product: chosen,
              catalogVersion: catalog.catalogVersion,
              customPrice: price,
            ),
          },
        ),
      );
      final line = e.lines.firstWhere((l) => l.id == slot.id);
      expect(line.source, PriceSource.custom);
      expect(line.total, price);
    });

    test('a selection that no longer fits the calculation is replaced and reported as stale', () {
      final circuitId = slot.circuitId!;
      final changed = apartment.copyWith(
        circuitSettings: {circuitId: const CircuitSettings(breakerA: 25)},
      );
      final e = calculateEstimate(
        changed,
        calculateProject(changed),
        EstimateInput(
          selections: {
            slot.id: ApparatusSelection(product: chosen, catalogVersion: catalog.catalogVersion),
          },
        ),
      );
      final line = e.lines.firstWhere((l) => l.id == slot.id);
      expect(line.source, isNot(PriceSource.selection));
      expect(e.warnings.map((w) => w.code), contains('stale_selection'));
    });

    test('estimate input JSON round trip', () {
      final input = EstimateInput(
        scenario: EstimateScenario.premium,
        voltageRelay: false,
        selections: {
          slot.id: ApparatusSelection(product: chosen, catalogVersion: catalog.catalogVersion),
        },
        cableCustomPrices: const {'incomer': PriceRange.exact(5000)},
      );
      expect(EstimateInput.fromJson(input.toJson()).toJson(), input.toJson());
    });
  });
}
