import 'package:flutter/painting.dart';

/// Font families bundled with the package.
abstract final class UiFonts {
  /// Interface text: IBM Plex Sans.
  static const sans = 'IBMPlexSans';

  /// Values, units, labels: IBM Plex Mono.
  static const mono = 'IBMPlexMono';

  /// Package that declares the fonts.
  static const package = 'common_ui';

  /// [sans] as a theme font family (fonts from a package carry its prefix).
  static const sansFamily = 'packages/$package/$sans';

  /// Plex Mono has no Greek: Δ, φ and the like come from Plex Sans.
  ///
  /// [TextStyle] prefixes fallbacks with the package itself, so the bare family name goes here.
  static const monoFallback = [sans];
}

/// Type scale of the «Чертёж» design system.
///
/// Text in Plex Sans, every number with a unit in Plex Mono (digits line up in columns).
/// Weights 400, 500, 600 only; nothing below 12. Styles carry no colour: widgets take it
/// from `UiColors` or inherit it from `DefaultTextStyle`.
abstract final class UiTextStyles {
  /// Page title on wide screens, the estimate total.
  static const display = TextStyle(
    fontFamily: UiFonts.sans,
    package: UiFonts.package,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  /// Screen and sheet title.
  static const title = TextStyle(
    fontFamily: UiFonts.sans,
    package: UiFonts.package,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  /// Card and section heading.
  static const heading = TextStyle(
    fontFamily: UiFonts.sans,
    package: UiFonts.package,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  /// Body text, list titles, inputs.
  static const body = TextStyle(
    fontFamily: UiFonts.sans,
    package: UiFonts.package,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Body text with emphasis: list row titles.
  static const bodyStrong = TextStyle(
    fontFamily: UiFonts.sans,
    package: UiFonts.package,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// Secondary text, row subtitles, table cells.
  static const bodySmall = TextStyle(
    fontFamily: UiFonts.sans,
    package: UiFonts.package,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  /// Captions, helper and error text, field labels.
  static const caption = TextStyle(
    fontFamily: UiFonts.sans,
    package: UiFonts.package,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  /// Button text.
  static const button = TextStyle(
    fontFamily: UiFonts.sans,
    package: UiFonts.package,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  /// Upper-case drawing-stamp label above values and groups.
  static const label = TextStyle(
    fontFamily: UiFonts.mono,
    package: UiFonts.package,
    fontFamilyFallback: UiFonts.monoFallback,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.7,
  );

  /// Value with a unit in text or tables.
  static const value = TextStyle(
    fontFamily: UiFonts.mono,
    package: UiFonts.package,
    fontFamilyFallback: UiFonts.monoFallback,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  /// Emphasised value: totals in rows.
  static const valueStrong = TextStyle(
    fontFamily: UiFonts.mono,
    package: UiFonts.package,
    fontFamilyFallback: UiFonts.monoFallback,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w600,
  );

  /// Reading of a metric tile.
  static const reading = TextStyle(
    fontFamily: UiFonts.mono,
    package: UiFonts.package,
    fontFamilyFallback: UiFonts.monoFallback,
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
  );

  /// Large reading: the estimate total.
  static const readingLarge = TextStyle(
    fontFamily: UiFonts.mono,
    package: UiFonts.package,
    fontFamilyFallback: UiFonts.monoFallback,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );
}
