import 'package:material_ui/material_ui.dart';

/// Colour roles of the «Чертёж» design system: ink on paper, signal orange for the current
/// element, three status colours.
///
/// Widgets take colours only from these roles (`context.uiColors`), never raw values.
/// Pairs meet WCAG 2.1 AA contrast in both themes.
@immutable
final class const UiColors({
  /// Page background (level 0).
  required final Color canvas,

  /// Cards, bars, sheets (level 1).
  required final Color surface,

  /// Recessed areas: segmented track, table header, hover.
  required final Color sunken,

  /// Hairlines between rows and around cards.
  required final Color border,

  /// Borders of inputs and controls, at least 3:1 against [surface] and [canvas].
  required final Color borderStrong,

  /// Body text and icons.
  required final Color text,

  /// Secondary text, labels, units.
  required final Color textMuted,

  /// Primary action fill.
  required final Color primary,

  /// Content on [primary].
  required final Color onPrimary,

  /// Current step, selection, focus ring. Graphics only; text uses [accentText].
  required final Color accent,

  /// Accent as text, at least 4.5:1 against [surface].
  required final Color accentText,

  /// Tint behind selected or focused elements.
  required final Color accentSoft,

  /// Passed check. Never an action colour.
  required final Color success,

  /// Tint for [success].
  required final Color successSoft,

  /// Result that needs review.
  required final Color warning,

  /// Tint for [warning].
  required final Color warningSoft,

  /// Failure and destructive actions.
  required final Color danger,

  /// Tint for [danger].
  required final Color dangerSoft,

  /// Content on [danger].
  required final Color onDanger,
}) extends ThemeExtension<UiColors> {
  /// Light theme: paper and ink, neutral greys without tint.
  static const light = UiColors(
    canvas: Color(0xFFF4F4F4),
    surface: Color(0xFFFFFFFF),
    sunken: Color(0xFFEBEBEB),
    border: Color(0xFFD9D9D9),
    borderStrong: Color(0xFF808080),
    text: Color(0xFF0A0A0A),
    textMuted: Color(0xFF525252),
    primary: Color(0xFF0A0A0A),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFD9480F),
    accentText: Color(0xFFB03A0B),
    accentSoft: Color(0xFFFBE7DC),
    success: Color(0xFF1B6E34),
    successSoft: Color(0xFFE3F1E6),
    warning: Color(0xFF95590A),
    warningSoft: Color(0xFFF7ECD9),
    danger: Color(0xFFC42B1C),
    dangerSoft: Color(0xFFF9E1DE),
    onDanger: Color(0xFFFFFFFF),
  );

  /// Dark theme: light ink on near-black, neutral greys without tint.
  static const dark = UiColors(
    canvas: Color(0xFF0A0A0A),
    surface: Color(0xFF141414),
    sunken: Color(0xFF1F1F1F),
    border: Color(0xFF2A2A2A),
    borderStrong: Color(0xFF737373),
    text: Color(0xFFF5F5F5),
    textMuted: Color(0xFFA3A3A3),
    primary: Color(0xFFF5F5F5),
    onPrimary: Color(0xFF0A0A0A),
    accent: Color(0xFFFF7B36),
    accentText: Color(0xFFFF9157),
    accentSoft: Color(0xFF3A2216),
    success: Color(0xFF5BC984),
    successSoft: Color(0xFF15301F),
    warning: Color(0xFFE8B651),
    warningSoft: Color(0xFF362A12),
    danger: Color(0xFFFF6E61),
    dangerSoft: Color(0xFF3B1A17),
    onDanger: Color(0xFF0A0A0A),
  );

  /// Keyboard focus ring.
  Color get focus => accent;

  /// Colours of the current theme.
  static UiColors of(BuildContext context) =>
      Theme.of(context).extension<UiColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  UiColors copyWith() => this;

  @override
  UiColors lerp(UiColors? other, double t) {
    if (other == null) return this;
    final a = this;
    final UiColors b = other;
    Color l(Color Function(UiColors) f) => Color.lerp(f(a), f(b), t)!;
    return UiColors(
      canvas: l((c) => c.canvas),
      surface: l((c) => c.surface),
      sunken: l((c) => c.sunken),
      border: l((c) => c.border),
      borderStrong: l((c) => c.borderStrong),
      text: l((c) => c.text),
      textMuted: l((c) => c.textMuted),
      primary: l((c) => c.primary),
      onPrimary: l((c) => c.onPrimary),
      accent: l((c) => c.accent),
      accentText: l((c) => c.accentText),
      accentSoft: l((c) => c.accentSoft),
      success: l((c) => c.success),
      successSoft: l((c) => c.successSoft),
      warning: l((c) => c.warning),
      warningSoft: l((c) => c.warningSoft),
      danger: l((c) => c.danger),
      dangerSoft: l((c) => c.dangerSoft),
      onDanger: l((c) => c.onDanger),
    );
  }
}
