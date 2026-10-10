/// Lookup rules shared by the normative tables.
///
/// The tables are stepwise; values between steps are resolved conservatively unless the
/// norm explicitly prescribes interpolation (СП 256 tables, see [interpolateLinear]).
library;

/// Returns the index of the first step that is not less than [value], or `null` if [value]
/// exceeds the last step.
///
/// Used where a larger argument gives a smaller (less favourable) factor, e.g. ambient
/// temperature or number of grouped circuits: taking the next step up is conservative.
int? indexOfStepAtOrAbove(List<num> steps, num value) {
  for (var i = 0; i < steps.length; i++) {
    if (steps[i] >= value) return i;
  }
  return null;
}

/// Linear interpolation of [ys] over ascending [xs], clamped to the end values.
///
/// СП 256 tables prescribe interpolation for intermediate arguments (e.g. примечание 1
/// к таблице 7.1). Pairs with a `null` y are skipped.
double interpolateLinear(List<num> xs, List<num?> ys, num x) {
  final points = <(double, double)>[
    for (var i = 0; i < xs.length; i++)
      if (ys[i] != null) (xs[i].toDouble(), ys[i]!.toDouble()),
  ];
  if (points.isEmpty) throw ArgumentError('No data points');
  if (x <= points.first.$1) return points.first.$2;
  if (x >= points.last.$1) return points.last.$2;
  for (var i = 1; i < points.length; i++) {
    final (x1, y1) = points[i];
    if (x <= x1) {
      final (x0, y0) = points[i - 1];
      return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
    }
  }
  return points.last.$2;
}
