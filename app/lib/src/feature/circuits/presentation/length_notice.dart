import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Circuits without a cable length, with the way to set one length for all of them.
///
/// Without a length the voltage drop and the fault loop are not evaluated and the circuit
/// stays preliminary, which is easy to miss in a long list.
class const LengthNotice({
  /// Project.
  required final ProjectReady state,
  super.key,
}) extends StatelessWidget {
  /// Whether some circuits have no length.
  static bool shows(ProjectReady state) => _missing(state).isNotEmpty;

  static List<String> _missing(ProjectReady state) => [
    for (final c in state.result.circuits)
      if (c.cable.lengthM == null) c.id,
  ];

  Future<void> _setLength(BuildContext context, List<String> circuitIds) async {
    final double? length = await showUiSheet<double>(
      context,
      builder: (_) => const _LengthSheet(),
    );
    if (length == null || !context.mounted) {
      return;
    }
    ProjectScope.edit(context, (d) {
      final Map<String, CircuitSettings> settings = {...d.input.circuitSettings};
      for (final id in circuitIds) {
        settings[id] = (settings[id] ?? const CircuitSettings()).copyWith(lengthM: length);
      }
      return d.copyWith(input: d.input.copyWith(circuitSettings: settings));
    });
  }

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final List<String> missing = _missing(state);
    if (missing.isEmpty) {
      return const SizedBox.shrink();
    }
    return UiNotice(
      boxed: true,
      tone: UiTone.warning,
      message: t.circuitsLengthMissing(missing.length),
      action: UiButton.ghost(
        label: t.circuitsSetLength,
        small: true,
        onPressed: () => _setLength(context, missing),
      ),
    );
  }
}

class const _LengthSheet() extends StatefulWidget {
  @override
  State<_LengthSheet> createState() => _LengthSheetState();
}

class _LengthSheetState() extends State<_LengthSheet> {
  double? _length;

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final double? length = _length;
    return UiSheet(
      title: t.circuitsSetLengthTitle,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: UiSpace.xl),
        child: DecimalField(
          value: length,
          label: t.circuitLength,
          digits: 1,
          validator: context.above(0),
          onChanged: (v) => setState(() => _length = v),
        ),
      ),
      actions: [
        UiButton.secondary(label: t.cancel, onPressed: () => Navigator.of(context).pop()),
        UiButton(
          label: t.circuitsSetLengthApply,
          onPressed: length == null || length <= 0 ? null : () => Navigator.of(context).pop(length),
        ),
      ],
    );
  }
}
