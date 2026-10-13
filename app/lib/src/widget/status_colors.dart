import 'package:flutter/material.dart';

/// Colours of calculation and check statuses that the Material colour scheme does not have.
///
/// Both pairs keep at least 4:1 against every surface of their theme (WCAG 2.1 AA asks 3:1 for
/// graphical objects). Failures use [ColorScheme.error].
@immutable
final class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({required this.success, required this.warning});

  /// Light theme.
  static const light = StatusColors(success: Color(0xFF2E7D32), warning: Color(0xFFA15C00));

  /// Dark theme.
  static const dark = StatusColors(success: Color(0xFF81C784), warning: Color(0xFFFFD54F));

  /// Passed check or calculation.
  final Color success;

  /// Warning or a result that needs review.
  final Color warning;

  /// Status colours of the current theme.
  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  StatusColors copyWith({Color? success, Color? warning}) =>
      StatusColors(success: success ?? this.success, warning: warning ?? this.warning);

  @override
  StatusColors lerp(StatusColors? other, double t) => other == null
      ? this
      : StatusColors(
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
        );
}
