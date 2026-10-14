import 'package:common_ui/src/tokens/ui_icons.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_pressable.dart';
import 'package:flutter/material.dart';

/// Collapsible section: a header row that shows or hides [child].
///
/// Put it inside a `UiCard`; several disclosures in one card are separated by `UiDivided`.
class UiDisclosure extends StatefulWidget {
  const UiDisclosure({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.leading,
    this.initiallyExpanded = false,
    super.key,
  });

  /// Title.
  final String title;

  /// Secondary line.
  final String? subtitle;

  /// Value at the end of the header: a total.
  final Widget? trailing;

  /// Leading widget: a status icon.
  final Widget? leading;

  /// Content.
  final Widget child;

  /// Whether it starts open.
  final bool initiallyExpanded;

  @override
  State<UiDisclosure> createState() => _UiDisclosureState();
}

class _UiDisclosureState extends State<UiDisclosure> {
  late var _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
    final duration = UiMotion.of(context, UiMotion.medium);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          expanded: _expanded,
          child: UiPressable(
            onPressed: () => setState(() => _expanded = !_expanded),
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
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: UiSpace.m),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: UiTextStyles.heading.copyWith(color: c.text),
                          ),
                          if (widget.subtitle != null)
                            Text(
                              widget.subtitle!,
                              style: UiTextStyles.bodySmall.copyWith(color: c.textMuted),
                            ),
                        ],
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: UiSpace.m),
                      DefaultTextStyle.merge(
                        style: UiTextStyles.valueStrong.copyWith(color: c.text),
                        child: widget.trailing!,
                      ),
                    ],
                    const SizedBox(width: UiSpace.s),
                    AnimatedRotation(
                      turns: _expanded ? .5 : 0,
                      duration: duration,
                      curve: UiMotion.curve,
                      child: Icon(UiIcons.chevronDown, size: UiSize.icon, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Content appears at once: only transform and opacity animate.
        if (_expanded)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: widget.child,
          ),
      ],
    );
  }
}
