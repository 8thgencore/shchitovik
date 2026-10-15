import 'package:common_ui/common_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// {@template initialization_failed_screen}
/// Screen that is shown when the initialization of the app fails.
/// {@endtemplate}
class const InitializationFailedApp({
  /// The error that caused the initialization to fail.
  required final Object error,

  /// The stack trace of the error that caused the initialization to fail.
  required final StackTrace stackTrace,

  /// The callback that will be called when the retry button is pressed.
  ///
  /// If null, the retry button will not be shown.
  final Future<void> Function()? onRetryInitialization,
  super.key,
}) extends StatefulWidget {
  /// {@macro initialization_failed_screen}
  this;
  @override
  State<InitializationFailedApp> createState() => _InitializationFailedAppState();
}

class _InitializationFailedAppState() extends State<InitializationFailedApp> {
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
    theme: UiTheme.light,
    darkTheme: UiTheme.dark,
    home: Scaffold(
      body: UiEmptyState(
        icon: UiIcons.danger,
        title: 'Не удалось запустить приложение',
        message:
            'Сохранённые проекты не затронуты. Повторите запуск; если ошибка '
            'повторится, скопируйте подробности и отправьте их разработчику.',
        actions: [
          if (widget.onRetryInitialization != null)
            ValueListenableBuilder<bool>(
              valueListenable: _inProgress,
              builder: (context, inProgress, _) => UiButton(
                label: 'Повторить запуск',
                icon: UiIcons.retry,
                busy: inProgress,
                onPressed: _retryInitialization,
              ),
            ),
          UiButton.secondary(
            label: 'Скопировать подробности',
            icon: UiIcons.copy,
            onPressed: () => Clipboard.setData(
              ClipboardData(text: '${widget.error}\n${widget.stackTrace}'),
            ),
          ),
        ],
      ),
    ),
  );
}
