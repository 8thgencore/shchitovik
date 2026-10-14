import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';

/// Tone of a calculation status.
UiTone statusTone(CalculationStatus status) => switch (status) {
  CalculationStatus.passed => UiTone.success,
  CalculationStatus.warning || CalculationStatus.requiresReview => UiTone.warning,
  CalculationStatus.preliminary => UiTone.neutral,
  CalculationStatus.failed => UiTone.danger,
};

/// Attention stripe for a row with this status; `null` when nothing needs attention.
UiTone? statusStripe(CalculationStatus status) => switch (status) {
  CalculationStatus.failed => UiTone.danger,
  CalculationStatus.warning || CalculationStatus.requiresReview => UiTone.warning,
  _ => null,
};

/// Icon of a calculation status with its name as the tooltip.
class StatusIcon extends StatelessWidget {
  const StatusIcon(this.status, {super.key});

  /// Status.
  final CalculationStatus status;

  @override
  Widget build(BuildContext context) => UiStatusIcon(
    tone: statusTone(status),
    label: status.label,
    icon: switch (status) {
      CalculationStatus.requiresReview => UiIcons.help,
      CalculationStatus.preliminary => UiIcons.pending,
      _ => null,
    },
  );
}

/// Badge with the name of a calculation status.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  /// Status.
  final CalculationStatus status;

  @override
  Widget build(BuildContext context) => UiBadge(label: status.label, tone: statusTone(status));
}

/// Icon of a check status.
class CheckStatusIcon extends StatelessWidget {
  const CheckStatusIcon(this.status, {super.key});

  /// Status.
  final CheckStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    CheckStatus.passed => UiStatusIcon(tone: UiTone.success, label: status.label, size: 18),
    CheckStatus.warning => UiStatusIcon(tone: UiTone.warning, label: status.label, size: 18),
    CheckStatus.failed => UiStatusIcon(tone: UiTone.danger, label: status.label, size: 18),
    CheckStatus.notEvaluated => UiStatusIcon(
      tone: UiTone.neutral,
      label: status.label,
      icon: UiIcons.notEvaluated,
      size: 18,
    ),
  };
}
