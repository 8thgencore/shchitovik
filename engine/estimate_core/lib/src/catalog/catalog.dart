import 'dart:convert';

import 'package:estimate_core/src/catalog/price.dart';
import 'package:estimate_core/src/generated/embedded_catalogs.dart';
import 'package:meta/meta.dart';

/// Kind of a modular protective device.
enum ApparatusFunction(
  /// Key used in the catalog.
  final String key,
) {
  mcb('MCB'),
  rcd('RCD'),
  rcbo('RCBO');

  /// Parses a catalog key.
  static ApparatusFunction fromKey(String key) => values.firstWhere((f) => f.key == key);
}

/// RCD type; a higher index detects more kinds of residual current (AC < A < F < B).
enum RcdType(
  /// Key used in the catalog.
  final String key,
) {
  ac('AC'),
  a('A'),
  f('F'),
  b('B');

  /// Parses a catalog key.
  static RcdType fromKey(String key) => values.firstWhere((t) => t.key == key);
}

/// Price segment of a manufacturer.
enum Tier() {
  budget,
  mid,
  premium,
}

/// Manufacturer.
@immutable
final class const Manufacturer({
  /// Id.
  required final String id,

  /// Brand name.
  required final String name,

  /// Country code.
  required final String country,

  /// Price segment.
  required final Tier tier,
});

/// Technical specification of a protective device.
@immutable
final class const ApparatusSpec({
  /// Poles; RCD/RCBO count N as a pole (2 = 1P+N, 4 = 3P+N).
  required final int poles,

  /// Rated current, A.
  required final double ratedCurrentA,

  /// Tripping curve `B`/`C`/`D` (MCB, RCBO).
  final String? curve,

  /// Rated short-circuit breaking capacity, A (MCB, RCBO).
  final double? breakingCapacityA,

  /// Rated residual operating current, mA (RCD, RCBO).
  final double? leakageMa,

  /// RCD type (RCD, RCBO).
  final RcdType? rcdType,

  /// Time-delayed (S).
  final bool selective = false,
}) {
  /// Parses a catalog `spec` object.
  factory fromJson(Map<String, Object?> json) => ApparatusSpec(
    poles: json['poles']! as int,
    ratedCurrentA: (json['rated_current_a']! as num).toDouble(),
    curve: json['curve'] as String?,
    breakingCapacityA: (json['breaking_capacity_a'] as num?)?.toDouble(),
    leakageMa: (json['leakage_ma'] as num?)?.toDouble(),
    rcdType: json['rcd_type'] == null ? null : RcdType.fromKey(json['rcd_type']! as String),
    selective: json['selectivity'] == 'S',
  );

  /// Serializes to the catalog format.
  Map<String, Object?> toJson() => {
    'poles': poles,
    'rated_current_a': ratedCurrentA,
    if (curve != null) 'curve': curve,
    if (breakingCapacityA != null) 'breaking_capacity_a': breakingCapacityA,
    if (leakageMa != null) 'leakage_ma': leakageMa,
    if (rcdType != null) 'rcd_type': rcdType!.key,
    'selectivity': selective ? 'S' : 'NONE',
  };
}

/// Catalog model of a protective device.
@immutable
final class const ApparatusProduct({
  /// Id.
  required final String id,

  /// Manufacturer id.
  required final String manufacturerId,

  /// Series.
  required final String series,

  /// Function.
  required final ApparatusFunction function,

  /// Specification.
  required final ApparatusSpec spec,

  /// Width in DIN modules.
  required final int moduleUnits,

  /// Price range.
  required final PriceRange price,

  /// How the price was obtained.
  required final String priceBasis,

  /// Model is sold (not archived).
  required final bool active,

  /// Manufacturer's article, if verified.
  final String? article,
}) {
  /// Parses a catalog product.
  factory fromJson(Map<String, Object?> json) {
    final price = json['price']! as Map<String, Object?>;
    return ApparatusProduct(
      id: json['id']! as String,
      manufacturerId: json['manufacturer']! as String,
      series: json['series']! as String,
      function: ApparatusFunction.fromKey(json['function']! as String),
      spec: ApparatusSpec.fromJson(json['spec']! as Map<String, Object?>),
      moduleUnits: json['module_units']! as int,
      price: PriceRange.fromRublesJson(price),
      priceBasis: price['basis']! as String,
      active: json['status'] == 'ACTIVE',
      article: json['article'] as String?,
    );
  }

  /// Serializes to the catalog format (used for selection snapshots).
  Map<String, Object?> toJson() => {
    'id': id,
    'manufacturer': manufacturerId,
    'series': series,
    'function': function.key,
    if (article != null) 'article': article,
    'spec': spec.toJson(),
    'module_units': moduleUnits,
    'price': {
      'min': price.minKopecks / 100,
      'typical': price.typicalKopecks / 100,
      'max': price.maxKopecks / 100,
      'basis': priceBasis,
    },
    'status': active ? 'ACTIVE' : 'ARCHIVED',
  };
}

/// Cable mark.
@immutable
final class const CableMark({
  /// Id.
  required final String id,

  /// Name like `ВВГнг(А)-LS`.
  required final String name,

  /// `copper` or `aluminium`.
  required final String material,

  /// Description.
  required final String note,
});

/// Cable price per metre.
@immutable
final class const CableItem({
  /// Id.
  required final String id,

  /// Mark id.
  required final String markId,

  /// Number of cores.
  required final int cores,

  /// Section, mm².
  required final double sectionMm2,

  /// Price per metre.
  required final PriceRange pricePerM,
});

