import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Interaction state of a [UiPressable].
@immutable
final class const UiPressState({
  /// Whether it reacts to input.
  required final bool enabled,

  /// Pointer is over it.
  required final bool hovered,

  /// Has keyboard focus (focus ring visible only in keyboard mode).
  required final bool focused,

  /// Pointer is down on it.
  required final bool pressed,
});

/// Base of every tappable element: hover, keyboard focus, press, Enter/Space activation,
/// pointer cursor and button semantics. Looks are left to [builder].
class const UiPressable({
  /// Tap and activation handler; `null` disables the element.
  required final VoidCallback? onPressed,

  /// Builds the element for its current state.
  required final Widget Function(BuildContext context, UiPressState state) builder,

  /// Accessible label when the visible content is not enough (icon-only).
  final String? semanticLabel,

  /// Selected state for screen readers (tabs, segments, navigation).
  final bool? selected,

  /// Toggled state for screen readers (switches).
  final bool? toggled,

  /// Focus node.
  final FocusNode? focusNode,

  /// Whether to take focus on first build.
  final bool autofocus = false,

  /// Announce as a button.
  final bool isButton = true,

  /// Keyboard focus highlight appeared or went away.
  final ValueChanged<bool>? onFocusHighlight,
  super.key,
}) extends StatefulWidget {
  @override
  State<UiPressable> createState() => _UiPressableState();
}

class _UiPressableState() extends State<UiPressable> {
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
class const UiFocusRing({
  /// Whether the ring is drawn.
  required final bool visible,

  /// Ringed element.
  required final Widget child,

  /// Corner radius of the element.
  final BorderRadius radius = UiRadius.controlAll,

  /// Draw inside the bounds (rows in lists, where outside would be clipped).
  final bool inset = false,
  super.key,
}) extends StatelessWidget {
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
