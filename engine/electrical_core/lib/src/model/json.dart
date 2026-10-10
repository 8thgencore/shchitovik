/// JSON helpers for the core models.
library;

/// JSON object.
typedef Json = Map<String, Object?>;

/// Reads an enum by its name.
T enumByName<T extends Enum>(List<T> values, Object? name) => values.byName(name! as String);

/// Reads a nullable enum by its name.
T? enumByNameOrNull<T extends Enum>(List<T> values, Object? name) =>
    name == null ? null : values.byName(name as String);

/// Reads a nullable number as double.
double? doubleOrNull(Object? value) => (value as num?)?.toDouble();

/// Drops `null` values so that serialized files stay compact and stable.
Json compact(Json json) => {
  for (final e in json.entries)
    if (e.value != null) e.key: e.value,
};