/// Auxiliary panel device (voltage relay, SPD).
@immutable
final class const AuxiliaryDevice({
  /// Id.
  required final String id,

  /// `voltage_relay`, `spd`, `spd_type1`.
  required final String kind,

  /// Poles.
  required final int poles,

  /// Rated current, A (relays).
  required final double? ratedCurrentA,

  /// Segment.
  required final Tier tier,

  /// Name.
  required final String name,

  /// Width in DIN modules.
  required final int moduleUnits,

  /// Price.
  required final PriceRange price,
});

/// Average price for a function/poles/rating range.
@immutable
final class const FallbackPrice({
  /// Function.
  required final ApparatusFunction function,

  /// Poles.
  required final int poles,

  /// Range of ratings, A.
  required final double minRatedA,

  /// Range of ratings, A.
  required final double maxRatedA,

  /// Segment.
  required final Tier tier,

  /// Only for selective (S) RCDs.
  required final bool selective,

  /// Width in DIN modules.
  required final int moduleUnits,

  /// Price.
  required final PriceRange price,
});

/// All price catalogs. Built from the embedded data or from a downloaded update.
final class EstimateCatalog._({
  /// Version of the apparatus catalog; stored with selections.
  required final String catalogVersion,

  /// When prices were taken (`YYYY-MM`).
  required final String priceAsOf,

  /// Manufacturers by id.
  required final Map<String, Manufacturer> manufacturers,

  /// Protective devices.
  required final List<ApparatusProduct> products,

  /// Cable marks.
  required final List<CableMark> cableMarks,

  /// Cable prices.
  required final List<CableItem> cables,

  /// Auxiliary devices.
  required final List<AuxiliaryDevice> auxiliaryDevices,

  /// Fallback prices.
  required final List<FallbackPrice> fallbackPrices,

  /// Versions of all datasets.
  required final Map<String, String> datasetVersions,
}) {
  /// Parses catalogs given as JSON strings keyed by dataset name.
  factory fromJsonStrings(Map<String, String> datasets) {
    Map<String, Object?> read(String name) => jsonDecode(datasets[name]!) as Map<String, Object?>;
    List<Map<String, Object?>> list(Map<String, Object?> json, String key) => [
      for (final e in json[key]! as List<Object?>) e! as Map<String, Object?>,
    ];

    final Map<String, Object?> apparatus = read('apparatus_catalog');
    final Map<String, Object?> cables = read('cable_catalog');
    final Map<String, Object?> auxiliary = read('auxiliary_devices');
    final Map<String, Object?> fallback = read('fallback_prices');
    return EstimateCatalog._(
      catalogVersion: apparatus['catalog_version']! as String,
      priceAsOf: apparatus['price_as_of']! as String,
      manufacturers: {
        for (final m in list(apparatus, 'manufacturers'))
          m['id']! as String: Manufacturer(
            id: m['id']! as String,
            name: m['name']! as String,
            country: m['country']! as String,
            tier: Tier.values.byName(m['tier']! as String),
          ),
      },
      products: [for (final p in list(apparatus, 'products')) ApparatusProduct.fromJson(p)],
      cableMarks: [
        for (final m in list(cables, 'marks'))
          CableMark(
            id: m['id']! as String,
            name: m['name']! as String,
            material: m['material']! as String,
            note: m['note']! as String,
          ),
      ],
      cables: [
        for (final c in list(cables, 'items'))
          CableItem(
            id: c['id']! as String,
            markId: c['mark']! as String,
            cores: c['cores']! as int,
            sectionMm2: (c['section_mm2']! as num).toDouble(),
            pricePerM: PriceRange.fromRublesJson(c['price_per_m']! as Map<String, Object?>),
          ),
      ],
      auxiliaryDevices: [
        for (final a in list(auxiliary, 'items'))
          AuxiliaryDevice(
            id: a['id']! as String,
            kind: a['kind']! as String,
            poles: a['poles']! as int,
            ratedCurrentA: (a['rated_current_a'] as num?)?.toDouble(),
            tier: Tier.values.byName(a['tier']! as String),
            name: a['name']! as String,
            moduleUnits: a['module_units']! as int,
            price: PriceRange.fromRublesJson(a['price']! as Map<String, Object?>),
          ),
      ],
      fallbackPrices: [
        for (final f in list(fallback, 'items'))
          FallbackPrice(
            function: ApparatusFunction.fromKey(f['function']! as String),
            poles: f['poles']! as int,
            minRatedA: (f['min_rated_a']! as num).toDouble(),
            maxRatedA: (f['max_rated_a']! as num).toDouble(),
            tier: Tier.values.byName(f['tier']! as String),
            selective: f['selectivity'] == 'S',
            moduleUnits: f['module_units']! as int,
            price: PriceRange.fromRublesJson(f['price']! as Map<String, Object?>),
          ),
      ],
      datasetVersions: {
        for (final e in datasets.entries)
          e.key: (jsonDecode(e.value) as Map<String, Object?>)['dataset_version']! as String,
      },
    );
  }

  /// Catalogs embedded at build time.
  static final EstimateCatalog embedded = EstimateCatalog.fromJsonStrings(embeddedCatalogs);

  late final Map<String, ApparatusProduct> _byId = {for (final p in products) p.id: p};

  /// Product by id, or `null`.
  ApparatusProduct? product(String id) => _byId[id];
}
