import 'package:estimate_core/estimate_core.dart';
import 'package:norms_data/norms_data.dart';
import 'package:test/test.dart';

ApparatusProduct product(
  ApparatusFunction function,
  ApparatusSpec spec, {
  bool active = true,
}) => ApparatusProduct(
  id: 'p',
  manufacturerId: 'm',
  series: 's',
  function: function,
  spec: spec,
  moduleUnits: spec.poles,
  price: const PriceRange.exact(10000),
  priceBasis: 'estimate',
  active: active,
);

void main() {
  const mcbC16 = ApparatusRequirement(
    function: ApparatusFunction.mcb,
    poles: 1,
    ratedCurrentA: 16,
    curve: BreakerCurve.c,
  );
  const rcd25 = ApparatusRequirement(
    function: ApparatusFunction.rcd,
    poles: 2,
    ratedCurrentA: 25,
    leakageMa: 30,
    rcdType: RcdType.a,
  );

  test('exact MCB match', () {
    final Compatibility c = checkCompatibility(
      product(
        ApparatusFunction.mcb,
        const ApparatusSpec(poles: 1, ratedCurrentA: 16, curve: 'C', breakingCapacityA: 4500),
      ),
      mcbC16,
    );
    expect(c.status, CompatibilityStatus.exact);
  });

  test('higher breaking capacity is a difference, lower is blocking', () {
    expect(
      checkCompatibility(
        product(
          ApparatusFunction.mcb,
          const ApparatusSpec(poles: 1, ratedCurrentA: 16, curve: 'C', breakingCapacityA: 6000),
        ),
        mcbC16,
      ).reasons,
      [CompatibilityReason.higherBreakingCapacity],
    );
    expect(
      checkCompatibility(
        product(
          ApparatusFunction.mcb,
          const ApparatusSpec(poles: 1, ratedCurrentA: 16, curve: 'C', breakingCapacityA: 3000),
        ),
        mcbC16,
      ).reasons,
      [CompatibilityReason.breakingCapacityBelowRequired],
    );
  });

  test('MCB rating and curve must match exactly', () {
    final Compatibility c = checkCompatibility(
      product(
        ApparatusFunction.mcb,
        const ApparatusSpec(poles: 2, ratedCurrentA: 20, curve: 'B', breakingCapacityA: 4500),
      ),
      mcbC16,
    );
    expect(c.status, CompatibilityStatus.incompatible);
    expect(c.reasons, [
      CompatibilityReason.polesMismatch,
      CompatibilityReason.ratedCurrentMismatch,
      CompatibilityReason.curveMismatch,
    ]);
  });

  test('RCD: higher rating allowed, lower is not', () {
    expect(
      checkCompatibility(
        product(
          ApparatusFunction.rcd,
          const ApparatusSpec(poles: 2, ratedCurrentA: 40, leakageMa: 30, rcdType: RcdType.a),
        ),
        rcd25,
      ).reasons,
      [CompatibilityReason.higherRcdRating],
    );
    expect(
      checkCompatibility(
        product(
          ApparatusFunction.rcd,
          const ApparatusSpec(poles: 2, ratedCurrentA: 16, leakageMa: 30, rcdType: RcdType.a),
        ),
        rcd25,
      ).reasons,
      [CompatibilityReason.ratedCurrentBelowRequired],
    );
  });

  test('RCD type: AC does not replace A; B does', () {
    expect(
      checkCompatibility(
        product(
          ApparatusFunction.rcd,
          const ApparatusSpec(poles: 2, ratedCurrentA: 25, leakageMa: 30, rcdType: RcdType.ac),
        ),
        rcd25,
      ).reasons,
      [CompatibilityReason.rcdTypeInsufficient],
    );
    expect(
      checkCompatibility(
        product(
          ApparatusFunction.rcd,
          const ApparatusSpec(poles: 2, ratedCurrentA: 25, leakageMa: 30, rcdType: RcdType.b),
        ),
        rcd25,
      ).status,
      CompatibilityStatus.compatibleWithDifferences,
    );
  });

  test('leakage and selectivity must match', () {
    final Compatibility c = checkCompatibility(
      product(
        ApparatusFunction.rcd,
        const ApparatusSpec(
          poles: 2,
          ratedCurrentA: 25,
          leakageMa: 300,
          rcdType: RcdType.a,
          selective: true,
        ),
      ),
      rcd25,
    );
    expect(c.reasons, [
      CompatibilityReason.leakageMismatch,
      CompatibilityReason.selectivityMismatch,
    ]);
  });

  test('archived model stays usable with a difference noted', () {
    final Compatibility c = checkCompatibility(
      product(
        ApparatusFunction.mcb,
        const ApparatusSpec(poles: 1, ratedCurrentA: 16, curve: 'C', breakingCapacityA: 4500),
        active: false,
      ),
      mcbC16,
    );
    expect(c.status, CompatibilityStatus.compatibleWithDifferences);
    expect(c.reasons, [CompatibilityReason.archived]);
  });

  test('choice list: only compatible, exact first, sorted by manufacturer and series', () {
    final List<({Compatibility compatibility, ApparatusProduct product})> list = compatibleProducts(
      mcbC16,
      EstimateCatalog.embedded,
    );
    expect(list, isNotEmpty);
    expect(list.every((e) => e.compatibility.isCompatible), isTrue);
    final List<int> statuses = list.map((e) => e.compatibility.status.index).toList();
    expect(statuses, [...statuses]..sort());
  });
}
