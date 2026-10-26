import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/src/catalog/catalog.dart';
import 'package:estimate_core/src/catalog/price.dart';
import 'package:estimate_core/src/estimate/compatibility.dart';
import 'package:estimate_core/src/estimate/estimate_input.dart';
import 'package:estimate_core/src/estimate/estimate_result.dart';
import 'package:estimate_core/src/estimate/requirements.dart';
import 'package:norms_data/norms_data.dart';

/// Default copper cable mark.
const defaultCopperCableMarkId = 'vvgng_a_ls';

/// Aluminium cable mark.
const aluminiumCableMarkId = 'avvgng_a_ls';

/// What the estimate never includes.
const notIncludedItems = [
  'корпус щита, DIN-рейки, шины, клеммы и маркировка',
  'кабеленесущие системы (гофра, кабель-каналы, лотки) и крепёж',
  'розетки, выключатели, распаечные коробки',
  'монтажные работы, доставка, региональные коэффициенты',
];

/// Active models compatible with [requirement], best first: exact matches, then by
/// manufacturer, series and id (case-insensitive). Used for the manual choice list.
List<({ApparatusProduct product, Compatibility compatibility})> compatibleProducts(
  ApparatusRequirement requirement,
  EstimateCatalog catalog,
) {
  final List<({Compatibility compatibility, ApparatusProduct product})> result = [
    for (final p in catalog.products)
      if (p.active && p.function == requirement.function)
        (product: p, compatibility: checkCompatibility(p, requirement)),
  ].where((e) => e.compatibility.isCompatible).toList();
  String manufacturer(ApparatusProduct p) =>
      (catalog.manufacturers[p.manufacturerId]?.name ?? p.manufacturerId).toLowerCase();
  result.sort((a, b) {
    final int byStatus = a.compatibility.status.index.compareTo(b.compatibility.status.index);
    if (byStatus != 0) {
      return byStatus;
    }
    final int byManufacturer = manufacturer(a.product).compareTo(manufacturer(b.product));
    if (byManufacturer != 0) {
      return byManufacturer;
    }
    final int bySeries = a.product.series.toLowerCase().compareTo(b.product.series.toLowerCase());
    return bySeries != 0 ? bySeries : a.product.id.compareTo(b.product.id);
  });
  return result;
}

/// Builds the estimate for a calculated project.
///
/// For every slot: a user selection that is still compatible is used with its snapshot price
/// (or the user's price); otherwise a model is chosen automatically — from the scenario
/// segment's series that covers most slots of this function, then the cheapest compatible
/// model of the segment, then the cheapest compatible model of any segment; if the catalog
/// has none, the average price of the rating range is used. Cables are priced per metre with
/// a length reserve; lines without a length are listed but not summed.
EstimateResult calculateEstimate(
  ProjectInput input,
  ProjectResult result,
  EstimateInput estimate, {
  EstimateCatalog? catalog,
}) => _Estimate(input, result, estimate, catalog ?? EstimateCatalog.embedded).run();

