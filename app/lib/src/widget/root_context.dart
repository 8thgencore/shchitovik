import 'package:material_ui/material_ui.dart';
import 'package:shchitovik/src/logic/composition_root.dart';
import 'package:shchitovik/src/widget/dependencies_scope.dart';
import 'package:shchitovik/src/widget/material_context.dart';

/// [RootContext] is an entry point to the application.
///
/// If a scope doesn't depend on any inherited widget returned by
/// [MaterialApp] or [WidgetsApp], like [Directionality] or [Theme],
/// and it should be available in the whole application, it should be
/// placed here.
class const RootContext({required final CompositionResult compositionResult, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DependenciesScope(
      dependencies: compositionResult.dependencies,
      child: const MaterialContext(),
    );
  }
}
