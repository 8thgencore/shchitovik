import 'package:common_ui/src/tokens/ui_icons.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_pressable.dart';
import 'package:common_ui/src/widgets/ui_status.dart';
import 'package:flutter/material.dart';

/// Row of a list inside a card: optional number or icon, title, subtitle, trailing content.
///
/// A [stripe] tone marks rows that need attention with a 3px bar on the leading edge.
class UiListRow extends StatelessWidget {
  const UiListRow({
    required this.title,
    this.subtitle,
    this.number,
    this.leading,
    this.trailing,
    this.below,
    this.stripe,
    this.onTap,
    this.selected = false,
    this.chevron = false,
    this.dense = false,
    super.key,
  });

  /// Title.
  final String title;

  /// Secondary line.
  final String? subtitle;

  /// Number in the mono column («1», «№3»).
  final String? number;

  /// Leading widget: an icon.
  final Widget? leading;

  /// Trailing widget: a value, a badge, a menu.
  final Widget? trailing;

  /// Extra widget under the subtitle: a badge on phones.
  final Widget? below;

  /// Attention bar on the leading edge.
  final UiTone? stripe;

  /// Tap handler; makes the row interactive.
  final VoidCallback? onTap;

  /// Selected state (tinted).
  final bool selected;

  /// Show a chevron that hints at a detail page.
  final bool chevron;

  /// 44 px minimum instead of 56.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
    Widget body(UiPressState? state) {
      final background = selected
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

    if (onTap == null) return body(null);
    return UiPressable(onPressed: onTap, selected: selected, builder: (context, s) => body(s));
  }
}

/// Row with a radio mark: one of several mutually exclusive options.
class UiChoiceRow extends StatelessWidget {
  const UiChoiceRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
    super.key,
  });

  /// Title.
  final String title;

  /// Secondary line.
  final String? subtitle;

  /// Whether this option is chosen.
  final bool selected;

  /// Choose this option.
  final VoidCallback? onTap;

  /// Trailing widget: a price.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
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

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected, required this.color});

  final bool selected;
  final Color color;

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
class UiSwitchRow extends StatelessWidget {
  const UiSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  /// Title.
  final String title;

  /// One line under the title.
  final String? subtitle;

  /// Current value.
  final bool value;

  /// Change handler; `null` disables the row.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
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
class UiSwitch extends StatelessWidget {
  const UiSwitch({required this.value, required this.onChanged, super.key});

  /// Current value.
  final bool value;

  /// Change handler; `null` disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
    final enabled = onChanged != null;
    final track = !enabled
        ? c.sunken
        : value
        ? c.primary
        : c.surface;
    final thumb = !enabled
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
class UiKeyValueList extends StatelessWidget {
  const UiKeyValueList({required this.entries, this.padding, super.key});

  /// Pairs.
  final List<(String label, String value)> entries;

  /// Padding; defaults to the card padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
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
