import 'package:flutter/material.dart';
import 'package:shchitovik/src/widget/status_colors.dart';

/// Light and dark themes of the app: navy and slate palette, IBM Plex Sans, flat bordered surfaces.
///
/// Decisions and contrast checks live in `design-system/shchitovik/MASTER.md`.
abstract final class AppTheme {
  /// Interface font family declared in `pubspec.yaml`.
  static const fontFamily = 'IBMPlexSans';

  /// Light theme.
  static final ThemeData light = _theme(
    ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A5F)).copyWith(
      primary: const Color(0xFF1E3A5F),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDBE5F1),
      onPrimaryContainer: const Color(0xFF1E3A5F),
      secondary: const Color(0xFF2563EB),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDBEAFE),
      onSecondaryContainer: const Color(0xFF1E3A8A),
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: const Color(0xFFF8FAFC),
      onSurface: const Color(0xFF0F172A),
      onSurfaceVariant: const Color(0xFF475569),
      outline: const Color(0xFF64748B),
      outlineVariant: const Color(0xFFE2E8F0),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF1F5F9),
      surfaceContainer: const Color(0xFFEEF2F6),
      surfaceContainerHigh: const Color(0xFFE2E8F0),
      surfaceContainerHighest: const Color(0xFFCBD5E1),
    ),
    status: StatusColors.light,
  );

  /// Dark theme.
  static final ThemeData dark = _theme(
    ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A5F), brightness: Brightness.dark).copyWith(
      primary: const Color(0xFF93C5FD),
      onPrimary: const Color(0xFF0F172A),
      primaryContainer: const Color(0xFF1E3A5F),
      onPrimaryContainer: const Color(0xFFDBE5F1),
      secondary: const Color(0xFF60A5FA),
      onSecondary: const Color(0xFF0F172A),
      secondaryContainer: const Color(0xFF1E3A8A),
      onSecondaryContainer: const Color(0xFFDBEAFE),
      error: const Color(0xFFF87171),
      onError: const Color(0xFF450A0A),
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFEE2E2),
      surface: const Color(0xFF0F172A),
      onSurface: const Color(0xFFF1F5F9),
      onSurfaceVariant: const Color(0xFF94A3B8),
      outline: const Color(0xFF7C8BA1),
      outlineVariant: const Color(0xFF334155),
      surfaceContainerLowest: const Color(0xFF0B1220),
      surfaceContainerLow: const Color(0xFF162033),
      surfaceContainer: const Color(0xFF1E293B),
      surfaceContainerHigh: const Color(0xFF273449),
      surfaceContainerHighest: const Color(0xFF334155),
    ),
    status: StatusColors.dark,
  );

  static ThemeData _theme(ColorScheme scheme, {required StatusColors status}) => ThemeData(
    colorScheme: scheme,
    fontFamily: fontFamily,
    extensions: [status],
    // Raised surfaces separate by a 1px border, not by shadow or tint.
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.brightness == Brightness.light
          ? scheme.surfaceContainerLowest
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
    ),
  );
}
