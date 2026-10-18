import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/logic/app_router.dart';

/// Why circuits need review: the phase–PE loop impedance before the board is assumed.
///
/// That one assumption marks every circuit with a fault-loop check as «requires review»
/// (`statusOf` in electrical_core), so it is explained once, with the way to lift it.
class const LoopReviewNotice({
  /// Project.
  required final ProjectReady state,

  /// A single circuit: the notice speaks about it instead of counting circuits.
  final CircuitResult? circuit,
  super.key,
}) extends StatelessWidget {
  static const _code = 'assumed_external_loop_impedance';

  /// Whether the notice has something to say for [state] (and [circuit]).
  static bool shows(ProjectReady state, {CircuitResult? circuit}) =>
      _assumption(state) != null &&
      (circuit == null ? _count(state) > 0 : circuit.status == CalculationStatus.requiresReview);

  static Assumption? _assumption(ProjectReady state) =>
      state.result.assumptions.where((a) => a.code == _code).firstOrNull;

  static int _count(ProjectReady state) =>
      state.result.circuits.where((c) => c.status == CalculationStatus.requiresReview).length;

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final Assumption? assumption = _assumption(state);
    if (assumption == null) {
      return const SizedBox.shrink();
    }
    return UiNotice(
      boxed: true,
      tone: UiTone.warning,
      title: circuit == null ? t.circuitsReviewTitle(_count(state)) : t.circuitReviewTitle,
      message: assumption.message,
      action: UiButton.ghost(
        label: t.circuitsReviewAction,
        small: true,
        onPressed: () => context.go(AppRoutes.projectSetup(state.document.id)),
      ),
    );
  }
}
