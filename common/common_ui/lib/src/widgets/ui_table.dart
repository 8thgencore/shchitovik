import 'package:common_ui/src/tokens/ui_colors.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_pressable.dart';
import 'package:common_ui/src/widgets/ui_status.dart';
import 'package:common_ui/src/widgets/ui_surfaces.dart';
import 'package:material_ui/material_ui.dart';

/// Column of a [UiTable].
@immutable
final class const UiTableColumn({
  /// Header.
  required final String label,

  /// Share of the free width when [width] is not set.
  final int flex = 1,

  /// Fixed width.
  final double? width,

  /// Right-aligned mono values.
  final bool numeric = false,
});

/// Row of a [UiTable].
@immutable
final class const UiTableRow({
  /// One widget per column; plain strings go through [UiTableCell].
  required final List<Widget> cells,

  /// Opens the row.
  final VoidCallback? onTap,

  /// Attention bar on the leading edge.
  final UiTone? stripe,
});

/// Text cell: mono for numeric columns.
class const UiTableCell(
  /// Text.
  final String text, {

  /// Muted second line: what the main value is made of.
  final String? detail,

  /// Colour of [detail]: a status tone when it explains a problem.
  final Color? detailColor,

  /// Secondary colour.
  final bool muted = false,

  /// The cell the eye looks for in the row: medium weight.
  final bool strong = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => UiTableDetail(
    detail: detail,
    detailColor: detailColor,
    child: Text(
      text,
      maxLines: detail == null ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: muted ? context.uiColors.textMuted : null,
        fontWeight: strong ? FontWeight.w500 : null,
      ),
    ),
  );
}

/// Cell content with a muted caption line under it.
class const UiTableDetail({
  /// Main value.
  required final Widget child,

  /// Second line; the cell is a single line without it.
  final String? detail,

  /// Colour of [detail]; muted by default.
  final Color? detailColor,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (detail == null) {
      return child;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        Text(
          detail!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: UiTextStyles.caption.copyWith(color: detailColor ?? context.uiColors.textMuted),
        ),
      ],
    );
  }
}

/// Data table for wide screens: stamp-label header, hairline rows, hover and tap per row.
///
/// Scrolls horizontally inside its own box when narrower than [minWidth]; on phones show a list.
class const UiTable({
  /// Columns.
  required final List<UiTableColumn> columns,

  /// Rows.
  required final List<UiTableRow> rows,

  /// Width below which the table scrolls horizontally.
  final double minWidth = 720,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final double width = constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;
      final table = SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(columns: columns),
            for (final row in rows) _Row(columns: columns, row: row),
          ],
        ),
      );
      if (width == constraints.maxWidth) {
        return table;
      }
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: table);
    },
  );
}

class const _Header({required final List<UiTableColumn> columns}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.sunken,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: _Cells(
        columns: columns,
        vertical: UiSpace.s + 2,
        children: [
          for (final col in columns)
            Align(
              alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft,
              child: UiLabel(col.label),
            ),
        ],
      ),
    );
  }
}

class const _Row({required final List<UiTableColumn> columns, required final UiTableRow row})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    Widget body(UiPressState? state) => UiFocusRing(
      visible: state?.focused ?? false,
      inset: true,
      radius: BorderRadius.zero,
      child: AnimatedContainer(
        duration: UiMotion.of(context, UiMotion.fast),
        decoration: BoxDecoration(
          color: state != null && (state.hovered || state.pressed)
              ? c.sunken
              : const Color(0x00000000),
          border: Border(
            bottom: BorderSide(color: c.border),
            left: BorderSide(
              color: row.stripe?.color(c) ?? const Color(0x00000000),
              width: 3,
            ),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: UiTextStyles.bodySmall.copyWith(color: c.text),
          child: _Cells(
            columns: columns,
            vertical: UiSpace.m,
            leftInset: -3,
            children: [
              for (var i = 0; i < columns.length; i++)
                Align(
                  alignment: columns[i].numeric ? Alignment.centerRight : Alignment.centerLeft,
                  child: columns[i].numeric
                      ? DefaultTextStyle.merge(
                          style: UiTextStyles.value,
                          textAlign: TextAlign.right,
                          child: row.cells[i],
                        )
                      : row.cells[i],
                ),
            ],
          ),
        ),
      ),
    );
    if (row.onTap == null) {
      return body(null);
    }
    return UiPressable(onPressed: row.onTap, builder: (context, s) => body(s));
  }
}

class const _Cells({
  required final List<UiTableColumn> columns,
  required final List<Widget> children,
  required final double vertical,
  final double leftInset = 0,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(UiSpace.s + leftInset, vertical, UiSpace.s, vertical),
    child: Row(
      children: [
        for (var i = 0; i < columns.length; i++)
          if (columns[i].width != null)
            SizedBox(
              width: columns[i].width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: UiSpace.s),
                child: children[i],
              ),
            )
          else
            Expanded(
              flex: columns[i].flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: UiSpace.s),
                child: children[i],
              ),
            ),
      ],
    ),
  );
}
