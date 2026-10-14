import 'package:flutter/widgets.dart';

/// Spacing scale: 4pt for micro gaps, 8pt for layout.
abstract final class UiSpace {
  /// 4.
  static const xs = 4.0;

  /// 8.
  static const s = 8.0;

  /// 12.
  static const m = 12.0;

  /// 16: side gutter on phones, card padding.
  static const l = 16.0;

  /// 24: gutter on wide screens, gap between sections.
  static const xl = 24.0;

  /// 32.
  static const xxl = 32.0;

  /// 48.
  static const xxxl = 48.0;
}

/// Corner radii: sharp, like a drawing.
abstract final class UiRadius {
  /// Controls: buttons, inputs, badges.
  static const control = 3.0;

  /// Cards, sheets, menus.
  static const card = 4.0;

  /// [control] as a border radius.
  static const controlAll = BorderRadius.all(Radius.circular(control));

  /// [card] as a border radius.
  static const cardAll = BorderRadius.all(Radius.circular(card));
}

/// Fixed sizes of controls.
abstract final class UiSize {
  /// Minimum touch target and the height of regular controls.
  static const control = 44.0;

  /// Height of small controls on dense screens (the hit area stays [control]).
  static const controlSmall = 36.0;

  /// Regular icon.
  static const icon = 20.0;

  /// Icon inside buttons and badges.
  static const iconSmall = 16.0;

  /// Hairline.
  static const hairline = 1.0;

  /// Keyboard focus ring.
  static const focusRing = 2.0;
}

/// Motion durations; everything respects «reduce motion» via [UiMotion.of].
abstract final class UiMotion {
  /// Hover, press, toggles.
  static const fast = Duration(milliseconds: 150);

  /// Expanding sections, chevrons.
  static const medium = Duration(milliseconds: 200);

  /// Easing for state changes.
  static const curve = Curves.easeOutCubic;

  /// [duration], or zero when the platform asks to reduce motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : duration;
}

/// Window breakpoints.
abstract final class UiBreakpoints {
  /// From this width the app uses the expanded layout: sidebar, tables, two columns.
  static const expanded = 840.0;

  /// From this content width two columns fit side by side.
  static const twoColumns = 960.0;

  /// Maximum width of page content; chrome stays full width.
  static const contentMax = 1280.0;

  /// Maximum width of a form column.
  static const formMax = 720.0;
}

/// Window size helpers.
extension UiWindowSize on BuildContext {
  /// Whether the window is wide enough for the expanded layout (desktop, tablet landscape).
  bool get isExpandedLayout => MediaQuery.sizeOf(this).width >= UiBreakpoints.expanded;
}
