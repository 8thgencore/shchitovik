import 'package:common_ui/src/tokens/ui_icons.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visible label above a field.
class UiFieldLabel extends StatelessWidget {
  const UiFieldLabel(this.text, {super.key});

  /// Text.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: UiSpace.s),
    child: Text(
      text,
      style: UiTextStyles.caption.copyWith(
        color: context.uiColors.text,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

/// Text input with a label above, a unit inside the field, helper and error text below.
///
/// Numbers and the unit are set in mono when [numeric] is on.
class UiTextField extends StatelessWidget {
  const UiTextField({
    required this.label,
    this.controller,
    this.focusNode,
    this.help,
    this.error,
    this.unit,
    this.placeholder,
    this.prefixIcon,
    this.numeric = false,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    super.key,
  });

  /// Label above the field.
  final String label;

  /// Controller.
  final TextEditingController? controller;

  /// Focus node.
  final FocusNode? focusNode;

  /// Helper text below the field.
  final String? help;

  /// Error text; replaces [help] and turns the border red.
  final String? error;

  /// Unit inside the field on the right («м», «кВт»).
  final String? unit;

  /// Format hint inside the empty field. Never a replacement for [label].
  final String? placeholder;

  /// Icon at the start (search).
  final IconData? prefixIcon;

  /// Mono digits and a decimal keyboard.
  final bool numeric;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Keyboard action.
  final TextInputAction? textInputAction;

  /// Focus on first build.
  final bool autofocus;

  /// Every change.
  final ValueChanged<String>? onChanged;

  /// Enter pressed.
  final ValueChanged<String>? onSubmitted;

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        UiFieldLabel(label),
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          keyboardType:
              keyboardType ??
              (numeric ? const TextInputType.numberWithOptions(decimal: true) : null),
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          style: (numeric ? UiTextStyles.value.copyWith(fontSize: 16) : UiTextStyles.body).copyWith(
            color: c.text,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            // Helper and error text are drawn below, aligned with the label.
            error: error == null ? null : const SizedBox.shrink(),
            suffixText: unit,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: UiSize.icon),
            // The label is outside; screen readers still get it.
            semanticCounterText: '',
          ),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
        if (error != null || help != null)
          Padding(
            padding: const EdgeInsets.only(top: UiSpace.xs),
            child: error != null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(UiIcons.info, size: 15, color: c.danger),
                      ),
                      const SizedBox(width: UiSpace.xs),
                      Expanded(
                        child: Text(
                          error!,
                          style: UiTextStyles.caption.copyWith(color: c.danger),
                        ),
                      ),
                    ],
                  )
                : Text(help!, style: UiTextStyles.caption.copyWith(color: c.textMuted)),
          ),
      ],
    );
  }
}

/// Dropdown with a label above; options open in a menu under the field.
class UiSelect<T> extends StatefulWidget {
  const UiSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.help,
    super.key,
  });

  /// Label above the field.
  final String label;

  /// Selected value.
  final T value;

  /// Options with their labels.
  final List<(T value, String label)> options;

  /// Selection handler; `null` disables the field.
  final ValueChanged<T>? onChanged;

  /// Helper text below.
  final String? help;

  @override
  State<UiSelect<T>> createState() => _UiSelectState<T>();
}

class _UiSelectState<T> extends State<UiSelect<T>> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
    final current = widget.options.where((o) => o.$1 == widget.value).firstOrNull?.$2 ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        UiFieldLabel(widget.label),
        LayoutBuilder(
          builder: (context, constraints) => MenuAnchor(
            controller: _controller,
            style: MenuStyle(
              minimumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 0)),
              maximumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 360)),
            ),
            alignmentOffset: const Offset(0, 4),
            menuChildren: [
              for (final (value, label) in widget.options)
                MenuItemButton(
                  onPressed: () => widget.onChanged?.call(value),
                  trailingIcon: value == widget.value
                      ? Icon(UiIcons.check, size: UiSize.iconSmall, color: c.accentText)
                      : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth - 72),
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: value == widget.value
                          ? const TextStyle(fontWeight: FontWeight.w600)
                          : null,
                    ),
                  ),
                ),
            ],
            builder: (context, controller, _) => UiPressable(
              onPressed: widget.onChanged == null
                  ? null
                  : () => controller.isOpen ? controller.close() : controller.open(),
              semanticLabel: '${widget.label}: $current',
              builder: (context, state) => AnimatedContainer(
                duration: UiMotion.of(context, UiMotion.fast),
                constraints: const BoxConstraints(minHeight: UiSize.control),
                padding: const EdgeInsets.only(left: UiSpace.m, right: UiSpace.s + 2),
                decoration: BoxDecoration(
                  color: state.enabled ? (state.hovered ? c.sunken : c.surface) : c.sunken,
                  borderRadius: UiRadius.controlAll,
                  border: Border.all(
                    color: state.focused || controller.isOpen ? c.focus : c.borderStrong,
                    width: state.focused || controller.isOpen ? UiSize.focusRing : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(
                          current,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: UiTextStyles.body.copyWith(
                            color: state.enabled ? c.text : c.textMuted,
                          ),
                        ),
                      ),
                    ),
                    Icon(UiIcons.chevronDown, size: UiSize.iconSmall, color: c.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.help != null)
          Padding(
            padding: const EdgeInsets.only(top: UiSpace.xs),
            child: Text(widget.help!, style: UiTextStyles.caption.copyWith(color: c.textMuted)),
          ),
      ],
    );
  }
}

/// Option of a [UiSegmented].
@immutable
final class UiSegment<T> {
  const UiSegment({required this.value, required this.label, this.icon});

  /// Value.
  final T value;

  /// Label.
  final String label;

  /// Icon before the label.
  final IconData? icon;
}

/// Segmented choice of 2–4 short options on a recessed track.
class UiSegmented<T> extends StatelessWidget {
  const UiSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.label,
    super.key,
  });

  /// Options.
  final List<UiSegment<T>> segments;

  /// Selected value.
  final T selected;

  /// Selection handler.
  final ValueChanged<T> onChanged;

  /// Label above the control.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
    final track = DecoratedBox(
      decoration: BoxDecoration(color: c.sunken, borderRadius: UiRadius.cardAll),
      child: Padding(
        padding: const EdgeInsets.all(UiSpace.xs),
        child: Row(
          children: [
            for (final s in segments)
              Expanded(
                child: UiPressable(
                  onPressed: () => onChanged(s.value),
                  selected: s.value == selected,
                  builder: (context, state) {
                    final on = s.value == selected;
                    return UiFocusRing(
                      visible: state.focused,
                      inset: true,
                      child: AnimatedContainer(
                        duration: UiMotion.of(context, UiMotion.fast),
                        height: UiSize.controlSmall,
                        padding: const EdgeInsets.symmetric(horizontal: UiSpace.s),
                        decoration: BoxDecoration(
                          color: on
                              ? c.surface
                              : state.hovered
                              ? c.border.withValues(alpha: .5)
                              : const Color(0x00000000),
                          borderRadius: UiRadius.controlAll,
                          border: Border.all(
                            color: on ? c.borderStrong : const Color(0x00000000),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (s.icon != null) ...[
                              Icon(
                                s.icon,
                                size: UiSize.iconSmall,
                                color: on ? c.text : c.textMuted,
                              ),
                              const SizedBox(width: UiSpace.xs),
                            ],
                            Flexible(
                              child: Text(
                                s.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiTextStyles.bodySmall.copyWith(
                                  color: on ? c.text : c.textMuted,
                                  fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
    if (label == null) return track;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [UiFieldLabel(label!), track],
    );
  }
}
