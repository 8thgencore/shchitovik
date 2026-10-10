import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';

/// Colour of a calculation status.
Color statusColor(BuildContext context, CalculationStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    CalculationStatus.passed => Colors.green.shade700,
    CalculationStatus.warning || CalculationStatus.requiresReview => Colors.amber.shade800,
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
    final (icon, color) = switch (status) {
      CheckStatus.passed => (Icons.check, Colors.green.shade700),
      CheckStatus.warning => (Icons.warning_amber, Colors.amber.shade800),
      CheckStatus.failed => (Icons.close, scheme.error),
      CheckStatus.notEvaluated => (Icons.remove, scheme.outline),
    };
    return Icon(icon, color: color, size: 20);
  }
}
