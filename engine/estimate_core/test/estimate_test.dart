import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:test/test.dart';

void main() {
  final EstimateCatalog catalog = EstimateCatalog.embedded;
  final ProjectInput apartment = DemoProjects.oneRoomApartment();
  final ProjectResult apartmentResult = calculateProject(apartment);

  test('price range arithmetic', () {
    const a = PriceRange(minKopecks: 100, typicalKopecks: 200, maxKopecks: 300);
    expect(a + a, const PriceRange(minKopecks: 200, typicalKopecks: 400, maxKopecks: 600));
    expect(a.times(1.5), const PriceRange(minKopecks: 150, typicalKopecks: 300, maxKopecks: 450));
  });

  group('slots', () {
    test(
      'one slot per circuit with the default RCBO strategy, incomer first (2P on single phase)',
      () {
        final List<ApparatusSlot> slots = slotsFor(apartment, apartmentResult);
        expect(slots.first.id, 'incomer/mcb');
        expect(slots.first.requirement.poles, 2);
        expect(slots.length, apartmentResult.circuits.length + 2);
        expect(slotsFor(apartment, apartmentResult, dinSocket: false), hasLength(slots.length - 1));
      },
    );

    test('DIN-rail socket gets its own RCBO 1P+N C16 30 mA', () {
      final ApparatusRequirement r = slotsFor(
        apartment,
        apartmentResult,
      ).firstWhere((s) => s.id == dinSocketRcboId).requirement;
      expect(r.label, 'Дифавтомат 1P+N C16 30 мА тип A');
    });

    test('MCB + RCD strategy adds RCD slots rated not below the breaker', () {
      final ProjectInput input = apartment.copyWith(rcdStrategy: RcdStrategy.rcdPerCircuit);
      final ProjectResult result = calculateProject(input);
      final List<ApparatusSlot> slots = slotsFor(input, result);
      final Iterable<ApparatusSlot> rcd = slots.where((s) => s.id.endsWith('/rcd'));
      expect(
        rcd.length,
        result.circuits.where((c) => c.protection.device == ProtectionDevice.mcbAndRcd).length,
      );
      for (final s in rcd) {
        final CircuitResult circuit = result.circuits.firstWhere((c) => c.id == s.circuitId);
        expect(s.requirement.ratedCurrentA, greaterThanOrEqualTo(circuit.protection.breakerA));
      }
    });

    test('house: three-phase incomer 3P and selective fire RCD 4P', () {
      final ProjectInput house = DemoProjects.house();
      final List<ApparatusSlot> slots = slotsFor(house, calculateProject(house));
      expect(slots.first.requirement.poles, 3);
      final ApparatusRequirement fire = slots.firstWhere((s) => s.id == 'incomer/rcd').requirement;
      expect(fire.selective, isTrue);
      expect(fire.leakageMa, 300);
      expect(fire.poles, 4);
    });
  });

  group('estimate', () {
    final EstimateResult standard = calculateEstimate(
      apartment,
      apartmentResult,
      const EstimateInput(),
    );

    test('totals are the sums of the lines and min ≤ typical ≤ max', () {
      final PriceRange sum = standard.lines.fold(PriceRange.zero, (s, l) => s + l.total);
      expect(standard.total, sum);
      expect(standard.total.minKopecks, lessThanOrEqualTo(standard.total.typicalKopecks));
      expect(standard.total.typicalKopecks, lessThanOrEqualTo(standard.total.maxKopecks));
    });

    test('scenario picks the manufacturer segment', () {
      Set<Tier> tiers(EstimateScenario scenario) {
        final EstimateResult e = calculateEstimate(
          apartment,
          apartmentResult,
          EstimateInput(scenario: scenario),
        );
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
      final CircuitResult circuit = apartmentResult.circuits.first;
      final EstimateLine line = standard.lines.firstWhere((l) => l.id == 'cable/${circuit.id}');
      final CableItem item = catalog.cables.firstWhere(
        (i) => i.markId == 'vvgng_a_ls' && i.cores == 3 && i.sectionMm2 == circuit.cable.sectionMm2,
      );
      expect(line.quantity, closeTo(circuit.cable.lengthM! * 1.1, 1e-9));
      expect(line.total, item.pricePerM.times(circuit.cable.lengthM! * 1.1));
    });

    test('voltage relay included by default, SPD only for houses', () {
      expect(standard.lines.map((l) => l.id), contains('aux/voltage_relay'));
      expect(standard.lines.map((l) => l.id), isNot(contains('aux/spd')));
      final ProjectInput house = DemoProjects.house();
      final EstimateResult houseEstimate = calculateEstimate(
        house,
        calculateProject(house),
        const EstimateInput(),
      );
      expect(houseEstimate.lines.map((l) => l.id), contains('aux/spd'));
    });

    test('three-phase RCBO is not in the catalog: fallback price with a warning', () {
      final ProjectInput house = DemoProjects.house();
      final EstimateResult e = calculateEstimate(
        house,
        calculateProject(house),
        const EstimateInput(),
      );
      final EstimateLine sauna = e.lines.firstWhere(
        (l) => l.requirement?.function == ApparatusFunction.rcbo && l.requirement!.poles == 4,
      );
      expect(sauna.source, PriceSource.fallback);
      expect(sauna.total.typicalKopecks, greaterThan(0));
      expect(e.warnings.map((w) => w.code), contains('fallback_price'));
    });

    test('missing length excludes the cable line from the total', () {
      final ProjectInput input = apartment.copyWith(cableDefaults: const CableDefaults());
      final EstimateResult e = calculateEstimate(
        input,
        calculateProject(input),
        const EstimateInput(),
      );
      final Iterable<EstimateLine> cables = e.lines.where(
        (l) => l.category == EstimateCategory.cable,
      );
      expect(
        cables.every((l) => l.missing.contains('длина') && l.total == PriceRange.zero),
        isTrue,
      );
      expect(e.cableTotal, PriceRange.zero);
      expect(e.warnings.map((w) => w.code), contains('cable_data_missing'));
    });
  });

  group('selections', () {
    final ApparatusSlot slot = slotsFor(
      apartment,
      apartmentResult,
    ).firstWhere((s) => s.circuitId != null && s.id.endsWith('/rcbo'));
    final ApparatusProduct chosen = compatibleProducts(slot.requirement, catalog).last.product;

    test('a compatible selection is used with its snapshot price', () {
      final EstimateResult e = calculateEstimate(
        apartment,
        apartmentResult,
        EstimateInput(
          selections: {
            slot.id: ApparatusSelection(product: chosen, catalogVersion: catalog.catalogVersion),
          },
        ),
      );
      final EstimateLine line = e.lines.firstWhere((l) => l.id == slot.id);
      expect(line.productId, chosen.id);
      expect(line.source, PriceSource.selection);
      expect(line.total, chosen.price);
    });

    test('user price overrides the catalog price', () {
      const price = PriceRange.exact(123400);
      final EstimateResult e = calculateEstimate(
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
      final EstimateLine line = e.lines.firstWhere((l) => l.id == slot.id);
      expect(line.source, PriceSource.custom);
      expect(line.total, price);
    });

    test('a selection that no longer fits the calculation is replaced and reported as stale', () {
      final String circuitId = slot.circuitId!;
      final ProjectInput changed = apartment.copyWith(
        circuitSettings: {circuitId: const CircuitSettings(breakerA: 25)},
      );
      final EstimateResult e = calculateEstimate(
        changed,
        calculateProject(changed),
        EstimateInput(
          selections: {
            slot.id: ApparatusSelection(product: chosen, catalogVersion: catalog.catalogVersion),
          },
        ),
      );
      final EstimateLine line = e.lines.firstWhere((l) => l.id == slot.id);
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
