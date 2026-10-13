import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';
import 'package:shchitovik/src/widget/status_colors.dart';

/// Colour of a calculation status.
Color statusColor(BuildContext context, CalculationStatus status) {
  final scheme = Theme.of(context).colorScheme;
  final colors = StatusColors.of(context);
  return switch (status) {
    CalculationStatus.passed => colors.success,
    CalculationStatus.warning || CalculationStatus.requiresReview => colors.warning,
    CalculationStatus.preliminary => scheme.outline,
    CalculationStatus.failed => scheme.error,
  };
}

/// Icon and colour of a calculation status.
class StatusIcon extends StatelessWidget {
  const StatusIcon(this.status, {super.key});

  /// Status.
  final CalculationStatus status;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status) {
      CalculationStatus.passed => Icons.check_circle,
      CalculationStatus.warning => Icons.info,
      CalculationStatus.requiresReview => Icons.help,
      CalculationStatus.preliminary => Icons.pending,
      CalculationStatus.failed => Icons.error,
    };
    return Tooltip(
      message: status.label,
      child: Icon(icon, color: statusColor(context, status)),
    );
  }
}

/// Icon of a check status.
class CheckStatusIcon extends StatelessWidget {
  const CheckStatusIcon(this.status, {super.key});

  /// Status.
  final CheckStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = StatusColors.of(context);
    final (icon, color) = switch (status) {
      CheckStatus.passed => (Icons.check, colors.success),
      CheckStatus.warning => (Icons.warning_amber, colors.warning),
      CheckStatus.failed => (Icons.close, scheme.error),
      CheckStatus.notEvaluated => (Icons.remove, scheme.outline),
    };
    return Icon(icon, color: color, size: 20);
  }
}
