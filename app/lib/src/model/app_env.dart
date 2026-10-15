/// The environment.
enum AppEnv._(
  /// The environment value.
  final String value,
) {
  /// Development environment.
  dev._('dev'),

  /// Production environment.
  prod._('prod');

  /// Returns the environment from the given [value].
  ///
  /// If the value is not found, the default environment is returned.
  static AppEnv from(String? value) => AppEnv.values.firstWhere(
    (e) => e.value.toLowerCase() == value?.toLowerCase(),
    orElse: () => AppEnv.dev,
  );
}
