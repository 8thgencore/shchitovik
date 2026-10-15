import 'package:common_ui/src/tokens/ui_colors.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_pressable.dart';
import 'package:common_ui/src/widgets/ui_progress.dart';
import 'package:material_ui/material_ui.dart';

/// Visual weight of a [UiButton].
enum UiButtonVariant() {
  /// Ink fill: the one main action of a screen or bar.
  primary,

  /// Outlined: alternative actions, «Назад».
  secondary,

  /// Text only: low-emphasis actions inside cards.
  ghost,

  /// Red fill: confirms a destructive action.
  danger,
}

/// Button with a verb-first label, optional icon and a busy state.
class UiButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.variant = UiButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.busy = false,
    this.expand = false,
    this.small = false,
    this.autofocus = false,
    super.key,
  });

  /// Outlined button.
  const new secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.busy = false,
    this.expand = false,
    this.small = false,
    this.autofocus = false,
    super.key,
  }) : variant = UiButtonVariant.secondary;

  /// Text button.
  const new ghost({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.busy = false,
    this.expand = false,
    this.small = false,
    this.autofocus = false,
    super.key,
  }) : variant = UiButtonVariant.ghost;

  /// Destructive button.
  const new danger({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.busy = false,
    this.expand = false,
    this.small = false,
    this.autofocus = false,
    super.key,
  }) : variant = UiButtonVariant.danger;

  /// Label: a verb, sentence case.
  final String label;

  /// Action; `null` disables the button.
  final VoidCallback? onPressed;

  /// Visual weight.
  final UiButtonVariant variant;

  /// Icon before the label.
  final IconData? icon;

  /// Icon after the label («Далее →»).
  final IconData? trailingIcon;

  /// Shows a spinner instead of [icon] and ignores taps.
  final bool busy;

  /// Fill the available width.
  final bool expand;

  /// 36 px tall on dense screens (the hit area stays 44).
  final bool small;

  /// Take focus on first build («Отмена» in confirmations).
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return UiPressable(
      onPressed: onPressed == null
          ? null
          : () {
              if (!busy) onPressed!();
            },
      autofocus: autofocus,
      builder: (context, state) {
        final (Color background, Color foreground, Color? border) = _colors(c, state);
        final StatelessWidget? iconWidget = busy
            ? UiSpinner(size: UiSize.iconSmall, color: foreground)
            : icon == null
            ? null
            : Icon(icon, size: UiSize.iconSmall, color: foreground);
        final content = Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null) ...[iconWidget, const SizedBox(width: UiSpace.s)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiTextStyles.button.copyWith(color: foreground),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: UiSpace.s),
              Icon(trailingIcon, size: UiSize.iconSmall, color: foreground),
            ],
          ],
        );
        return SizedBox(
          height: UiSize.control,
          child: Center(
            widthFactor: 1,
            child: UiFocusRing(
              visible: state.focused,
              child: AnimatedContainer(
                duration: UiMotion.of(context, UiMotion.fast),
                height: small ? UiSize.controlSmall : UiSize.control,
                padding: EdgeInsets.symmetric(
                  horizontal: variant == UiButtonVariant.ghost
                      ? UiSpace.m
                      : small
                      ? UiSpace.m
                      : UiSpace.l,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: UiRadius.controlAll,
                  border: border == null ? null : Border.all(color: border),
                ),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }

  (Color background, Color foreground, Color? border) _colors(UiColors c, UiPressState s) {
    if (!s.enabled) {
      return switch (variant) {
        UiButtonVariant.ghost => (const Color(0x00000000), c.textMuted, null),
        UiButtonVariant.secondary => (c.surface, c.textMuted, c.border),
        _ => (c.sunken, c.textMuted, null),
      };
    }
    final emphasis = s.pressed ? .16 : (s.hovered ? .08 : 0.0);
    Color tint(Color base, Color over) =>
        emphasis == 0 ? base : Color.alphaBlend(over.withValues(alpha: emphasis), base);
    return switch (variant) {
      UiButtonVariant.primary => (tint(c.primary, c.onPrimary), c.onPrimary, null),
      UiButtonVariant.danger => (tint(c.danger, c.onDanger), c.onDanger, null),
      UiButtonVariant.secondary => (
        s.hovered || s.pressed ? tint(c.sunken, c.text) : c.surface,
        c.text,
        c.borderStrong,
      ),
      UiButtonVariant.ghost => (
        s.hovered || s.pressed ? tint(c.accentSoft, c.accent) : const Color(0x00000000),
        c.accentText,
        null,
      ),
    };
  }
}

/// Square icon-only button; [tooltip] is required and doubles as the accessible label.
///
/// The tooltip shows on hover, long press and keyboard focus.
class const UiIconButton({
  /// Icon.
  required final IconData icon,

  /// Tooltip and accessible label: a verb («Сохранить PDF»).
  required final String tooltip,

  /// Action; `null` disables the button.
  required final VoidCallback? onPressed,

  /// Shows a spinner instead of the icon.
  final bool busy = false,

  /// Icon colour; defaults to the text colour.
  final Color? color,
  super.key,
}) extends StatefulWidget {
  @override
  State<UiIconButton> createState() => _UiIconButtonState();
}

class _UiIconButtonState() extends State<UiIconButton> {
  final _tooltip = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final VoidCallback? onPressed = widget.onPressed;
    return Tooltip(
      key: _tooltip,
      message: widget.tooltip,
      excludeFromSemantics: true,
      child: UiPressable(
        onPressed: onPressed == null
            ? null
            : () {
                if (!widget.busy) onPressed();
              },
        semanticLabel: widget.tooltip,
        onFocusHighlight: (focused) {
          if (focused) {
            _tooltip.currentState?.ensureTooltipVisible();
          } else {
            Tooltip.dismissAllToolTips();
          }
        },
        builder: (context, state) {
          final Color foreground = state.enabled ? (widget.color ?? c.text) : c.textMuted;
          return UiFocusRing(
            visible: state.focused,
            inset: true,
            child: AnimatedContainer(
              duration: UiMotion.of(context, UiMotion.fast),
              width: UiSize.control,
              height: UiSize.control,
              decoration: BoxDecoration(
                color: state.pressed
                    ? c.border
                    : state.hovered
                    ? c.sunken
                    : const Color(0x00000000),
                borderRadius: UiRadius.controlAll,
              ),
              alignment: Alignment.center,
              child: widget.busy
                  ? UiSpinner(size: UiSize.iconSmall, color: foreground)
                  : Icon(widget.icon, size: UiSize.icon, color: foreground),
            ),
          );
        },
      ),
    );
  }
}
