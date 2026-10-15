import 'package:common_utils/common_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:shchitovik/src/feature/settings/application/settings_service.dart';
import 'package:shchitovik/src/feature/settings/domain/model/settings.dart';
import 'package:shchitovik/src/widget/dependencies_scope.dart';

/// A scope that provides [Settings] to the application.
class const SettingsScope({
  /// The widget below this widget in the tree.
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  /// Returns the [Settings] of the nearest [SettingsScope] ancestor.
  static Settings of(BuildContext context, {bool listen = true}) =>
      context.inhOf<_SettingsInherited>(listen: listen).settings;

  /// Update the [Settings] of the nearest [SettingsScope] ancestor.
  static Future<void> update(BuildContext context, Settings Function(Settings) transform) async {
    final SettingsService settingsService = DependenciesScope.of(context)
        .settingsContainer
        .settingsService;
    await settingsService.update(transform);
  }

  @override
  Widget build(BuildContext context) {
    final SettingsService settingsService = DependenciesScope.of(context)
        .settingsContainer
        .settingsService;

    return StreamBuilder<Settings>(
      stream: settingsService.stream,
      initialData: settingsService.current,
      builder: (context, snapshot) {
        return _SettingsInherited(settings: snapshot.data!, child: child);
      },
    );
  }
}

class const _SettingsInherited({required super.child, required final Settings settings})
    extends InheritedWidget {
  @override
  bool updateShouldNotify(covariant _SettingsInherited oldWidget) {
    return settings != oldWidget.settings;
  }
}
