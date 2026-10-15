/// Numeric tolerance and formatting shared by the calculations.
library;

/// Absolute tolerance for comparisons of currents, percents and impedances.
///
/// All "≤ limit" checks use `value <= limit + epsilon` so that values equal to the limit
/// pass regardless of floating-point noise.
const double epsilon = 1e-9;

/// `a ≤ b` with [epsilon].
bool lessOrEqual(double a, double b) => a <= b + epsilon;

/// Formats a number for Russian messages: comma decimal separator, at most [digits] digits.
String fmt(double value, [int digits = 1]) {
  String s = value.toStringAsFixed(digits);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}