final class _Estimate(
  final ProjectInput input,
  final ProjectResult result,
  final EstimateInput estimate,
  final EstimateCatalog catalog,
) {
  final warnings = <EstimateWarning>[];

  Tier get tier => estimate.scenario.tier;

  EstimateResult run() {
    final List<ApparatusSlot> slots = slotsFor(
      input,
      result,
      dinSocket: estimate.dinSocket ?? true,
    );
    final Map<ApparatusFunction, String> preferred = _preferredSeries(slots);
    final List<EstimateLine> apparatus = [
      for (final slot in slots) _apparatusLine(slot, preferred),
    ];
    final List<EstimateLine> auxiliary = _auxiliaryLines();
    final List<EstimateLine> cables = _cableLines();

    final int stale = apparatus
        .where((l) => l.source != PriceSource.selection && estimate.selections.containsKey(l.id))
        .length;
    if (stale > 0) {
      warnings.add(
        EstimateWarning(
          code: 'stale_selection',
          message:
              '$stale ${_positions(stale)} требуют повторного выбора: сохранённая модель больше не '
              'соответствует расчётным параметрам',
        ),
      );
    }
    final int fallback = apparatus.where((l) => l.source == PriceSource.fallback).length;
    if (fallback > 0) {
      warnings.add(
        EstimateWarning(
          code: 'fallback_price',
          message:
              'Для $fallback ${_positions(fallback)} в каталоге нет совместимой модели: взята усреднённая цена',
        ),
      );
    }
    final int missingCable = cables.where((l) => l.missing.isNotEmpty).length;
    if (missingCable > 0) {
      warnings.add(
        EstimateWarning(
          code: 'cable_data_missing',
          message:
              'Стоимость $missingCable ${_positions(missingCable)} кабеля не посчитана: не хватает данных',
        ),
      );
    }
    final int notPassed = result.circuits.where((c) => c.status != CalculationStatus.passed).length;
    if (notPassed > 0) {
      warnings.add(
        EstimateWarning(
          code: 'cable_requires_review',
          message:
              '$notPassed ${_lines(notPassed)} требуют проверки или доработки: стоимость не подтверждает '
              'пригодность линии',
        ),
      );
    }
    warnings.add(
      EstimateWarning(
        code: 'prices_are_estimates',
        message: 'Цены — ориентировочные розничные (на ${catalog.priceAsOf}), не прайс-лист',
      ),
    );

    PriceRange sum(Iterable<EstimateLine> lines) =>
        lines.fold(PriceRange.zero, (s, l) => s + l.total);
    final PriceRange apparatusTotal = sum(apparatus);
    final PriceRange auxiliaryTotal = sum(auxiliary);
    final PriceRange cableTotal = sum(cables);
    return EstimateResult(
      lines: [...apparatus, ...auxiliary, ...cables],
      apparatusTotal: apparatusTotal,
      auxiliaryTotal: auxiliaryTotal,
      cableTotal: cableTotal,
      total: apparatusTotal + auxiliaryTotal + cableTotal,
      moduleUnits: [...apparatus, ...auxiliary].fold(0, (s, l) => s + l.moduleUnits),
      warnings: warnings,
      notIncluded: notIncludedItems,
      catalogVersion: catalog.catalogVersion,
      priceAsOf: catalog.priceAsOf,
    );
  }

  /// Series of the scenario segment covering most slots per function; ties — lower total
  /// typical price, then series name.
  Map<ApparatusFunction, String> _preferredSeries(List<ApparatusSlot> slots) {
    final result = <ApparatusFunction, String>{};
    for (final ApparatusFunction function in ApparatusFunction.values) {
      final List<ApparatusSlot> functionSlots = slots
          .where((s) => s.requirement.function == function)
          .toList();
      if (functionSlots.isEmpty) {
        continue;
      }
      final bySeries = <String, ({int covered, int price})>{};
      final Set<String> seriesKeys = {
        for (final p in catalog.products)
          if (p.active &&
              p.function == function &&
              catalog.manufacturers[p.manufacturerId]?.tier == tier)
            '${p.manufacturerId}|${p.series}',
      };
      for (final key in seriesKeys) {
        var covered = 0;
        var price = 0;
        for (final slot in functionSlots) {
          final ApparatusProduct? cheapest = _cheapest(
            slot.requirement,
            (p) => '${p.manufacturerId}|${p.series}' == key,
          );
          if (cheapest != null) {
            covered++;
            price += cheapest.price.typicalKopecks;
          }
        }
        bySeries[key] = (covered: covered, price: price);
      }
      final List<MapEntry<String, ({int covered, int price})>> ranked =
          bySeries.entries.where((e) => e.value.covered > 0).toList()..sort((a, b) {
            final int byCovered = b.value.covered.compareTo(a.value.covered);
            if (byCovered != 0) {
              return byCovered;
            }
            final int byPrice = a.value.price.compareTo(b.value.price);
            return byPrice != 0 ? byPrice : a.key.compareTo(b.key);
          });
      if (ranked.isNotEmpty) {
        result[function] = ranked.first.key;
      }
    }
    return result;
  }

  /// Cheapest compatible active model matching [filter]; exact matches win over differences.
  ApparatusProduct? _cheapest(
    ApparatusRequirement requirement,
    bool Function(ApparatusProduct) filter,
  ) {
    ApparatusProduct? best;
    CompatibilityStatus? bestStatus;
    for (final ApparatusProduct p in catalog.products) {
      if (!p.active || p.function != requirement.function || !filter(p)) {
        continue;
      }
      final CompatibilityStatus status = checkCompatibility(p, requirement).status;
      if (status == CompatibilityStatus.incompatible) {
        continue;
      }
      final bool better =
          best == null ||
          status.index < bestStatus!.index ||
          (status == bestStatus &&
              (p.price.typicalKopecks < best.price.typicalKopecks ||
                  (p.price.typicalKopecks == best.price.typicalKopecks &&
                      p.id.compareTo(best.id) < 0)));
      if (better) {
        best = p;
        bestStatus = status;
      }
    }
    return best;
  }

  EstimateLine _apparatusLine(ApparatusSlot slot, Map<ApparatusFunction, String> preferred) {
    final ApparatusRequirement requirement = slot.requirement;
    final ApparatusSelection? selection = estimate.selections[slot.id];
    if (selection != null) {
      final Compatibility compatibility = checkCompatibility(selection.product, requirement);
      if (compatibility.isCompatible) {
        final PriceRange price = selection.customPrice ?? selection.product.price;
        return _productLine(
          slot,
          selection.product,
          compatibility,
          price,
          selection.customPrice != null ? PriceSource.custom : PriceSource.selection,
        );
      }
    }

    final String? preferredKey = preferred[requirement.function];
    final ApparatusProduct? product =
        (preferredKey == null
            ? null
            : _cheapest(requirement, (p) => '${p.manufacturerId}|${p.series}' == preferredKey)) ??
        _cheapest(requirement, (p) => catalog.manufacturers[p.manufacturerId]?.tier == tier) ??
        _cheapest(requirement, (_) => true);
    if (product != null) {
      return _productLine(
        slot,
        product,
        checkCompatibility(product, requirement),
        product.price,
        PriceSource.automatic,
      );
    }

    final FallbackPrice? fallback = _fallback(requirement);
    final PriceRange price = fallback?.price ?? PriceRange.zero;
    return EstimateLine(
      id: slot.id,
      category: EstimateCategory.apparatus,
      title: slot.title,
      description: '${requirement.label} (усреднённая цена)',
      quantity: 1,
      unit: 'шт.',
      unitPrice: price,
      total: price,
      source: PriceSource.fallback,
      circuitId: slot.circuitId,
      requirement: requirement,
      moduleUnits: fallback?.moduleUnits ?? requirement.poles,
      missing: fallback == null ? const ['цена'] : const [],
    );
  }

  EstimateLine _productLine(
    ApparatusSlot slot,
    ApparatusProduct product,
    Compatibility compatibility,
    PriceRange price,
    PriceSource source,
  ) {
    final String manufacturer =
        catalog.manufacturers[product.manufacturerId]?.name ?? product.manufacturerId;
    return EstimateLine(
      id: slot.id,
      category: EstimateCategory.apparatus,
      title: slot.title,
      description:
          '$manufacturer ${product.series}, ${slot.requirement.label}'
          '${product.article == null ? '' : ', арт. ${product.article}'}',
      quantity: 1,
      unit: 'шт.',
      unitPrice: price,
      total: price,
      source: source,
      circuitId: slot.circuitId,
      requirement: slot.requirement,
      productId: product.id,
      manufacturer: manufacturer,
      series: product.series,
      compatibility: compatibility,
      moduleUnits: product.moduleUnits,
    );
  }

  FallbackPrice? _fallback(ApparatusRequirement r) {
    final Iterable<FallbackPrice> candidates = catalog.fallbackPrices.where(
      (f) =>
          f.function == r.function &&
          f.poles == r.poles &&
          f.tier == tier &&
          f.minRatedA <= r.ratedCurrentA &&
          r.ratedCurrentA <= f.maxRatedA,
    );
    // The most specific entry: selective rows only for selective requirements.
    return candidates.where((f) => f.selective == r.selective).firstOrNull;
  }

  /// Auxiliary devices in mounting order: SPD, DIN-rail socket, voltage relay, load switch.
  List<EstimateLine> _auxiliaryLines() {
    final lines = <EstimateLine>[];
    final three = input.supplyPhases == SupplyPhases.three;
    final double incomerA = result.incomer.breakerA ?? 0;
    AuxiliaryDevice? find(String kind, int poles, {double? atLeastA}) => catalog.auxiliaryDevices
        .where((d) => d.kind == kind && d.poles == poles && d.tier == tier)
        .where((d) => atLeastA == null || (d.ratedCurrentA ?? 0) >= atLeastA)
        .firstOrNull;

    final bool spd =
        estimate.surgeProtection ??
        (input.objectType == ObjectType.house || input.objectType == ObjectType.garageWorkshop);
    if (spd) {
      final bool type1 = estimate.overheadSupply;
      lines.add(
        _auxLine(
          'aux/spd',
          'УЗИП',
          find(type1 ? 'spd_type1' : 'spd', three ? 4 : 2),
          'УЗИП',
          typicalUnits: (type1 ? 4 : 2) * (three ? 2 : 1),
        ),
      );
    }

    if (estimate.dinSocket ?? true) {
      lines.add(
        _auxLine(
          'aux/din_socket',
          'Розетка на DIN-рейку',
          find('din_socket', 2),
          'розетка на DIN-рейку 16 А',
          typicalUnits: 3,
        ),
      );
    }

    if (estimate.voltageRelay ?? true) {
      lines.add(
        _auxLine(
          'aux/voltage_relay',
          'Реле напряжения',
          find('voltage_relay', three ? 4 : 2, atLeastA: incomerA),
          'реле на ${incomerA.toStringAsFixed(0)} А',
          typicalUnits: three ? 6 : 2,
        ),
      );
    }

    // ASSUMPTION: design practice, not a norm clause (verification/VERIFICATION.md, E10).
    final bool switchable = result.circuits.any((c) => !c.alwaysOn);
    if ((estimate.loadSwitch ?? true) && switchable) {
      lines.add(
        _auxLine(
          'aux/load_switch',
          'Выключатель нагрузки',
          find('load_switch', three ? 4 : 2, atLeastA: incomerA),
          'выключатель нагрузки на ${incomerA.toStringAsFixed(0)} А',
          typicalUnits: three ? 4 : 2,
        ),
      );
    }
    return lines;
  }

  /// When the catalog has no model, the line keeps [typicalUnits] so the device still takes
  /// its place on the switchboard.
  EstimateLine _auxLine(
    String id,
    String title,
    AuxiliaryDevice? device,
    String fallbackDescription, {
    required int typicalUnits,
  }) => EstimateLine(
    id: id,
    category: EstimateCategory.auxiliary,
    title: title,
    description: device?.name ?? fallbackDescription,
    quantity: 1,
    unit: 'шт.',
    unitPrice: device?.price ?? PriceRange.zero,
    total: device?.price ?? PriceRange.zero,
    source: PriceSource.automatic,
    moduleUnits: device?.moduleUnits ?? typicalUnits,
    missing: device == null ? const ['модель в каталоге'] : const [],
  );

  List<EstimateLine> _cableLines() {
    final lines = <EstimateLine>[];
    final CableResult? incomerCable = result.incomer.cable;
    if (incomerCable != null) {
      lines.add(_cableLine('incomer', 'Кабель ввода', incomerCable));
    }
    for (final CircuitResult c in result.circuits) {
      lines.add(_cableLine(c.id, '№${c.number} ${c.name}', c.cable, circuitId: c.id));
    }
    return lines;
  }

  EstimateLine _cableLine(String key, String title, CableResult cable, {String? circuitId}) {
    final String markId = cable.material == ConductorMaterial.aluminium
        ? aluminiumCableMarkId
        : (estimate.cableMarkId ?? defaultCopperCableMarkId);
    final CableMark? mark = catalog.cableMarks.where((m) => m.id == markId).firstOrNull;
    final CableItem? item = catalog.cables
        .where(
          (i) => i.markId == markId && i.cores == cable.cores && i.sectionMm2 == cable.sectionMm2,
        )
        .firstOrNull;
    final PriceRange? custom = estimate.cableCustomPrices[key];
    final PriceRange? unitPrice = custom ?? item?.pricePerM;
    final double? length = cable.lengthM;
    final missing = <String>[
      if (length == null) 'длина',
      if (unitPrice == null) 'цена кабеля',
    ];
    final double quantity = length == null ? 0.0 : length * estimate.cableReserveFactor;
    final PriceRange total = missing.isEmpty ? unitPrice!.times(quantity) : PriceRange.zero;
    return EstimateLine(
      id: 'cable/$key',
      category: EstimateCategory.cable,
      title: title,
      description: '${mark?.name ?? markId} ${cable.label}',
      quantity: double.parse(quantity.toStringAsFixed(2)),
      unit: 'м',
      unitPrice: unitPrice ?? PriceRange.zero,
      total: total,
      source: custom != null ? PriceSource.custom : PriceSource.automatic,
      circuitId: circuitId,
      missing: missing,
    );
  }
}

String _positions(int n) => _plural(n, 'позиция', 'позиции', 'позиций');

String _lines(int n) => _plural(n, 'линия', 'линии', 'линий');

String _plural(int n, String one, String few, String many) {
  final int mod10 = n % 10;
  final int mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) {
    return one;
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return few;
  }
  return many;
}
