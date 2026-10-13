import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// {@template initialization_failed_screen}
/// Screen that is shown when the initialization of the app fails.
/// {@endtemplate}
class InitializationFailedApp extends StatefulWidget {
  /// The error that caused the initialization to fail.
  final Object error;

  /// The stack trace of the error that caused the initialization to fail.
  final StackTrace stackTrace;

  /// The callback that will be called when the retry button is pressed.
  ///
  /// If null, the retry button will not be shown.
  final Future<void> Function()? onRetryInitialization;

  /// {@macro initialization_failed_screen}
  const InitializationFailedApp({
    required this.error,
    required this.stackTrace,
    this.onRetryInitialization,
    super.key,
  });

  @override
  State<InitializationFailedApp> createState() => _InitializationFailedAppState();
}

class _InitializationFailedAppState extends State<InitializationFailedApp> {
  /// Whether the initialization is in progress.
  final _inProgress = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _inProgress.dispose();
    super.dispose();
  }

  Future<void> _retryInitialization() async {
    _inProgress.value = true;
    await widget.onRetryInitialization?.call();
    _inProgress.value = false;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Builder(
              builder: (context) {
                final typography = Theme.of(context).textTheme;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Не удалось запустить приложение',
                      style: typography.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Сохранённые проекты не затронуты. Повторите запуск; если ошибка '
                      'повторится, скопируйте подробности и отправьте их разработчику.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.onRetryInitialization != null)
                          ValueListenableBuilder<bool>(
                            valueListenable: _inProgress,
                            builder: (context, inProgress, _) => FilledButton.icon(
                              onPressed: inProgress ? null : _retryInitialization,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Повторить запуск'),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: '${widget.error}\n${widget.stackTrace}'),
                          ),
                          icon: const Icon(Icons.copy_outlined),
                          label: const Text('Скопировать подробности'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
