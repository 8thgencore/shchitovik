import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_pressable.dart';
import 'package:common_ui/src/widgets/ui_status.dart';
import 'package:common_ui/src/widgets/ui_surfaces.dart';
import 'package:flutter/material.dart';

/// Column of a [UiTable].
@immutable
final class UiTableColumn {
  const UiTableColumn({required this.label, this.flex = 1, this.width, this.numeric = false});

  /// Header.
  final String label;

  /// Share of the free width when [width] is not set.
  final int flex;

  /// Fixed width.
  final double? width;

  /// Right-aligned mono values.
  final bool numeric;
}

/// Row of a [UiTable].
@immutable
final class UiTableRow {
  const UiTableRow({required this.cells, this.onTap, this.stripe});

  /// One widget per column; plain strings go through [UiTableCell].
  final List<Widget> cells;

  /// Opens the row.
  final VoidCallback? onTap;

  /// Attention bar on the leading edge.
  final UiTone? stripe;
}

/// Text cell: mono for numeric columns.
class UiTableCell extends StatelessWidget {
  const UiTableCell(this.text, {this.muted = false, super.key});

  /// Text.
  final String text;

  /// Secondary colour.
  final bool muted;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(color: muted ? context.uiColors.textMuted : null),
  );
}

/// Data table for wide screens: stamp-label header, hairline rows, hover and tap per row.
///
/// Scrolls horizontally inside its own box when narrower than [minWidth]; on phones show a list.
class UiTable extends StatelessWidget {
  const UiTable({required this.columns, required this.rows, this.minWidth = 720, super.key});

  /// Columns.
  final List<UiTableColumn> columns;

  /// Rows.
  final List<UiTableRow> rows;

  /// Width below which the table scrolls horizontally.
  final double minWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;
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
      if (width == constraints.maxWidth) return table;
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: table);
    },
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.columns});

  final List<UiTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
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

class _Row extends StatelessWidget {
  const _Row({required this.columns, required this.row});

  final List<UiTableColumn> columns;
  final UiTableRow row;

  @override
  Widget build(BuildContext context) {
    final c = context.uiColors;
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
            vertical: UiSpace.m - 1,
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
    if (row.onTap == null) return body(null);
    return UiPressable(onPressed: row.onTap, builder: (context, s) => body(s));
  }
}

class _Cells extends StatelessWidget {
  const _Cells({
    required this.columns,
    required this.children,
    required this.vertical,
    this.leftInset = 0,
  });

  final List<UiTableColumn> columns;
  final List<Widget> children;
  final double vertical;
  final double leftInset;

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
