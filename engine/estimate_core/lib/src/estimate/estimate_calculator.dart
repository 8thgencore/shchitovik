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
  final result = [
    for (final p in catalog.products)
      if (p.active && p.function == requirement.function)
        (product: p, compatibility: checkCompatibility(p, requirement)),
  ].where((e) => e.compatibility.isCompatible).toList();
  String manufacturer(ApparatusProduct p) =>
      (catalog.manufacturers[p.manufacturerId]?.name ?? p.manufacturerId).toLowerCase();
  result.sort((a, b) {
    final byStatus = a.compatibility.status.index.compareTo(b.compatibility.status.index);
    if (byStatus != 0) return byStatus;
    final byManufacturer = manufacturer(a.product).compareTo(manufacturer(b.product));
    if (byManufacturer != 0) return byManufacturer;
    final bySeries = a.product.series.toLowerCase().compareTo(b.product.series.toLowerCase());
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

final class _Estimate {
  _Estimate(this.input, this.result, this.estimate, this.catalog);

  final ProjectInput input;
  final ProjectResult result;
  final EstimateInput estimate;
  final EstimateCatalog catalog;
  final warnings = <EstimateWarning>[];

  Tier get tier => estimate.scenario.tier;

  EstimateResult run() {
    final slots = slotsFor(input, result);
    final preferred = _preferredSeries(slots);
    final apparatus = [for (final slot in slots) _apparatusLine(slot, preferred)];
    final auxiliary = _auxiliaryLines();
    final cables = _cableLines();

    final stale = apparatus
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
    final fallback = apparatus.where((l) => l.source == PriceSource.fallback).length;
    if (fallback > 0) {
      warnings.add(
        EstimateWarning(
          code: 'fallback_price',
          message:
              'Для $fallback ${_positions(fallback)} в каталоге нет совместимой модели: взята усреднённая цена',
        ),
      );
    }
    final missingCable = cables.where((l) => l.missing.isNotEmpty).length;
    if (missingCable > 0) {
      warnings.add(
        EstimateWarning(
          code: 'cable_data_missing',
          message:
              'Стоимость $missingCable ${_positions(missingCable)} кабеля не посчитана: не хватает данных',
        ),
      );
    }
    final notPassed = result.circuits.where((c) => c.status != CalculationStatus.passed).length;
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
    final apparatusTotal = sum(apparatus);
    final auxiliaryTotal = sum(auxiliary);
    final cableTotal = sum(cables);
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
    for (final function in ApparatusFunction.values) {
      final functionSlots = slots.where((s) => s.requirement.function == function).toList();
      if (functionSlots.isEmpty) continue;
      final bySeries = <String, ({int covered, int price})>{};
      final seriesKeys = {
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
          final cheapest = _cheapest(
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
      final ranked = bySeries.entries.where((e) => e.value.covered > 0).toList()
        ..sort((a, b) {
          final byCovered = b.value.covered.compareTo(a.value.covered);
          if (byCovered != 0) return byCovered;
          final byPrice = a.value.price.compareTo(b.value.price);
          return byPrice != 0 ? byPrice : a.key.compareTo(b.key);
        });
      if (ranked.isNotEmpty) result[function] = ranked.first.key;
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
    for (final p in catalog.products) {
      if (!p.active || p.function != requirement.function || !filter(p)) continue;
      final status = checkCompatibility(p, requirement).status;
      if (status == CompatibilityStatus.incompatible) continue;
      final better =
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
    final requirement = slot.requirement;
    final selection = estimate.selections[slot.id];
    if (selection != null) {
      final compatibility = checkCompatibility(selection.product, requirement);
      if (compatibility.isCompatible) {
        final price = selection.customPrice ?? selection.product.price;
        return _productLine(
          slot,
          selection.product,
          compatibility,
          price,
          selection.customPrice != null ? PriceSource.custom : PriceSource.selection,
        );
      }
    }

    final preferredKey = preferred[requirement.function];
    final product =
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

    final fallback = _fallback(requirement);
    final price = fallback?.price ?? PriceRange.zero;
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
    final manufacturer =
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
    final candidates = catalog.fallbackPrices.where(
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

  List<EstimateLine> _auxiliaryLines() {
    final lines = <EstimateLine>[];
    final three = input.supplyPhases == SupplyPhases.three;
    final incomerA = result.incomer.breakerA ?? 0;

    final relay = estimate.voltageRelay ?? true;
    if (relay) {
      final poles = three ? 4 : 2;
      final device = catalog.auxiliaryDevices
          .where((d) => d.kind == 'voltage_relay' && d.poles == poles && d.tier == tier)
          .where((d) => (d.ratedCurrentA ?? 0) >= incomerA)
          .firstOrNull;
      lines.add(
        _auxLine(
          'aux/voltage_relay',
          'Реле напряжения',
          device,
          'реле на ${incomerA.toStringAsFixed(0)} А',
        ),
      );
    }

    final spd =
        estimate.surgeProtection ??
        (input.objectType == ObjectType.house || input.objectType == ObjectType.garageWorkshop);
    if (spd) {
      final kind = estimate.overheadSupply ? 'spd_type1' : 'spd';
      final device = catalog.auxiliaryDevices
          .where((d) => d.kind == kind && d.poles == (three ? 4 : 2) && d.tier == tier)
          .firstOrNull;
      lines.add(_auxLine('aux/spd', 'УЗИП', device, 'УЗИП'));
    }
    return lines;
  }

  EstimateLine _auxLine(
    String id,
    String title,
    AuxiliaryDevice? device,
    String fallbackDescription,
  ) => EstimateLine(
    id: id,
    category: EstimateCategory.auxiliary,
    title: title,
    description: device?.name ?? fallbackDescription,
    quantity: 1,
    unit: 'шт.',
    unitPrice: device?.price ?? PriceRange.zero,
    total: device?.price ?? PriceRange.zero,
    source: PriceSource.automatic,
    moduleUnits: device?.moduleUnits ?? 0,
    missing: device == null ? const ['модель в каталоге'] : const [],
  );

  List<EstimateLine> _cableLines() {
    final lines = <EstimateLine>[];
    final incomerCable = result.incomer.cable;
    if (incomerCable != null) {
      lines.add(_cableLine('incomer', 'Кабель ввода', incomerCable));
    }
    for (final c in result.circuits) {
      lines.add(_cableLine(c.id, '№${c.number} ${c.name}', c.cable, circuitId: c.id));
    }
    return lines;
  }

  EstimateLine _cableLine(String key, String title, CableResult cable, {String? circuitId}) {
    final markId = cable.material == ConductorMaterial.aluminium
        ? aluminiumCableMarkId
        : (estimate.cableMarkId ?? defaultCopperCableMarkId);
    final mark = catalog.cableMarks.where((m) => m.id == markId).firstOrNull;
    final item = catalog.cables
        .where(
          (i) => i.markId == markId && i.cores == cable.cores && i.sectionMm2 == cable.sectionMm2,
        )
        .firstOrNull;
    final custom = estimate.cableCustomPrices[key];
    final unitPrice = custom ?? item?.pricePerM;
    final length = cable.lengthM;
    final missing = <String>[
      if (length == null) 'длина',
      if (unitPrice == null) 'цена кабеля',
    ];
    final quantity = length == null ? 0.0 : length * estimate.cableReserveFactor;
    final total = missing.isEmpty ? unitPrice!.times(quantity) : PriceRange.zero;
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
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}
