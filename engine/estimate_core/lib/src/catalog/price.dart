import 'package:meta/meta.dart';

/// Price range in kopecks: an estimate is always a range, not a single figure.
@immutable
final class PriceRange {
  const PriceRange({
    required this.minKopecks,
    required this.typicalKopecks,
    required this.maxKopecks,
  });

  /// Same value for all three bounds (user-entered price).
  const PriceRange.exact(int kopecks)
    : minKopecks = kopecks,
      typicalKopecks = kopecks,
      maxKopecks = kopecks;

  /// Parses a catalog price object given in rubles.
  factory PriceRange.fromRublesJson(Map<String, Object?> json) => PriceRange(
    minKopecks: _kopecks(json['min']),
    typicalKopecks: _kopecks(json['typical']),
    maxKopecks: _kopecks(json['max']),
  );

  /// Parses JSON produced by [toJson].
  factory PriceRange.fromJson(Map<String, Object?> json) => PriceRange(
    minKopecks: json['min_kopecks']! as int,
    typicalKopecks: json['typical_kopecks']! as int,
    maxKopecks: json['max_kopecks']! as int,
  );

  /// Zero.
  static const zero = PriceRange(minKopecks: 0, typicalKopecks: 0, maxKopecks: 0);

  /// Lower bound, kopecks.
  final int minKopecks;

  /// Typical value, kopecks.
  final int typicalKopecks;

  /// Upper bound, kopecks.
  final int maxKopecks;

  /// Sum.
  PriceRange operator +(PriceRange other) => PriceRange(
    minKopecks: minKopecks + other.minKopecks,
    typicalKopecks: typicalKopecks + other.typicalKopecks,
    maxKopecks: maxKopecks + other.maxKopecks,
  );

  /// Multiplies by [factor], rounding each bound to the nearest kopeck.
  PriceRange times(num factor) => PriceRange(
    minKopecks: (minKopecks * factor).round(),
    typicalKopecks: (typicalKopecks * factor).round(),
    maxKopecks: (maxKopecks * factor).round(),
  );

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
    'min_kopecks': minKopecks,
    'typical_kopecks': typicalKopecks,
    'max_kopecks': maxKopecks,
  };

  @override
  bool operator ==(Object other) =>
      other is PriceRange &&
      other.minKopecks == minKopecks &&
      other.typicalKopecks == typicalKopecks &&
      other.maxKopecks == maxKopecks;

  @override
  int get hashCode => Object.hash(minKopecks, typicalKopecks, maxKopecks);

  @override
  String toString() => 'PriceRange($minKopecks/$typicalKopecks/$maxKopecks коп.)';
}

int _kopecks(Object? rubles) => ((rubles! as num) * 100).round();
