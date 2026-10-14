import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';

/// Result of [CreateProjectSheet].
typedef NewProjectParams = ({String name, ObjectType objectType, SupplyPhases supplyPhases});

/// Asks for the name, object type and supply of a new project.
class CreateProjectSheet extends StatefulWidget {
  const CreateProjectSheet({super.key});

  /// Shows the sheet; `null` if cancelled.
  static Future<NewProjectParams?> show(BuildContext context) =>
      showUiSheet<NewProjectParams>(context, builder: (_) => const CreateProjectSheet());

  @override
  State<CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends State<CreateProjectSheet> {
  late final _name = TextEditingController(text: context.translations.createProjectDefaultName);
  var _objectType = ObjectType.apartment;
  var _supply = SupplyPhases.single;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop((
    name: _name.text.trim().isEmpty
        ? context.translations.createProjectDefaultName
        : _name.text.trim(),
    objectType: _objectType,
    supplyPhases: _supply,
  ));

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    return UiSheet(
      title: t.createProjectTitle,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(UiSpace.xl, UiSpace.s, UiSpace.xl, UiSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiTextField(
              controller: _name,
              autofocus: true,
              label: t.createProjectName,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: UiSpace.l),
            UiFieldLabel(t.objectTypeTitle),
            UiCard(
              child: UiDivided(
                children: [
                  for (final type in ObjectType.values)
                    UiChoiceRow(
                      title: type.label,
                      selected: type == _objectType,
                      onTap: () => setState(() => _objectType = type),
                    ),
                ],
              ),
            ),
            const SizedBox(height: UiSpace.l),
            UiSegmented<SupplyPhases>(
              label: t.supplyTitle,
              segments: [
                UiSegment(value: SupplyPhases.single, label: t.supplySingle),
                UiSegment(value: SupplyPhases.three, label: t.supplyThree),
              ],
              selected: _supply,
              onChanged: (v) => setState(() => _supply = v),
            ),
          ],
        ),
      ),
      actions: [
        UiButton.secondary(label: t.cancel, onPressed: () => Navigator.of(context).pop()),
        UiButton(label: t.create, icon: UiIcons.add, onPressed: _submit),
      ],
    );
  }
}
