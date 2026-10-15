import 'package:estimate_core/src/catalog/catalog.dart';
import 'package:estimate_core/src/estimate/requirements.dart';
import 'package:norms_data/src/protection.dart';

/// How well a model matches a requirement.
enum CompatibilityStatus() {
  /// Matches the requirement exactly.
  exact,

  /// Can be installed; some parameters are better than required.
  compatibleWithDifferences,

  /// Cannot be installed.
  incompatible,
}

/// Reason why a model differs from or cannot meet the requirement.
enum CompatibilityReason(
  /// Russian description.
  final String message,
) {
  archived('модель снята с продажи'),
  functionMismatch('другой тип аппарата'),
  polesMismatch('другое число полюсов'),
  ratedCurrentMismatch('другой номинальный ток'),
  ratedCurrentBelowRequired('номинальный ток УЗО ниже требуемого'),
  curveMismatch('другая характеристика срабатывания'),
  breakingCapacityBelowRequired('отключающая способность ниже требуемой'),
  leakageMismatch('другой ток утечки'),
  rcdTypeInsufficient('тип УЗО не обеспечивает требуемую защиту'),
  selectivityMismatch('другая селективность'),
  higherRcdRating('номинал УЗО выше требуемого'),
  betterRcdType('тип УЗО выше требуемого'),
  higherBreakingCapacity('отключающая способность выше требуемой'),
}

/// Result of a compatibility check.
final class const Compatibility(
  /// Status.
  final CompatibilityStatus status,

  /// Blocking reasons (incompatible) or differences (compatible).
  final List<CompatibilityReason> reasons,
) {
  /// Can be installed.
  bool get isCompatible => status != CompatibilityStatus.incompatible;
}

/// Compares [product] with [requirement].
///
/// Blocking: function, poles, rated current (exact for MCB/RCBO, not below for RCD), curve,
/// breaking capacity below the minimum, residual current, RCD type weaker than required
/// (AC < A < F < B), selectivity. An archived model is never offered but a stored selection of
/// it stays valid with a difference noted.
Compatibility checkCompatibility(ApparatusProduct product, ApparatusRequirement requirement) {
  final blocking = <CompatibilityReason>[];
  final differences = <CompatibilityReason>[];
  final ApparatusSpec spec = product.spec;

  if (!product.active) differences.add(CompatibilityReason.archived);
  if (product.function != requirement.function) blocking.add(CompatibilityReason.functionMismatch);
  if (spec.poles != requirement.poles) blocking.add(CompatibilityReason.polesMismatch);

  if (requirement.function == ApparatusFunction.rcd) {
    if (spec.ratedCurrentA < requirement.ratedCurrentA) {
      blocking.add(CompatibilityReason.ratedCurrentBelowRequired);
    } else if (spec.ratedCurrentA > requirement.ratedCurrentA) {
      differences.add(CompatibilityReason.higherRcdRating);
    }
  } else if (spec.ratedCurrentA != requirement.ratedCurrentA) {
    blocking.add(CompatibilityReason.ratedCurrentMismatch);
  }

  final BreakerCurve? curve = requirement.curve;
  if (curve != null && spec.curve?.toUpperCase() != curve.name.toUpperCase()) {
    blocking.add(CompatibilityReason.curveMismatch);
  }

  if (requirement.function != ApparatusFunction.rcd) {
    final double capacity = spec.breakingCapacityA ?? 0;
    if (capacity < requirement.minBreakingCapacityA) {
      blocking.add(CompatibilityReason.breakingCapacityBelowRequired);
    } else if (capacity > requirement.minBreakingCapacityA) {
      differences.add(CompatibilityReason.higherBreakingCapacity);
    }
  }

  if (requirement.leakageMa != null && spec.leakageMa != requirement.leakageMa) {
    blocking.add(CompatibilityReason.leakageMismatch);
  }
  final RcdType? type = requirement.rcdType;
  if (type != null) {
    final RcdType? actual = spec.rcdType;
    if (actual == null || actual.index < type.index) {
      blocking.add(CompatibilityReason.rcdTypeInsufficient);
    } else if (actual.index > type.index) {
      differences.add(CompatibilityReason.betterRcdType);
    }
  }
  if (requirement.function != ApparatusFunction.mcb && spec.selective != requirement.selective) {
    blocking.add(CompatibilityReason.selectivityMismatch);
  }

  if (blocking.isNotEmpty) return Compatibility(CompatibilityStatus.incompatible, blocking);
  if (differences.isNotEmpty) {
    return Compatibility(CompatibilityStatus.compatibleWithDifferences, differences);
  }
  return const Compatibility(CompatibilityStatus.exact, []);
}
