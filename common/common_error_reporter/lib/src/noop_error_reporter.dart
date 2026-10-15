import 'package:common_error_reporter/common_error_reporter.dart';

/// {@template noop_error_reporter}
/// A [ErrorReporter] that does nothing.
/// {@endtemplate}
final class const NoopErrorReporter() implements ErrorReporter {
  /// {@macro noop_error_reporter}
  this;

  @override
  Future<void> captureException({
    required Object throwable,
    StackTrace? stackTrace,
  }) async {}
}
