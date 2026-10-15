import 'package:common_ui/src/tokens/ui_colors.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_surfaces.dart';
import 'package:material_ui/material_ui.dart';

/// One reading: stamp label, mono value and unit.
@immutable
final class const UiMetric({
  /// What is measured.
  required final String label,

  /// Value without the unit.
  required final String value,

  /// Unit or a «/ total» suffix.
  final String? unit,

  /// Colour for a value outside limits.
  final Color? emphasis,

  /// [label] is a quantity symbol (In, ΔU) and keeps its case.
  final bool symbol = false,
});

/// Grid of readings separated by hairlines: 2 columns on phones, 4 on wide cards.
class const UiMetricGrid({
  /// Readings.
  required final List<UiMetric> metrics,

  /// Hairline above the first row (after a card header).
  final bool topBorder = true,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 4 : 2;
        final rows = <List<UiMetric>>[
          for (var i = 0; i < metrics.length; i += columns)
            metrics.sublist(i, (i + columns).clamp(0, metrics.length)),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows.length; r++)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: r > 0 || topBorder ? Border(top: BorderSide(color: c.border)) : null,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < columns; i++)
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: i < columns - 1
                                  ? Border(right: BorderSide(color: c.border))
                                  : null,
                            ),
                            child: i < rows[r].length
                                ? _MetricCell(metric: rows[r][i])
                                : const SizedBox.shrink(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class const _MetricCell({required final UiMetric metric}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(UiSpace.l, UiSpace.m, UiSpace.m, UiSpace.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiLabel(metric.label, symbol: metric.symbol),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: metric.value),
                if (metric.unit != null)
                  TextSpan(
                    text: ' ${metric.unit}',
                    style: UiTextStyles.value.copyWith(color: c.textMuted),
                  ),
              ],
            ),
            style: UiTextStyles.reading.copyWith(color: metric.emphasis ?? c.text),
          ),
        ],
      ),
    );
  }
}

/// Range with a marker: where a typical value sits between its bounds.
class const UiRangeBar({
  /// Marker position, 0…1.
  required final double position,

  /// Lower bound text.
  required final String startLabel,

  /// Upper bound text.
  required final String endLabel,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final TextStyle style = UiTextStyles.value.copyWith(color: c.textMuted, fontSize: 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 14,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 4,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.accentSoft,
                      border: Border.all(color: c.border),
                    ),
                  ),
                ),
                Positioned(
                  left: (constraints.maxWidth - 3) * position.clamp(0, 1),
                  top: 0,
                  width: 3,
                  height: 14,
                  child: ColoredBox(color: c.accent),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: UiSpace.xs),
        Row(
          children: [
            Expanded(child: Text(startLabel, style: style)),
            Text(endLabel, style: style),
          ],
        ),
      ],
    );
  }
}
