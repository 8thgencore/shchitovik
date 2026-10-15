import 'package:estimate_core/estimate_core.dart';

/// Number with a comma and at most [digits] decimals; `—` for null.
String formatNumber(double? value, [int digits = 1]) {
  if (value == null) return '—';
  String s = value.toStringAsFixed(digits);
  if (s.contains('.')) s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return s.replaceAll('.', ',');
}

/// Rubles with thin grouping, from kopecks.
String formatRubles(int kopecks) {
  final rubles = (kopecks / 100).round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rubles.length; i++) {
    if (i > 0 && (rubles.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(rubles[i]);
  }
  return '$buffer ₽';
}

/// `min … max ₽`.
String formatPriceRange(PriceRange price) =>
    '${formatRubles(price.minKopecks)} … ${formatRubles(price.maxKopecks)}';

/// Parses a decimal entered with a comma or a dot; `null` if empty or invalid.
double? parseDecimal(String text) {
  final String normalized = text.trim().replaceAll(',', '.').replaceAll(' ', '');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}
