import 'package:common_ui/src/tokens/ui_colors.dart';
import 'package:common_ui/src/tokens/ui_icons.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_pressable.dart';
import 'package:common_ui/src/widgets/ui_surfaces.dart';
import 'package:material_ui/material_ui.dart';

/// Top bar of a screen: leading button, stamp label and title, actions, optional bottom part.
///
/// Flat surface with a hairline below; used as `Scaffold.appBar`.
class const UiTopBar({
  /// Title.
  required final String title,

  /// Stamp label above the title: the project name on wide screens.
  final String? eyebrow,

  /// Leading widget: a back button.
  final Widget? leading,

  /// Actions at the end.
  final List<Widget> actions = const [],

  /// Part under the bar: wizard steps.
  final PreferredSizeWidget? bottom,

  /// Larger title for wide screens.
  final bool large = false,
  super.key,
}) extends StatelessWidget implements PreferredSizeWidget {
  double get _barHeight => eyebrow != null || large ? 68 : 56;

  @override
  Size get preferredSize => Size.fromHeight(_barHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _barHeight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: leading == null ? (large ? UiSpace.xl : UiSpace.l) : UiSpace.xs,
                    right: large ? UiSpace.l : UiSpace.xs,
                  ),
                  child: Row(
                    children: [
                      if (leading != null) ...[leading!, const SizedBox(width: UiSpace.xs)],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (eyebrow != null) UiLabel(eyebrow!),
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: (large ? UiTextStyles.title : UiTextStyles.heading).copyWith(
                                  color: c.text,
                                  fontSize: large ? 20 : 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final a in actions) ...[const SizedBox(width: UiSpace.xs), a],
                    ],
                  ),
                ),
              ),
              ?bottom,
            ],
          ),
        ),
      ),
    );
  }
}

/// Side navigation of the expanded layout: brand, context block, sections, footer links.
class const UiSidebar({
  /// Product name next to the mark.
  required final String brand,

  /// Main sections.
  required final List<Widget> items,

  /// Block under the brand: the current project.
  final Widget? header,

  /// Links at the bottom: all projects, settings.
  final List<Widget> footer = const [],
  super.key,
}) extends StatelessWidget {
  /// Width of the sidebar.
  static const width = 248.0;

  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: SizedBox(
        width: width,
        child: SafeArea(
          right: false,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(UiSpace.m, UiSpace.l, UiSpace.m, UiSpace.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(UiSpace.s, 0, UiSpace.s, UiSpace.l),
                        child: Row(
                          children: [
                            SizedBox.square(
                              dimension: 28,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: c.primary,
                                  borderRadius: UiRadius.controlAll,
                                ),
                                child: Icon(UiIcons.brand, size: 16, color: c.onPrimary),
                              ),
                            ),
                            const SizedBox(width: UiSpace.m),
                            Text(brand, style: UiTextStyles.heading.copyWith(color: c.text)),
                          ],
                        ),
                      ),
                      if (header != null)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: c.border),
                              bottom: BorderSide(color: c.border),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: UiSpace.s,
                              vertical: UiSpace.m,
                            ),
                            child: header,
                          ),
                        ),
                      const SizedBox(height: UiSpace.s),
                      ...items,
                      const Spacer(),
                      const SizedBox(height: UiSpace.l),
                      ...footer,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section link in a [UiSidebar]; the selected one gets an accent bar.
class const UiNavItem({
  /// Icon.
  required final IconData icon,

  /// Label.
  required final String label,

  /// Open the section.
  required final VoidCallback onPressed,

  /// Current section.
  final bool selected = false,

  /// Number at the end: items in the section.
  final String? count,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return UiPressable(
      onPressed: onPressed,
      selected: selected,
      builder: (context, state) {
        final Color foreground = selected || state.hovered ? c.text : c.textMuted;
        return UiFocusRing(
          visible: state.focused,
          inset: true,
          child: AnimatedContainer(
            duration: UiMotion.of(context, UiMotion.fast),
            height: UiSize.control,
            padding: const EdgeInsets.symmetric(horizontal: UiSpace.m),
            decoration: BoxDecoration(
              color: selected
                  ? c.sunken
                  : state.hovered
                  ? c.sunken.withValues(alpha: .6)
                  : const Color(0x00000000),
              border: Border(
                left: BorderSide(
                  color: selected ? c.accent : const Color(0x00000000),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: UiSize.icon, color: selected ? c.accentText : foreground),
                const SizedBox(width: UiSpace.m),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiTextStyles.bodySmall.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    count!,
                    style: UiTextStyles.value.copyWith(color: c.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// State of a wizard step.
enum UiStepState() {
  /// Not reached or incomplete.
  upcoming,

  /// Shown now.
  current,

  /// Complete.
  done,
}

/// Step of a [UiStepBar].
@immutable
final class const UiStep({
  /// Name.
  required final String label,

  /// State.
  required final UiStepState state,

  /// One-line summary under the name: «3 помещения».
  final String? summary,
});

/// Wizard progress on phones: one bar per step, accent on the current one; steps are tappable.
class const UiStepBar({
  /// Steps.
  required final List<UiStep> steps,

  /// Open a step by index.
  required final ValueChanged<int> onSelected,
  super.key,
}) extends StatelessWidget implements PreferredSizeWidget {
  /// Height of the bar.
  static const height = 64.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return SizedBox(
      height: preferredSize.height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(UiSpace.m, 0, UiSpace.m, UiSpace.s),
        child: Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: UiPressable(
                  onPressed: () => onSelected(i),
                  selected: steps[i].state == UiStepState.current,
                  builder: (context, state) {
                    final UiStep step = steps[i];
                    final current = step.state == UiStepState.current;
                    final done = step.state == UiStepState.done;
                    return UiFocusRing(
                      visible: state.focused,
                      inset: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: UiMotion.of(context, UiMotion.fast),
                              height: 3,
                              color: current
                                  ? c.accent
                                  : done
                                  ? c.textMuted
                                  : state.hovered
                                  ? c.borderStrong
                                  : c.border,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (done && !current) ...[
                                  Icon(UiIcons.check, size: 14, color: c.text),
                                  const SizedBox(width: 3),
                                ],
                                Flexible(
                                  child: Text(
                                    step.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: UiTextStyles.caption.copyWith(
                                      color: current || done ? c.text : c.textMuted,
                                      fontWeight: current ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              step.summary ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiTextStyles.value.copyWith(
                                color: c.textMuted,
                                fontSize: 12,
                                height: 1.3,
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
  }
}
