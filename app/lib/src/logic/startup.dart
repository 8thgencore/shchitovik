import 'dart:async';

import 'package:common_error_reporter/common_error_reporter.dart';
import 'package:common_logger/common_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shchitovik/src/bloc/app_bloc_observer.dart';
import 'package:shchitovik/src/bloc/bloc_transformer.dart';
import 'package:shchitovik/src/logic/composition_root.dart';
import 'package:shchitovik/src/model/app_config.dart';
import 'package:shchitovik/src/widget/initialization_failed_app.dart';
import 'package:shchitovik/src/widget/root_context.dart';

/// Initializes dependencies and runs app
Future<void> startup() async {
  const config = AppConfig();
  final Logger logger = createAppLogger(
    observers: [
      if (!kReleaseMode) const PrintingLogObserver(logLevel: LogLevel.trace),
    ],
  );

  await runZonedGuarded(
    () async {
      // Ensure Flutter is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Configure global error interception
      FlutterError.onError = logger.logFlutterError;
      WidgetsBinding.instance.platformDispatcher.onError = logger.logPlatformDispatcherError;

      // Setup bloc observer and transformer
      Bloc.observer = AppBlocObserver(logger);
      Bloc.transformer = sequentialBlocTransformer;

      // Setup error reporter and add log observer
      final ErrorReporter errorReporter = await createErrorReporter(config);
      logger.addObserver(ErrorReporterLogObserver(errorReporter));

      Future<void> composeAndRun() async {
        try {
          final CompositionResult compositionResult = await composeDependencies(
            config: config,
            logger: logger,
          );
          runApp(RootContext(compositionResult: compositionResult));
        } on Object catch (e, stackTrace) {
          logger.error('Initialization failed', error: e, stackTrace: stackTrace);
          runApp(
            InitializationFailedApp(
              error: e,
              stackTrace: stackTrace,
              onRetryInitialization: composeAndRun,
            ),
          );
        }
      }

      // Launch the application
      await composeAndRun();
    },
    logger.logZoneError,
  );
}

/// Creates the [ErrorReporter] instance: Sentry when a DSN is configured, no-op otherwise.
Future<ErrorReporter> createErrorReporter(AppConfig config) async {
  if (!config.enableSentry) {
    return const NoopErrorReporter();
  }

  final reporter = SentryErrorReporter(
    dsn: config.sentryDsn,
    environment: config.environment.value,
  );
  await reporter.initialize();

  return reporter;
}
