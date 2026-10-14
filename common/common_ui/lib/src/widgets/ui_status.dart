import 'package:common_ui/src/tokens/ui_colors.dart';
import 'package:common_ui/src/tokens/ui_icons.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:flutter/material.dart';

/// Meaning of a status mark. Colour is never the only signal: tones also differ in icon or text.
enum UiTone {
  /// Nothing to report, preliminary.
  neutral,

  /// Current or selected.
  accent,

  /// Passed.
  success,

  /// Needs review.
  warning,

  /// Failed.
  danger;

  /// Foreground colour of the tone.
  Color color(UiColors c) => switch (this) {
    neutral => c.textMuted,
    accent => c.accentText,
    success => c.success,
    warning => c.warning,
    danger => c.danger,
  };

  /// Tint behind the tone.
  Color soft(UiColors c) => switch (this) {
    neutral => c.sunken,
    accent => c.accentSoft,
    success => c.successSoft,
    warning => c.warningSoft,
    danger => c.dangerSoft,
  };

  /// Default icon of the tone.
  IconData get icon => switch (this) {
    neutral => UiIcons.pending,
    accent => UiIcons.info,
    success => UiIcons.success,
    warning => UiIcons.warning,
    danger => UiIcons.danger,
  };
}

/// Outlined stamp-like badge: square marker and an upper-case mono label.
class UiBadge extends StatelessWidget {
  const UiBadge({required this.label, required this.tone, super.key});

  /// Text: what the status means («Норма», «1 ошибка»).
  final String label;

  /// Tone.
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone.color(context.uiColors);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: UiRadius.controlAll,
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: UiSpace.s, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UiStatusDot(tone: tone),
            const SizedBox(width: UiSpace.s),
            Flexible(
              child: Text(
                label.toUpperCase(),
                semanticsLabel: label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiTextStyles.label.copyWith(color: color, letterSpacing: .4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small square status marker.
class UiStatusDot extends StatelessWidget {
  const UiStatusDot({required this.tone, this.size = 7, super.key});

  /// Tone.
  final UiTone tone;

  /// Side.
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: tone.color(context.uiColors),
        borderRadius: const BorderRadius.all(Radius.circular(1)),
      ),
    ),
  );
}

/// Status icon with a tooltip that names it.
class UiStatusIcon extends StatelessWidget {
  const UiStatusIcon({required this.tone, required this.label, this.icon, this.size, super.key});

  /// Tone.
  final UiTone tone;

  /// Status name: tooltip and accessible label.
  final String label;

  /// Icon; defaults to the tone icon.
  final IconData? icon;

  /// Icon size.
  final double? size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Icon(
      icon ?? tone.icon,
      size: size ?? UiSize.icon,
      color: tone.color(context.uiColors),
      semanticLabel: label,
    ),
  );
}

/// Inline message with a tone icon; [boxed] puts it on a tinted panel with a side stripe.
class UiNotice extends StatelessWidget {
  const UiNotice({
    required this.message,
    this.tone = UiTone.neutral,
    this.title,
    this.action,
    this.boxed = false,
    super.key,
  });

  /// Text.
  final String message;

  /// Bold first line.
  final String? title;

  /// Tone.
  final UiTone tone;

  /// Action under the text: a ghost button.
  final Widget? action;

  /// Draw on a tinted panel.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(tone.icon, size: 18, color: tone.color(c)),
        ),
        const SizedBox(width: UiSpace.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: UiTextStyles.bodySmall.copyWith(
                    color: c.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(message, style: UiTextStyles.bodySmall.copyWith(color: c.text)),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.only(top: UiSpace.xs),
                  child: action,
                ),
            ],
          ),
        ),
      ],
    );
    if (!boxed) return content;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.soft(c),
        borderRadius: UiRadius.controlAll,
        border: Border(left: BorderSide(color: tone.color(c), width: 3)),
      ),
      child: Padding(padding: const EdgeInsets.all(UiSpace.m), child: content),
    );
  }
}
