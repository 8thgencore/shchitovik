import 'package:electrical_core/src/model/enums.dart';
import 'package:electrical_core/src/model/project_result.dart';
import 'package:norms_data/norms_data.dart';

/// Russian labels for reports and the UI.
extension ObjectTypeLabel on ObjectType {
  /// Label.
  String get label => switch (this) {
    ObjectType.apartment => 'Квартира',
    ObjectType.house => 'Частный дом',
    ObjectType.garageWorkshop => 'Гараж, мастерская',
    ObjectType.commercial => 'Коммерческое помещение',
  };
}

/// Russian labels.
extension SupplyPhasesLabel on SupplyPhases {
  /// Label.
  String get label => switch (this) {
    SupplyPhases.single => 'однофазный',
    SupplyPhases.three => 'трёхфазный',
  };
}

/// Russian labels.
extension PhaseLabel on Phase {
  /// Label.
  String get label => switch (this) {
    Phase.l1 => 'L1',
    Phase.l2 => 'L2',
    Phase.l3 => 'L3',
  };
}

/// Russian labels.
extension CalculationStatusLabel on CalculationStatus {
  /// Label.
  String get label => switch (this) {
    CalculationStatus.passed => 'проверено',
    CalculationStatus.warning => 'с замечаниями',
    CalculationStatus.requiresReview => 'требует проверки',
    CalculationStatus.preliminary => 'предварительно',
    CalculationStatus.failed => 'не проходит',
  };
}

/// Russian labels.
extension CheckStatusLabel on CheckStatus {
  /// Label.
  String get label => switch (this) {
    CheckStatus.passed => 'выполнено',
    CheckStatus.warning => 'замечание',
    CheckStatus.failed => 'не выполнено',
    CheckStatus.notEvaluated => 'не оценивалось',
  };
}

/// Russian labels.
extension ProtectionLabel on ProtectionResult {
  /// Short description like `Дифавтомат C16, 30 мА, тип A`.
  String get description {
    final String breaker = label;
    final RcdResult? rcd = this.rcd;
    return switch (device) {
      ProtectionDevice.mcb => 'Автомат $breaker',
      ProtectionDevice.rcbo => 'Дифавтомат $breaker, ${_n(rcd!.residualMa)} мА, тип ${rcd.type}',
      ProtectionDevice.mcbAndRcd =>
        'Автомат $breaker + УЗО ${_n(rcd!.ratedA ?? breakerA)} А, ${_n(rcd.residualMa)} мА, тип ${rcd.type}',
      ProtectionDevice.mcbUnderGroupRcd => 'Автомат $breaker (УЗО ${rcd?.groupId ?? 'группы'})',
    };
  }
}

/// Russian labels.
extension MaterialLabel on ConductorMaterial {
  /// Label.
  String get label => switch (this) {
    ConductorMaterial.copper => 'медь',
    ConductorMaterial.aluminium => 'алюминий',
  };
}

String _n(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString().replaceAll('.', ',');
