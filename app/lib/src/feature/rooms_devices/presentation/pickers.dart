import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:norms_data/norms_data.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';

/// Russian label of a room kind.
String roomKindLabel(BuildContext context, RoomKind kind) {
  final CommonTranslationsLocalizations t = context.translations;
  return switch (kind) {
    RoomKind.standard => t.roomKindStandard,
    RoomKind.kitchen => t.roomKindKitchen,
    RoomKind.bathroom => t.roomKindBathroom,
    RoomKind.outdoor => t.roomKindOutdoor,
    RoomKind.garage => t.roomKindGarage,
  };
}

/// Choice of a room template (or an empty room).
class const RoomTemplatePicker({super.key}) extends StatelessWidget {
  /// Shows the picker.
  static Future<RoomTemplate?> show(BuildContext context) =>
      showUiSheet<RoomTemplate>(context, builder: (_) => const RoomTemplatePicker());

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final List<RoomTemplate> templates = NormsData.embedded.roomTemplates;
    return UiSheet(
      title: t.roomsAddTitle,
      body: ListView(
        padding: const EdgeInsets.only(bottom: UiSpace.l),
        children: [
          UiDivided(
            topBorder: true,
            children: [
              UiListRow(
                leading: const Icon(UiIcons.room),
                title: t.roomsEmptyRoom,
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
                UiListRow(
                  title: room.name,
                  subtitle: '${roomKindLabel(context, room.kind)} · ${room.devices.length} поз.',
                  chevron: true,
                  onTap: () => Navigator.of(context).pop(room),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Choice of a catalog device or a custom one (returns `Object()` for custom).
class const DeviceTemplatePicker({super.key}) extends StatefulWidget {
  /// Shows the picker: [DeviceTemplate], a non-template object for «свой прибор», or `null`.
  static Future<Object?> show(BuildContext context) =>
      showUiSheet<Object>(context, builder: (_) => const DeviceTemplatePicker());

  @override
  State<DeviceTemplatePicker> createState() => _DeviceTemplatePickerState();
}

class _DeviceTemplatePickerState() extends State<DeviceTemplatePicker> {
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
    final CommonTranslationsLocalizations t = context.translations;
    final List<DeviceTemplate> devices = NormsData.embedded.devices
        .where((d) => d.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return UiSheet(
      title: t.devicesAdd,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(UiSpace.xl, 0, UiSpace.xl, UiSpace.m),
            child: UiTextField(
              controller: _search,
              autofocus: true,
              label: t.devicesSearch,
              prefixIcon: UiIcons.search,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: UiSpace.l),
              children: [
                UiDivided(
                  topBorder: true,
                  children: [
                    UiListRow(
                      leading: const Icon(UiIcons.edit),
                      title: t.deviceCustom,
                      onTap: () => Navigator.of(context).pop(Object()),
                    ),
                    if (devices.isEmpty)
                      UiEmptyState(
                        standalone: false,
                        icon: UiIcons.search,
                        title: t.devicesNotFound(_query),
                        message: '',
                        actions: [
                          UiButton.secondary(label: t.devicesSearchReset, onPressed: _resetSearch),
                        ],
                      ),
                    for (final d in devices)
                      UiListRow(
                        title: d.name,
                        trailing: Text(
                          '${formatNumber(d.powerW / 1000, 2)} кВт${d.phases == 3 ? ' · 3ф' : ''}',
                        ),
                        onTap: () => Navigator.of(context).pop(d),
                      ),
                  ],
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
class const RoomEditorSheet({
  /// Room.
  required final RoomInput room,
  super.key,
}) extends StatefulWidget {
  /// Shows the sheet; `null` if cancelled.
  static Future<RoomInput?> show(BuildContext context, RoomInput room) =>
      showUiSheet<RoomInput>(context, builder: (_) => RoomEditorSheet(room: room));

  @override
  State<RoomEditorSheet> createState() => _RoomEditorSheetState();
}

class _RoomEditorSheetState() extends State<RoomEditorSheet> {
  late final _name = TextEditingController(text: widget.room.name);
  late RoomKind _kind = widget.room.kind;

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
    final CommonTranslationsLocalizations t = context.translations;
    return UiSheet(
      title: t.roomRename,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(UiSpace.xl, UiSpace.s, UiSpace.xl, UiSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiTextField(
              controller: _name,
              autofocus: true,
              label: t.deviceName,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: UiSpace.l),
            UiSelect<RoomKind>(
              label: t.roomKind,
              value: _kind,
              options: [for (final k in RoomKind.values) (k, roomKindLabel(context, k))],
              onChanged: (k) => setState(() => _kind = k),
            ),
          ],
        ),
      ),
      actions: [
        UiButton.secondary(label: t.cancel, onPressed: () => Navigator.of(context).pop()),
        UiButton(label: t.save, onPressed: _save),
      ],
    );
  }
}
