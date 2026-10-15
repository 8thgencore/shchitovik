import 'package:common_ui/src/tokens/ui_colors.dart';
import 'package:common_ui/src/tokens/ui_icons.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Meaning of a status mark. Colour is never the only signal: tones also differ in icon or text.
enum UiTone() {
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
class const UiBadge({
  /// Text: what the status means («Норма», «1 ошибка»).
  required final String label,

  /// Tone.
  required final UiTone tone,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color color = tone.color(context.uiColors);
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
class const UiStatusDot({
  /// Tone.
  required final UiTone tone,

  /// Side.
  final double size = 7,
  super.key,
}) extends StatelessWidget {
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
class const UiStatusIcon({
  /// Tone.
  required final UiTone tone,

  /// Status name: tooltip and accessible label.
  required final String label,

  /// Icon; defaults to the tone icon.
  final IconData? icon,

  /// Icon size.
  final double? size,
  super.key,
}) extends StatelessWidget {
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
class const UiNotice({
  /// Text.
  required final String message,

  /// Tone.
  final UiTone tone = UiTone.neutral,

  /// Bold first line.
  final String? title,

  /// Action under the text: a ghost button.
  final Widget? action,

  /// Draw on a tinted panel.
  final bool boxed = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
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
