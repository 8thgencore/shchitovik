import 'package:common_translations/common_translations.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';
import 'package:norms_data/norms_data.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/widget/sheet_form.dart';

/// Russian label of a room kind.
String roomKindLabel(BuildContext context, RoomKind kind) {
  final t = context.translations;
  return switch (kind) {
    RoomKind.standard => t.roomKindStandard,
    RoomKind.kitchen => t.roomKindKitchen,
    RoomKind.bathroom => t.roomKindBathroom,
    RoomKind.outdoor => t.roomKindOutdoor,
    RoomKind.garage => t.roomKindGarage,
  };
}

/// Choice of a room template (or an empty room).
class RoomTemplatePicker extends StatelessWidget {
  const RoomTemplatePicker({super.key});

  /// Shows the picker.
  static Future<RoomTemplate?> show(BuildContext context) => showModalBottomSheet<RoomTemplate>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const RoomTemplatePicker(),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final templates = NormsData.embedded.roomTemplates;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          ListTile(title: Text(t.roomsAddTitle, style: Theme.of(context).textTheme.titleMedium)),
          ListTile(
            leading: const Icon(Icons.crop_square),
            title: Text(t.roomsEmptyRoom),
            onTap: () => Navigator.of(context).pop(
              RoomTemplate(
                id: 'empty',
                name: t.roomsEmptyRoom,
                kind: RoomKind.standard,
                devices: const [],
              ),
            ),
          ),
          for (final room in templates)
            ListTile(
              title: Text(room.name),
              subtitle: Text(
                '${roomKindLabel(context, room.kind)} · ${room.devices.length} поз.',
              ),
              onTap: () => Navigator.of(context).pop(room),
            ),
        ],
      ),
    );
  }
}

/// Choice of a catalog device or a custom one (returns `Object()` for custom).
class DeviceTemplatePicker extends StatefulWidget {
  const DeviceTemplatePicker({super.key});

  /// Shows the picker: [DeviceTemplate], a non-template object for «свой прибор», or `null`.
  static Future<Object?> show(BuildContext context) => showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const DeviceTemplatePicker(),
  );

  @override
  State<DeviceTemplatePicker> createState() => _DeviceTemplatePickerState();
}

class _DeviceTemplatePickerState extends State<DeviceTemplatePicker> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _resetSearch() {
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final devices = NormsData.embedded.devices
        .where((d) => d.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _search,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: t.devicesSearch,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(t.deviceCustom),
                  onTap: () => Navigator.of(context).pop(Object()),
                ),
                if (devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(t.devicesNotFound(_query), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        OutlinedButton(onPressed: _resetSearch, child: Text(t.devicesSearchReset)),
                      ],
                    ),
                  ),
                for (final d in devices)
                  ListTile(
                    title: Text(d.name),
                    subtitle: Text(
                      '${formatNumber(d.powerW / 1000, 2)} кВт${d.phases == 3 ? ' · 3ф' : ''}',
                    ),
                    onTap: () => Navigator.of(context).pop(d),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Edits name and kind of a room.
class RoomEditorSheet extends StatefulWidget {
  const RoomEditorSheet({required this.room, super.key});

  /// Room.
  final RoomInput room;

  /// Shows the sheet; `null` if cancelled.
  static Future<RoomInput?> show(BuildContext context, RoomInput room) =>
      SheetForm.show<RoomInput>(context, (_) => RoomEditorSheet(room: room));

  @override
  State<RoomEditorSheet> createState() => _RoomEditorSheetState();
}

class _RoomEditorSheetState extends State<RoomEditorSheet> {
  late final _name = TextEditingController(text: widget.room.name);
  late var _kind = widget.room.kind;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(
    widget.room.copyWith(
      name: _name.text.trim().isEmpty ? widget.room.name : _name.text.trim(),
      kind: _kind,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    return SheetForm(
      title: t.roomRename,
      fields: [
        TextField(
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(labelText: t.deviceName),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<RoomKind>(
          initialValue: _kind,
          isExpanded: true,
          decoration: InputDecoration(labelText: t.roomKind),
          items: [
            for (final k in RoomKind.values)
              DropdownMenuItem(value: k, child: Text(roomKindLabel(context, k))),
          ],
          onChanged: (k) => setState(() => _kind = k!),
        ),
      ],
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel)),
        FilledButton(onPressed: _save, child: Text(t.save)),
      ],
    );
  }
}
