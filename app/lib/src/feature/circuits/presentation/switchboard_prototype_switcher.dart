// PROTOTYPE – floating switcher of the board variants (`?board=A|B|C`), debug builds only.
// ignore_for_file: specify_nonobvious_local_variable_types, use_key_in_widget_constructors
import 'package:common_ui/common_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Variant keys; `''` is the current production view.
const protoVariants = ['', 'A', 'B', 'C'];

const _names = {
  '': 'Текущий',
  'A': 'Реалистичный',
  'B': 'Повёрнутая рейка',
  'C': 'Рейка + легенда',
};

/// Variant chosen in the URL; always `''` in release builds.
String protoVariantOf(BuildContext context) {
  if (!kDebugMode) {
    return '';
  }
  final String v = GoRouterState.of(context).uri.queryParameters['board'] ?? '';
  return protoVariants.contains(v) ? v : '';
}

/// Shows the pill over [child] and cycles variants with ← / → unless [keys] is off.
class const ProtoSwitcher({
  required final String current,
  required final bool keys,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<ProtoSwitcher> createState() => _ProtoSwitcherState();
}

class _ProtoSwitcherState() extends State<ProtoSwitcher> {
  final _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _portal.show();
      HardwareKeyboard.instance.addHandler(_onKey);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (!widget.keys || event is! KeyDownEvent || !mounted) {
      return false;
    }
    final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
    if (focused != null &&
        (focused.widget is EditableText ||
            focused.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _step(-1);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _step(1);
      return true;
    }
    return false;
  }

  void _step(int delta) {
    final int i = protoVariants.indexOf(widget.current);
    final String next = protoVariants[(i + delta) % protoVariants.length];
    final Uri uri = GoRouterState.of(context).uri;
    final params = {...uri.queryParameters}..remove('board');
    if (next.isNotEmpty) {
      params['board'] = next;
    }
    context.go(Uri(path: uri.path, queryParameters: params.isEmpty ? null : params).toString());
  }

  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final String key = widget.current.isEmpty ? '0' : widget.current;
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (_) => Positioned(
        left: 0,
        right: 0,
        bottom: UiSpace.xl,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              border: Border.all(color: c.text, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: UiSpace.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UiIconButton(
                    icon: UiIcons.moveLeft,
                    tooltip: 'Предыдущий вариант',
                    onPressed: () => _step(-1),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: UiSpace.s),
                      child: Text(
                        'PROTOTYPE  $key · ${_names[widget.current]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiTextStyles.bodyStrong.copyWith(color: c.text),
                      ),
                    ),
                  ),
                  UiIconButton(
                    icon: UiIcons.moveRight,
                    tooltip: 'Следующий вариант',
                    onPressed: () => _step(1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: widget.child,
    );
  }
}
