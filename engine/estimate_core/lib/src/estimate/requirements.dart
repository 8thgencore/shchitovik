import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/src/catalog/catalog.dart';
import 'package:meta/meta.dart';
import 'package:norms_data/norms_data.dart';

/// Minimum rated short-circuit breaking capacity of modular breakers, A.
///
/// 4,5 кА is the smallest standard value of ГОСТ IEC 60898-1 for household breakers; the
/// prospective short-circuit current at the panel is not calculated, so a higher value is
/// treated as a difference, not a requirement.
const double minimumBreakingCapacityA = 4500;

/// What has to be installed in one place of the panel.
@immutable
final class const ApparatusRequirement({
  /// Function.
  required final ApparatusFunction function,

  /// Poles (RCD/RCBO count N: 2 = 1P+N, 4 = 3P+N).
  required final int poles,

  /// Rated current: exact for MCB/RCBO, minimum for RCD.
  required final double ratedCurrentA,

  /// Curve (MCB, RCBO).
  final BreakerCurve? curve,

  /// Minimum breaking capacity, A (MCB, RCBO).
  final double minBreakingCapacityA = minimumBreakingCapacityA,

  /// Residual current, mA (RCD, RCBO).
  final double? leakageMa,

  /// Minimum RCD type (RCD, RCBO).
  final RcdType? rcdType,

  /// Time-delayed RCD required.
  final bool selective = false,
}) {
  /// Short description like `MCB 1P C16`.
  String get label {
    final parts = <String>[
      switch (function) {
        ApparatusFunction.mcb => 'Автомат',
        ApparatusFunction.rcd => 'УЗО',
        ApparatusFunction.rcbo => 'Дифавтомат',
      },
      _polesLabel,
      if (curve != null)
        '${curve!.name.toUpperCase()}${_n(ratedCurrentA)}'
      else
        '${_n(ratedCurrentA)} А',
      if (leakageMa != null) '${_n(leakageMa!)} мА',
      if (rcdType != null) 'тип ${rcdType!.key}${selective ? ' S' : ''}',
    ];
    return parts.join(' ');
  }

  String get _polesLabel => switch ((function, poles)) {
    (ApparatusFunction.mcb, _) => '${poles}P',
    (_, 2) => '1P+N',
    (_, 4) => '3P+N',
    _ => '${poles}P',
  };

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
    'function': function.key,
    'poles': poles,
    'rated_current_a': ratedCurrentA,
    if (curve != null) 'curve': curve!.name.toUpperCase(),
    'min_breaking_capacity_a': minBreakingCapacityA,
    if (leakageMa != null) 'leakage_ma': leakageMa,
    if (rcdType != null) 'rcd_type': rcdType!.key,
    'selective': selective,
  };
}

/// Place for one device in the panel.
@immutable
final class const ApparatusSlot({
  /// Stable id: `<circuit id>/mcb|rcd|rcbo`, `incomer/mcb`, `incomer/rcd`, `rcd-<n>`.
  required final String id,

  /// Title for the estimate.
  required final String title,

  /// Requirement.
  required final ApparatusRequirement requirement,

  /// Circuit served, if any.
  final String? circuitId,
});

/// Builds the list of slots from a calculation result. The incomer comes first.
List<ApparatusSlot> slotsFor(ProjectInput input, ProjectResult result) {
  final three = input.supplyPhases == SupplyPhases.three;
  final slots = <ApparatusSlot>[];

  final double? incomerA = result.incomer.breakerA;
  if (incomerA != null) {
    slots.add(
      ApparatusSlot(
        id: 'incomer/mcb',
        title: 'Вводной автомат',
        requirement: ApparatusRequirement(
          function: ApparatusFunction.mcb,
          poles: three ? 3 : 2,
          ratedCurrentA: incomerA,
          curve: BreakerCurve.c,
        ),
      ),
    );
  }
  final SharedRcdResult? fire = result.fireRcd;
  if (fire != null) {
    slots.add(
      ApparatusSlot(
        id: 'incomer/rcd',
        title: 'Противопожарное УЗО на вводе',
        requirement: ApparatusRequirement(
          function: ApparatusFunction.rcd,
          poles: fire.poles,
          ratedCurrentA: fire.ratedA,
          leakageMa: fire.residualMa,
          rcdType: RcdType.fromKey(fire.type),
          selective: fire.selective,
        ),
      ),
    );
  }
  for (final SharedRcdResult rcd in result.sharedRcds) {
    slots.add(
      ApparatusSlot(
        id: rcd.id,
        title: 'УЗО группы линий ${rcd.circuitIds.length}',
        requirement: ApparatusRequirement(
          function: ApparatusFunction.rcd,
          poles: rcd.poles,
          ratedCurrentA: rcd.ratedA,
          leakageMa: rcd.residualMa,
          rcdType: RcdType.fromKey(rcd.type),
        ),
      ),
    );
  }

  for (final CircuitResult c in result.circuits) {
    final ProtectionResult p = c.protection;
    final three = c.phases == 3;
    final title = '№${c.number} ${c.name}';
    final RcdType? rcdType = p.rcd == null ? null : RcdType.fromKey(p.rcd!.type);
    switch (p.device) {
      case ProtectionDevice.rcbo:
        slots.add(
          ApparatusSlot(
            id: '${c.id}/rcbo',
            title: title,
            circuitId: c.id,
            requirement: ApparatusRequirement(
              function: ApparatusFunction.rcbo,
              poles: three ? 4 : 2,
              ratedCurrentA: p.breakerA,
              curve: p.curve,
              leakageMa: p.rcd!.residualMa,
              rcdType: rcdType,
            ),
          ),
        );
      case ProtectionDevice.mcb:
      case ProtectionDevice.mcbAndRcd:
      case ProtectionDevice.mcbUnderGroupRcd:
        slots.add(
          ApparatusSlot(
            id: '${c.id}/mcb',
            title: title,
            circuitId: c.id,
            requirement: ApparatusRequirement(
              function: ApparatusFunction.mcb,
              poles: three ? 3 : 1,
              ratedCurrentA: p.breakerA,
              curve: p.curve,
            ),
          ),
        );
        if (p.device == ProtectionDevice.mcbAndRcd) {
          slots.add(
            ApparatusSlot(
              id: '${c.id}/rcd',
              title: '$title — УЗО',
              circuitId: c.id,
              requirement: ApparatusRequirement(
                function: ApparatusFunction.rcd,
                poles: three ? 4 : 2,
                ratedCurrentA: p.rcd!.ratedA ?? p.breakerA,
                leakageMa: p.rcd!.residualMa,
                rcdType: rcdType,
              ),
            ),
          );
        }
    }
  }
  return slots;
}

String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
