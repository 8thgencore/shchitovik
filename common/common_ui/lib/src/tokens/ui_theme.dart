import 'package:common_ui/src/tokens/ui_colors.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:flutter/material.dart';

/// Light and dark [ThemeData] of the «Чертёж» design system.
///
/// The app draws its own widgets from `common_ui`; this theme maps the same tokens onto the
/// Material widgets that stay underneath (text input, menus, dialogs, tooltips, snack bars),
/// so nothing falls back to Material defaults.
abstract final class UiTheme {
  /// Light theme.
  static final ThemeData light = _build(UiColors.light, Brightness.light);

  /// Dark theme.
  static final ThemeData dark = _build(UiColors.dark, Brightness.dark);

  static ThemeData _build(UiColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.text,
      secondary: c.accent,
      onSecondary: c.onPrimary,
      tertiary: c.accentText,
      onTertiary: c.onPrimary,
      error: c.danger,
      onError: c.onDanger,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.text,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.sunken,
      surfaceContainerHighest: c.sunken,
      outline: c.borderStrong,
      outlineVariant: c.border,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: c.text,
      onInverseSurface: c.canvas,
      inversePrimary: c.accent,
      surfaceTint: const Color(0x00000000),
    );

    TextStyle ink(TextStyle style, [Color? color]) => style.copyWith(color: color ?? c.text);
    final textTheme = TextTheme(
      displayLarge: ink(UiTextStyles.display),
      displayMedium: ink(UiTextStyles.display),
      displaySmall: ink(UiTextStyles.display),
      headlineLarge: ink(UiTextStyles.display),
      headlineMedium: ink(UiTextStyles.title),
      headlineSmall: ink(UiTextStyles.title),
      titleLarge: ink(UiTextStyles.title),
      titleMedium: ink(UiTextStyles.heading),
      titleSmall: ink(UiTextStyles.heading),
      bodyLarge: ink(UiTextStyles.body),
      bodyMedium: ink(UiTextStyles.body),
      bodySmall: ink(UiTextStyles.bodySmall, c.textMuted),
      labelLarge: ink(UiTextStyles.button),
      labelMedium: ink(UiTextStyles.caption),
      labelSmall: ink(UiTextStyles.caption, c.textMuted),
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: UiRadius.cardAll,
      side: BorderSide(color: c.border),
    );
    final overlayShadow = [
      BoxShadow(
        color: const Color(0xFF000000).withValues(alpha: brightness == Brightness.dark ? .4 : .06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
    final inputBorder = OutlineInputBorder(
      borderRadius: UiRadius.controlAll,
      borderSide: BorderSide(color: c.borderStrong),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: UiFonts.sansFamily,
      textTheme: textTheme,
      extensions: [c],
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.surface,
      dividerColor: c.border,
      // States are drawn by the widgets themselves: tints, not ripples.
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x00000000),
      hoverColor: c.sunken,
      focusColor: c.accentSoft,
      iconTheme: IconThemeData(color: c.text, size: UiSize.icon),
      dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.text,
        selectionColor: c.accent.withValues(alpha: .25),
        selectionHandleColor: c.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: UiSpace.m, vertical: 11),
        hintStyle: UiTextStyles.body.copyWith(color: c.textMuted),
        helperStyle: UiTextStyles.caption.copyWith(color: c.textMuted),
        errorStyle: UiTextStyles.caption.copyWith(color: c.danger),
        suffixStyle: UiTextStyles.value.copyWith(color: c.textMuted),
        prefixIconColor: c.textMuted,
        suffixIconColor: c.textMuted,
        helperMaxLines: 3,
        errorMaxLines: 3,
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.border)),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: c.focus, width: UiSize.focusRing),
        ),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: c.danger)),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: c.danger, width: UiSize.focusRing),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.text, borderRadius: UiRadius.controlAll),
        textStyle: UiTextStyles.caption.copyWith(color: c.canvas),
        padding: const EdgeInsets.symmetric(horizontal: UiSpace.s, vertical: 6),
        waitDuration: const Duration(milliseconds: 400),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Color(0x00000000)),
          elevation: const WidgetStatePropertyAll(4),
          shadowColor: WidgetStatePropertyAll(overlayShadow.first.color),
          side: WidgetStatePropertyAll(BorderSide(color: c.border)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: UiRadius.cardAll),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: UiSpace.xs)),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(160, UiSize.control)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: UiSpace.l)),
          textStyle: const WidgetStatePropertyAll(UiTextStyles.body),
          foregroundColor: WidgetStatePropertyAll(c.text),
          iconColor: WidgetStatePropertyAll(c.text),
          iconSize: const WidgetStatePropertyAll(UiSize.iconSmall),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused) || s.contains(WidgetState.hovered)
                ? c.sunken
                : null,
          ),
          overlayColor: const WidgetStatePropertyAll(Color(0x00000000)),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        shape: cardShape,
        titleTextStyle: ink(UiTextStyles.title),
        contentTextStyle: ink(UiTextStyles.body),
        barrierColor: const Color(0xFF000000).withValues(alpha: .45),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        surfaceTintColor: const Color(0x00000000),
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: const Color(0xFF000000).withValues(alpha: .45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        dragHandleColor: c.borderStrong,
        dragHandleSize: const Size(36, 4),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text,
        contentTextStyle: UiTextStyles.bodySmall.copyWith(color: c.canvas),
        actionTextColor: c.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: UiRadius.controlAll),
        insetPadding: const EdgeInsets.all(UiSpace.l),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(c.borderStrong.withValues(alpha: .6)),
        radius: const Radius.circular(2),
        thickness: const WidgetStatePropertyAll(6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.sunken,
        circularTrackColor: const Color(0x00000000),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: c.surface,
        surfaceTintColor: const Color(0x00000000),
        shape: cardShape,
      ),
    );
  }
}

/// Theme shortcuts.
extension UiThemeContext on BuildContext {
  /// Colour roles of the current theme.
  UiColors get uiColors => UiColors.of(this);
}
