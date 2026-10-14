import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_button.dart';
import 'package:flutter/material.dart';

/// Bordered surface on the canvas: 1px hairline, 4px corners, no shadow.
class UiCard extends StatelessWidget {
  const UiCard({
    required this.child,
    this.title,
    this.eyebrow,
    this.trailing,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// Content.
  final Widget child;

  /// Heading in the card header.
  final String? title;

  /// Stamp label above [title].
  final String? eyebrow;

  /// Widget at the end of the header: a badge or an action.
  final Widget? trailing;

  /// Padding around [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
    final hasHeader = title != null || eyebrow != null || trailing != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: UiRadius.cardAll,
        border: Border.all(color: c.border),
      ),
      child: ClipRRect(
        borderRadius: UiRadius.cardAll,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasHeader)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  UiSpace.l,
                  UiSpace.m,
                  // An icon button brings its own inner space.
                  trailing is UiIconButton ? UiSpace.xs : UiSpace.l,
                  UiSpace.m,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (eyebrow != null) UiLabel(eyebrow!),
                            if (title != null)
                              Text(
                                title!,
                                style: UiTextStyles.heading.copyWith(color: c.text),
                              ),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[const SizedBox(width: UiSpace.s), trailing!],
                    ],
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Upper-case mono label, like the text in a drawing stamp: groups and value names.
class UiLabel extends StatelessWidget {
  const UiLabel(this.text, {this.color, this.symbol = false, super.key});

  /// Text; shown in upper case.
  final String text;

  /// A quantity symbol (In, ΔU, cos φ): keep the case, it carries meaning.
  final bool symbol;

  /// Colour; defaults to the muted text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    symbol ? text : text.toUpperCase(),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    semanticsLabel: text,
    style: UiTextStyles.label.copyWith(color: color ?? context.uiColors.textMuted),
  );
}

/// Group heading above a block of cards or fields.
class UiSectionHeader extends StatelessWidget {
  const UiSectionHeader(this.title, {this.trailing, this.description, super.key});

  /// Title.
  final String title;

  /// One line under the title.
  final String? description;

  /// Widget at the end: an action.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
    return Padding(
      padding: const EdgeInsets.only(top: UiSpace.s, bottom: UiSpace.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: UiTextStyles.heading.copyWith(color: c.text)),
                ),
                if (description != null)
                  Text(description!, style: UiTextStyles.caption.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Column with hairlines between the children: rows inside a card.
class UiDivided extends StatelessWidget {
  const UiDivided({required this.children, this.topBorder = false, super.key});

  /// Rows.
  final List<Widget> children;

  /// Draw a hairline above the first row too (after a card header).
  final bool topBorder;

  @override
  Widget build(BuildContext context) {
    final line = ColoredBox(
      color: context.uiColors.border,
      child: const SizedBox(height: UiSize.hairline, width: double.infinity),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 || topBorder) line,
          children[i],
        ],
      ],
    );
  }
}

/// Caps the page content at [maxWidth] and centers it; chrome stays full width.
class UiContentWidth extends StatelessWidget {
  const UiContentWidth({
    required this.child,
    this.maxWidth = UiBreakpoints.contentMax,
    super.key,
  });

  /// Page content.
  final Widget child;

  /// Maximum width.
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Bar pinned to the bottom of a screen: wizard navigation, the main action on phones.
class UiActionBar extends StatelessWidget {
  const UiActionBar({required this.child, super.key});

  /// Content: a notice and buttons.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(UiSpace.l, UiSpace.m, UiSpace.l, UiSpace.m),
          child: child,
        ),
      ),
    );
  }
}

/// Card with a heading and form fields stacked with a 16px rhythm.
class UiFieldGroup extends StatelessWidget {
  const UiFieldGroup({required this.title, required this.children, this.eyebrow, super.key});

  /// Heading.
  final String title;

  /// Stamp label above the heading.
  final String? eyebrow;

  /// Fields.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => UiCard(
    title: title,
    eyebrow: eyebrow,
    padding: const EdgeInsets.fromLTRB(UiSpace.l, UiSpace.xs, UiSpace.l, UiSpace.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: UiSpace.l),
          children[i],
        ],
      ],
    ),
  );
}
