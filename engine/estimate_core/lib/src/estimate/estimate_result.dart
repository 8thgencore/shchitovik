import 'package:estimate_core/src/catalog/price.dart';
import 'package:estimate_core/src/estimate/compatibility.dart';
import 'package:estimate_core/src/estimate/requirements.dart';
import 'package:meta/meta.dart';

/// Section of the estimate.
enum EstimateCategory() {
  apparatus,
  auxiliary,
  cable,
}

/// Where a price comes from.
enum PriceSource() {
  /// Model chosen by the user.
  selection,

  /// Model chosen automatically for the scenario.
  automatic,

  /// Price entered by the user.
  custom,

  /// Average price for the rating range (no compatible model in the catalog).
  fallback,
}

/// One line of the estimate.
@immutable
final class const EstimateLine({
  /// Slot id, aux id or `cable/<circuit id>`.
  required final String id,

  /// Section.
  required final EstimateCategory category,

  /// What the line is for (circuit name).
  required final String title,

  /// What is bought (model or cable).
  required final String description,

  /// Quantity (pieces or metres).
  required final double quantity,

  /// `шт.` or `м`.
  required final String unit,

  /// Unit price range; zero if the line is incomplete.
  required final PriceRange unitPrice,

  /// Line total; zero if the line is incomplete.
  required final PriceRange total,

  /// Price source.
  required final PriceSource source,

  /// Circuit served.
  final String? circuitId,

  /// Requirement (apparatus lines).
  final ApparatusRequirement? requirement,

  /// Catalog model id.
  final String? productId,

  /// Manufacturer name.
  final String? manufacturer,

  /// Series.
  final String? series,

  /// Compatibility with the requirement.
  final Compatibility? compatibility,

  /// Width in DIN modules (all units).
  final int moduleUnits = 0,

  /// Missing data that excluded the line from the total (e.g. `длина`).
  final List<String> missing = const [],
}) {
  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
    'id': id,
    'category': category.name,
    'title': title,
    'description': description,
    'quantity': quantity,
    'unit': unit,
    'unit_price': unitPrice.toJson(),
    'total': total.toJson(),
    'source': source.name,
    if (circuitId != null) 'circuit_id': circuitId,
    if (requirement != null) 'requirement': requirement!.toJson(),
    if (productId != null) 'product_id': productId,
    if (manufacturer != null) 'manufacturer': manufacturer,
    if (series != null) 'series': series,
    if (compatibility != null) 'compatibility': compatibility!.status.name,
    'module_units': moduleUnits,
    if (missing.isNotEmpty) 'missing': missing,
  };
}

/// Warning attached to the estimate.
@immutable
final class const EstimateWarning({
  /// Stable code.
  required final String code,

  /// Russian text.
  required final String message,
}) {
  /// Serializes to JSON.
  Map<String, Object?> toJson() => {'code': code, 'message': message};
}

/// Complete estimate.
@immutable
final class const EstimateResult({
  /// Lines: apparatus, auxiliary, cable.
  required final List<EstimateLine> lines,

  /// Protective devices.
  required final PriceRange apparatusTotal,

  /// Auxiliary devices.
  required final PriceRange auxiliaryTotal,

  /// Cables (complete lines only).
  required final PriceRange cableTotal,

  /// Grand total.
  required final PriceRange total,

  /// DIN modules occupied by apparatus and auxiliary devices (for choosing the enclosure).
  required final int moduleUnits,

  /// Warnings.
  required final List<EstimateWarning> warnings,

  /// What the estimate does not include.
  required final List<String> notIncluded,

  /// Catalog version used.
  required final String catalogVersion,

  /// Price date.
  required final String priceAsOf,
}) {
  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
    'lines': [for (final l in lines) l.toJson()],
    'apparatus_total': apparatusTotal.toJson(),
    'auxiliary_total': auxiliaryTotal.toJson(),
    'cable_total': cableTotal.toJson(),
    'total': total.toJson(),
    'module_units': moduleUnits,
    'warnings': [for (final w in warnings) w.toJson()],
    'not_included': notIncluded,
    'catalog_version': catalogVersion,
    'price_as_of': priceAsOf,
  };
}
