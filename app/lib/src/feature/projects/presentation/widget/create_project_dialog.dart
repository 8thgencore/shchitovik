import 'package:common_translations/common_translations.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';

/// Result of [CreateProjectDialog].
typedef NewProjectParams = ({String name, ObjectType objectType, SupplyPhases supplyPhases});

/// Asks for the name, object type and supply of a new project.
class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  /// Shows the dialog; `null` if cancelled.
  static Future<NewProjectParams?> show(BuildContext context) =>
      showDialog<NewProjectParams>(context: context, builder: (_) => const CreateProjectDialog());

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
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
    return AlertDialog(
      title: Text(t.createProjectTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: t.createProjectName),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text(t.objectTypeTitle, style: Theme.of(context).textTheme.labelLarge),
            RadioGroup<ObjectType>(
              groupValue: _objectType,
              onChanged: (v) => setState(() => _objectType = v!),
              child: Column(
                children: [
                  for (final type in ObjectType.values)
                    RadioListTile<ObjectType>(value: type, title: Text(type.label), dense: true),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(t.supplyTitle, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<SupplyPhases>(
              segments: [
                ButtonSegment(value: SupplyPhases.single, label: Text(t.supplySingle)),
                ButtonSegment(value: SupplyPhases.three, label: Text(t.supplyThree)),
              ],
              selected: {_supply},
              onSelectionChanged: (s) => setState(() => _supply = s.single),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel)),
        FilledButton(onPressed: _submit, child: Text(t.create)),
      ],
    );
  }
}
