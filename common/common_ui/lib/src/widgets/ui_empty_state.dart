import 'package:common_ui/src/tokens/ui_colors.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Empty or zero-result state: icon in a drawn frame, what is missing, how to fill it.
class const UiEmptyState({
  /// What is empty.
  required final String title,

  /// What to do about it.
  required final String message,

  /// Icon of the missing thing.
  final IconData? icon,

  /// Buttons; the primary one first.
  final List<Widget> actions = const [],

  /// Extra block under the actions: examples to start from.
  final Widget? footer,

  /// Fills and centers in the page with its own scrolling; off inside a list or a card.
  final bool standalone = true,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final content = Padding(
      padding: const EdgeInsets.all(UiSpace.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                SizedBox.square(
                  dimension: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: c.borderStrong),
                      borderRadius: UiRadius.controlAll,
                    ),
                    child: Icon(icon, size: 24, color: c.textMuted),
                  ),
                ),
                const SizedBox(height: UiSpace.l),
              ],
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: UiTextStyles.title.copyWith(color: c.text),
                ),
              ),
              if (message.isNotEmpty) const SizedBox(height: UiSpace.s),
              if (message.isNotEmpty)
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: UiTextStyles.body.copyWith(color: c.textMuted),
                ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: UiSpace.xl),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: UiSpace.s,
                  runSpacing: UiSpace.s,
                  children: actions,
                ),
              ],
              if (footer != null) ...[const SizedBox(height: UiSpace.xxl), footer!],
            ],
          ),
        ),
      ),
    );
    if (!standalone) {
      return content;
    }
    return Center(child: SingleChildScrollView(child: content));
  }
}
