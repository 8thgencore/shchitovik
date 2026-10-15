import 'dart:math' as math;

import 'package:common_ui/common_ui.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 contrast ratio of two opaque colours.
double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

void main() {
  for (final (name, c) in [('light', UiColors.light), ('dark', UiColors.dark)]) {
    group('$name theme', () {
      final Map<String, Color> grounds = {
        'canvas': c.canvas,
        'surface': c.surface,
        'sunken': c.sunken,
      };

      // Text roles: 4.5:1 (WCAG 1.4.3) on every ground they appear on.
      final Map<String, Color> text = {
        'text': c.text,
        'textMuted': c.textMuted,
        'accentText': c.accentText,
        'success': c.success,
        'warning': c.warning,
        'danger': c.danger,
      };
      for (final MapEntry(key: role, value: fg) in text.entries) {
        for (final MapEntry(key: ground, value: bg) in grounds.entries) {
          test('$role on $ground ≥ 4.5', () {
            expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
          });
        }
      }

      // Component boundaries and graphics: 3:1 (WCAG 1.4.11).
      for (final (role, fg) in [('borderStrong', c.borderStrong), ('accent', c.accent)]) {
        for (final MapEntry(key: ground, value: bg) in grounds.entries) {
          test('$role on $ground ≥ 3', () {
            expect(contrast(fg, bg), greaterThanOrEqualTo(3));
          });
        }
      }

      // Content on filled controls.
      for (final (pair, fg, bg) in [
        ('onPrimary on primary', c.onPrimary, c.primary),
        ('onDanger on danger', c.onDanger, c.danger),
        ('canvas on text (tooltip, toast)', c.canvas, c.text),
      ]) {
        test('$pair ≥ 4.5', () {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }

      // Status text on its own tint (badges, notices).
      for (final UiTone tone in UiTone.values) {
        test('${tone.name} on its tint ≥ 4.5', () {
          expect(contrast(tone.color(c), tone.soft(c)), greaterThanOrEqualTo(4.5));
        });
      }
    });
  }
}
