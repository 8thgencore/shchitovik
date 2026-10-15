import 'package:common_ui/src/tokens/ui_colors.dart';
import 'package:common_ui/src/tokens/ui_icons.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_button.dart';
import 'package:material_ui/material_ui.dart';

/// Shows [builder] as a bottom sheet on phones and as a centered panel on wide screens.
///
/// Build the content with [UiSheet].
Future<T?> showUiSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  if (context.isExpandedLayout) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(UiSpace.xl),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: Builder(builder: builder),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
    builder: builder,
  );
}

/// Content of a sheet or panel: title with a close button, body, actions at the bottom.
///
/// [body] gets the remaining height: pass a `SingleChildScrollView` for short forms (the sheet
/// sizes to it) or a `ListView` for long lists (the sheet takes the full height).
class const UiSheet({
  /// Title.
  required final String title,

  /// Content.
  required final Widget body,

  /// Buttons; the primary one goes last.
  final List<Widget> actions = const [],
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final bool bottomSheet = !context.isExpandedLayout;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              UiSpace.xl,
              bottomSheet ? 0 : UiSpace.l,
              UiSpace.s,
              UiSpace.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: UiTextStyles.title.copyWith(color: c.text)),
                  ),
                ),
                UiIconButton(
                  icon: UiIcons.close,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          Flexible(child: body),
          if (actions.isNotEmpty)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(UiSpace.xl, UiSpace.m, UiSpace.xl, UiSpace.m),
                  child: OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: UiSpace.s,
                    overflowAlignment: OverflowBarAlignment.end,
                    overflowSpacing: UiSpace.s,
                    children: actions,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Asks to confirm a destructive action; `true` only when the user confirmed.
///
/// [title] names the exact entity, [confirmLabel] is the destructive verb. The cancel button has
/// the initial focus, so Enter or Escape never delete anything by accident.
Future<bool> showUiConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final UiColors c = context.uiColors;
      return Dialog(
        insetPadding: const EdgeInsets.all(UiSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(UiSpace.xl, UiSpace.xl, UiSpace.xl, UiSpace.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: UiTextStyles.title.copyWith(color: c.text)),
                ),
                const SizedBox(height: UiSpace.s),
                Text(message, style: UiTextStyles.body.copyWith(color: c.textMuted)),
                const SizedBox(height: UiSpace.xl),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: UiSpace.s,
                  overflowAlignment: OverflowBarAlignment.end,
                  overflowSpacing: UiSpace.s,
                  children: [
                    UiButton.secondary(
                      label: cancelLabel,
                      autofocus: true,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    UiButton.danger(
                      label: confirmLabel,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}

/// Short message at the bottom of the screen with an optional action.
void showUiToast(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      width: context.isExpandedLayout ? 480 : null,
      action: actionLabel == null || onAction == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction),
    ),
  );
}

/// Entry of a [UiMenuButton].
@immutable
final class const UiMenuEntry({
  /// Label.
  required final String label,

  /// Action.
  required final VoidCallback onPressed,

  /// Icon.
  final IconData? icon,

  /// Shown in the danger colour.
  final bool destructive = false,
});

/// «Ещё» icon button with a menu of secondary actions.
class const UiMenuButton({
  /// Tooltip and accessible label.
  required final String tooltip,

  /// Entries.
  required final List<UiMenuEntry> entries,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        for (final e in entries)
          MenuItemButton(
            onPressed: e.onPressed,
            leadingIcon: e.icon == null
                ? null
                : Icon(e.icon, color: e.destructive ? c.danger : c.text),
            child: Text(e.label, style: TextStyle(color: e.destructive ? c.danger : c.text)),
          ),
      ],
      builder: (context, controller, _) => UiIconButton(
        icon: UiIcons.more,
        tooltip: tooltip,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
