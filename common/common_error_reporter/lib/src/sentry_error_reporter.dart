import 'package:common_error_reporter/common_error_reporter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// {@template sentry_error_reporter}
/// An [ErrorReporter] that sends exceptions to Sentry.
///
/// Call [initialize] once before the app starts reporting.
/// {@endtemplate}
final class SentryErrorReporter implements ErrorReporter {
  /// {@macro sentry_error_reporter}
  const SentryErrorReporter({required this.dsn, required this.environment, this.release});

  /// Sentry project DSN.
  final String dsn;

  /// Environment name, e.g. `dev` or `prod`.
  final String environment;

  /// Release identifier, e.g. `shchitovik@1.0.0+1`.
  final String? release;

  /// Initializes the Sentry SDK.
  Future<void> initialize() => SentryFlutter.init((options) {
    options
      ..dsn = dsn
      ..environment = environment
      ..release = release
      // Project data never leaves the device except as part of an error report.
      ..sendDefaultPii = false;
  });

  @override
  Future<void> captureException({required Object throwable, StackTrace? stackTrace}) async {
    await Sentry.captureException(throwable, stackTrace: stackTrace);
  }
}
