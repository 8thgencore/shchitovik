/// Helpers for reading the embedded JSON datasets.
library;

/// JSON object.
typedef JsonMap = Map<String, Object?>;

/// Reads a list of nullable numbers as doubles.
List<double?> nullableDoubles(Object? list) => [
  for (final v in list! as List<Object?>) (v as num?)?.toDouble(),
];

/// Reads a list of numbers as doubles.
List<double> doubles(Object? list) => [
  for (final v in list! as List<Object?>) (v! as num).toDouble(),
];

/// Reads a list of JSON objects.
List<JsonMap> objects(Object? list) => [for (final v in list! as List<Object?>) v! as JsonMap];

/// Reads a list of strings.
List<String> strings(Object? list) => [for (final v in list! as List<Object?>) v! as String];

/// Reads a JSON object field.
JsonMap object(Object? value) => value! as JsonMap;

/// Reads a number as double.
double toDouble(Object? value) => (value! as num).toDouble();
