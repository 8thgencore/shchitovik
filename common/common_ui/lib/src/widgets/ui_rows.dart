import 'package:common_ui/src/tokens/ui_colors.dart';
import 'package:common_ui/src/tokens/ui_icons.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_pressable.dart';
import 'package:common_ui/src/widgets/ui_status.dart';
import 'package:material_ui/material_ui.dart';

/// Row of a list inside a card: optional number or icon, title, subtitle, trailing content.
///
/// A [stripe] tone marks rows that need attention with a 3px bar on the leading edge.
class const UiListRow({
  /// Title.
  required final String title,

  /// Secondary line.
  final String? subtitle,

  /// Number in the mono column («1», «№3»).
  final String? number,

  /// Leading widget: an icon.
  final Widget? leading,

  /// Trailing widget: a value, a badge, a menu.
  final Widget? trailing,

  /// Extra widget under the subtitle: a badge on phones.
  final Widget? below,

  /// Attention bar on the leading edge.
  final UiTone? stripe,

  /// Tap handler; makes the row interactive.
  final VoidCallback? onTap,

  /// Selected state (tinted).
  final bool selected = false,

  /// Show a chevron that hints at a detail page.
  final bool chevron = false,

  /// 44 px minimum instead of 56.
  final bool dense = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    Widget body(UiPressState? state) {
      final Color background = selected
          ? c.accentSoft
          : state != null && (state.hovered || state.pressed)
          ? c.sunken
          : const Color(0x00000000);
      return UiFocusRing(
        visible: state?.focused ?? false,
        inset: true,
        radius: BorderRadius.zero,
        child: AnimatedContainer(
          duration: UiMotion.of(context, UiMotion.fast),
          constraints: BoxConstraints(minHeight: dense ? UiSize.control : 56),
          decoration: BoxDecoration(
            color: background,
            border: stripe == null
                ? null
                : Border(left: BorderSide(color: stripe!.color(c), width: 3)),
          ),
          padding: EdgeInsets.fromLTRB(
            stripe == null ? UiSpace.l : UiSpace.l - 3,
            dense ? UiSpace.s : UiSpace.m,
            UiSpace.l,
            dense ? UiSpace.s : UiSpace.m,
          ),
          child: Row(
            children: [
              if (number != null) ...[
                SizedBox(
                  width: 28,
                  child: Text(
                    number!,
                    textAlign: TextAlign.right,
                    style: UiTextStyles.value.copyWith(color: c.textMuted),
                  ),
                ),
                const SizedBox(width: UiSpace.m),
              ],
              if (leading != null) ...[
                IconTheme.merge(
                  data: IconThemeData(color: c.textMuted, size: UiSize.icon),
                  child: leading!,
                ),
                const SizedBox(width: UiSpace.m),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: (dense ? UiTextStyles.body : UiTextStyles.bodyStrong).copyWith(
                        color: c.text,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        style: UiTextStyles.bodySmall.copyWith(color: c.textMuted),
                      ),
                    if (below != null)
                      Padding(
                        padding: const EdgeInsets.only(top: UiSpace.xs),
                        child: below,
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: UiSpace.m),
                DefaultTextStyle.merge(
                  style: UiTextStyles.value.copyWith(color: c.text),
                  textAlign: TextAlign.right,
                  child: trailing!,
                ),
              ],
              if (chevron) ...[
                const SizedBox(width: UiSpace.s),
                Icon(UiIcons.chevronRight, size: UiSize.iconSmall, color: c.textMuted),
              ],
            ],
          ),
        ),
      );
    }

    if (onTap == null) {
      return body(null);
    }
    return UiPressable(onPressed: onTap, selected: selected, builder: (context, s) => body(s));
  }
}

/// Row with a radio mark: one of several mutually exclusive options.
class const UiChoiceRow({
  /// Title.
  required final String title,

  /// Whether this option is chosen.
  required final bool selected,

  /// Choose this option.
  required final VoidCallback? onTap,

  /// Secondary line.
  final String? subtitle,

  /// Trailing widget: a price.
  final Widget? trailing,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: UiListRow(
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        trailing: trailing,
        leading: _RadioMark(selected: selected, color: selected ? c.accent : c.borderStrong),
      ),
    );
  }
}

class const _RadioMark({required final bool selected, required final Color color})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 18,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: selected ? 5 : 1.5),
      ),
    ),
  );
}

/// Row with a label, a description and a [UiSwitch]; the whole row toggles.
class const UiSwitchRow({
  /// Title.
  required final String title,

  /// Current value.
  required final bool value,

  /// Change handler; `null` disables the row.
  required final ValueChanged<bool>? onChanged,

  /// One line under the title.
  final String? subtitle,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return UiPressable(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      toggled: value,
      builder: (context, state) => UiFocusRing(
        visible: state.focused,
        inset: true,
        radius: BorderRadius.zero,
        child: AnimatedContainer(
          duration: UiMotion.of(context, UiMotion.fast),
          color: state.hovered ? c.sunken : const Color(0x00000000),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: UiSpace.l, vertical: UiSpace.m),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: UiTextStyles.body.copyWith(color: c.text)),
                    if (subtitle != null)
                      Text(subtitle!, style: UiTextStyles.caption.copyWith(color: c.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: UiSpace.l),
              ExcludeSemantics(
                child: UiSwitch(value: value, onChanged: onChanged),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square switch, drawn like a relay contact: track and a sliding block.
class const UiSwitch({
  /// Current value.
  required final bool value,

  /// Change handler; `null` disables the switch.
  required final ValueChanged<bool>? onChanged,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final enabled = onChanged != null;
    final Color track = !enabled
        ? c.sunken
        : value
        ? c.primary
        : c.surface;
    final Color thumb = !enabled
        ? c.border
        : value
        ? c.onPrimary
        : c.borderStrong;
    return GestureDetector(
      onTap: enabled ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: UiMotion.of(context, UiMotion.fast),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: track,
          borderRadius: UiRadius.controlAll,
          border: Border.all(color: value && enabled ? c.primary : c.borderStrong),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          // Inner width 36 − thumb 16 = 20 px of travel = 1.25 thumb widths.
          child: AnimatedSlide(
            duration: UiMotion.of(context, UiMotion.fast),
            curve: UiMotion.curve,
            offset: Offset(value ? 1.25 : 0, 0),
            child: SizedBox.square(
              dimension: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: thumb,
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label–value pairs: labels muted on the left, mono values on the right.
class const UiKeyValueList({
  /// Pairs.
  required final List<(String label, String value)> entries,

  /// Padding; defaults to the card padding.
  final EdgeInsetsGeometry? padding,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(UiSpace.l, 0, UiSpace.l, UiSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, value) in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: UiSpace.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: UiTextStyles.bodySmall.copyWith(color: c.textMuted),
                    ),
                  ),
                  const SizedBox(width: UiSpace.m),
                  Flexible(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        value,
                        textAlign: TextAlign.right,
                        style: UiTextStyles.value.copyWith(color: c.text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
