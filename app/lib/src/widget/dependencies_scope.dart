import 'package:common_utils/common_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shchitovik/src/feature/settings/presentation/settings_scope.dart';
import 'package:shchitovik/src/model/dependencies_container.dart';

/// A scope that provides [DependenciesContainer] to the application.
class const DependenciesScope({
  /// Container with dependencies.
  required final DependenciesContainer dependencies,

  /// The widget below this widget in the tree.
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  /// Get the dependencies from the [context].
  static DependenciesContainer of(BuildContext context) =>
      context.inhOf<_DependenciesInherited>(listen: false).dependencies;

  @override
  Widget build(BuildContext context) {
    return _DependenciesInherited(
      dependencies: dependencies,
      child: SettingsScope(child: child),
    );
  }
}

/// A scope that provides composed [DependenciesContainer].
class const _DependenciesInherited({
  required super.child,

  /// Container with dependencies.
  required final DependenciesContainer dependencies,
}) extends InheritedWidget {
  @override
  bool updateShouldNotify(_DependenciesInherited oldWidget) {
    return !identical(dependencies, oldWidget.dependencies);
  }
}
