import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:flutter/material.dart';

/// Interaction state of a [UiPressable].
@immutable
final class UiPressState {
  const UiPressState({
    required this.enabled,
    required this.hovered,
    required this.focused,
    required this.pressed,
  });

  /// Whether it reacts to input.
  final bool enabled;

  /// Pointer is over it.
  final bool hovered;

  /// Has keyboard focus (focus ring visible only in keyboard mode).
  final bool focused;

  /// Pointer is down on it.
  final bool pressed;
}

/// Base of every tappable element: hover, keyboard focus, press, Enter/Space activation,
/// pointer cursor and button semantics. Looks are left to [builder].
class UiPressable extends StatefulWidget {
  const UiPressable({
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    this.selected,
    this.toggled,
    this.focusNode,
    this.autofocus = false,
    this.isButton = true,
    this.onFocusHighlight,
    super.key,
  });

  /// Tap and activation handler; `null` disables the element.
  final VoidCallback? onPressed;

  /// Builds the element for its current state.
  final Widget Function(BuildContext context, UiPressState state) builder;

  /// Accessible label when the visible content is not enough (icon-only).
  final String? semanticLabel;

  /// Selected state for screen readers (tabs, segments, navigation).
  final bool? selected;

  /// Toggled state for screen readers (switches).
  final bool? toggled;

  /// Focus node.
  final FocusNode? focusNode;

  /// Whether to take focus on first build.
  final bool autofocus;

  /// Announce as a button.
  final bool isButton;

  /// Keyboard focus highlight appeared or went away.
  final ValueChanged<bool>? onFocusHighlight;

  @override
  State<UiPressable> createState() => _UiPressableState();
}

class _UiPressableState extends State<UiPressable> {
  var _hovered = false;
  var _focused = false;
  var _pressed = false;

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (_) {
        widget.onPressed?.call();
        return null;
      },
    ),
  };

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      container: true,
      button: widget.isButton,
      enabled: enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      label: widget.semanticLabel,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        actions: _actions,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) {
          setState(() => _focused = v);
          widget.onFocusHighlight?.call(v);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: widget.builder(
            context,
            UiPressState(
              enabled: enabled,
              hovered: enabled && _hovered,
              focused: enabled && _focused,
              pressed: enabled && _pressed,
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the keyboard focus ring outside [child] when [visible].
class UiFocusRing extends StatelessWidget {
  const UiFocusRing({
    required this.visible,
    required this.child,
    this.radius = UiRadius.controlAll,
    this.inset = false,
    super.key,
  });

  /// Whether the ring is drawn.
  final bool visible;

  /// Ringed element.
  final Widget child;

  /// Corner radius of the element.
  final BorderRadius radius;

  /// Draw inside the bounds (rows in lists, where outside would be clipped).
  final bool inset;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      borderRadius: radius,
      border: visible
          ? Border.all(
              color: context.uiColors.focus,
              width: UiSize.focusRing,
              strokeAlign: inset ? BorderSide.strokeAlignInside : BorderSide.strokeAlignOutside,
            )
          : null,
    ),
    child: child,
  );
}
