import 'package:shchitovik/src/model/app_env.dart';

/// App configuration
///
/// Configurations are read from environment variables, which are set with --dart-define
/// or --dart-define-from-file=env/.dev.env.
class const AppConfig() {
  /// Creates a new [AppConfig] instance.
  this;

  /// The current environment.
  AppEnv get environment {
    String env = const String.fromEnvironment('ENVIRONMENT').trim();

    if (env.isNotEmpty) {
      return AppEnv.from(env);
    }

    env = const String.fromEnvironment('FLUTTER_APP_FLAVOR').trim();

    return AppEnv.from(env);
  }

  /// The Sentry DSN.
  String get sentryDsn => const String.fromEnvironment('SENTRY_DSN').trim();

  /// Whether Sentry is enabled.
  bool get enableSentry => sentryDsn.isNotEmpty;

  /// Base URL of the static catalog hosting; empty means only the bundled catalog is used.
  String get catalogUrl => const String.fromEnvironment('CATALOG_URL').trim();
}

/// A special version of [AppConfig] that is used in tests.
///
/// In order to use [AppConfig] in tests, it is needed to
/// extend this class and provide the dependencies that are needed for the test.
base class const TestConfig() implements AppConfig {
  @override
  Object noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'The test tries to access ${invocation.memberName} (${invocation.runtimeType}) config option, but '
      'it was not provided. Please provide the option in the test. '
      'You can do it by extending this class and providing the option.',
    );
  }
}
