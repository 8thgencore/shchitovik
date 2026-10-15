import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:norms_data/norms_data.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/feature/rooms_devices/presentation/device_editor_sheet.dart';
import 'package:shchitovik/src/feature/rooms_devices/presentation/pickers.dart';
import 'package:shchitovik/src/widget/form_fields.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Rooms of the project with their devices.
class const RoomsScreen({super.key}) extends StatelessWidget {
  Future<void> _addRoom(BuildContext context) async {
    final RoomTemplate? template = await RoomTemplatePicker.show(context);
    if (template == null || !context.mounted) return;
    final String roomId = _uuid.v4();
    ProjectScope.edit(context, (d) {
      final ProjectInput input = d.input;
      final int sameName = input.rooms.where((r) => r.name.startsWith(template.name)).length;
      final room = RoomInput(
        id: roomId,
        name: sameName == 0 ? template.name : '${template.name} ${sameName + 1}',
        kind: template.kind,
      );
      final List<DeviceInput> devices = [
        for (final entry in template.devices)
          DeviceInput.fromTemplate(
            NormsData.embedded.device(entry.deviceId),
            id: _uuid.v4(),
            roomId: roomId,
            quantity: entry.count,
          ),
      ];
      return d.copyWith(
        input: input.copyWith(
          rooms: [...input.rooms, room],
          devices: [...input.devices, ...devices],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final ProjectInput input = (context.watch<ProjectBloc>().state as ProjectReady).document.input;
    if (input.rooms.isEmpty) {
      return UiEmptyState(
        icon: UiIcons.rooms,
        title: t.roomsEmptyTitle,
        message: t.roomsEmpty,
        actions: [
          UiButton(label: t.roomsAdd, icon: UiIcons.add, onPressed: () => _addRoom(context)),
        ],
      );
    }
    final List<_RoomCard> cards = [
      for (final room in input.rooms) _RoomCard(room: room, input: input),
    ];
    return PageBody(
      children: [
        UiSectionHeader(
          t.tabRooms,
          description: t.stepRoomsSummary(input.rooms.length, input.devices.length),
          trailing: UiButton.secondary(
            label: t.roomsAdd,
            icon: UiIcons.add,
            onPressed: () => _addRoom(context),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= UiBreakpoints.twoColumns ? 2 : 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < columns; col++) ...[
                  if (col > 0) const SizedBox(width: UiSpace.l),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = col; i < cards.length; i += columns) ...[
                          if (i >= columns) const SizedBox(height: UiSpace.l),
                          cards[i],
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class const _RoomCard({required final RoomInput room, required final ProjectInput input})
    extends StatelessWidget {
  Future<void> _addDevice(BuildContext context) async {
    final Object? template = await DeviceTemplatePicker.show(context);
    if (!context.mounted || template == null) return;
    final DeviceInput device = switch (template) {
      DeviceTemplate() => DeviceInput.fromTemplate(template, id: _uuid.v4(), roomId: room.id),
      _ => DeviceInput(
        id: _uuid.v4(),
        roomId: room.id,
        name: context.translations.deviceCustom,
        kind: 'other',
        powerW: 1000,
      ),
    };
    ProjectScope.edit(
      context,
      (d) => d.copyWith(input: d.input.copyWith(devices: [...d.input.devices, device])),
    );
    if (template is! DeviceTemplate) await DeviceEditorSheet.show(context, deviceId: device.id);
  }

  Future<void> _rename(BuildContext context) async {
    final RoomInput? result = await RoomEditorSheet.show(context, room);
    if (result == null || !context.mounted) return;
    ProjectScope.edit(
      context,
      (d) => d.copyWith(
        input: d.input.copyWith(
          rooms: d.input.rooms.map((r) => r.id == room.id ? result : r).toList(),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final CommonTranslationsLocalizations t = context.translations;
    final bool confirmed = await showUiConfirm(
      context,
      title: t.roomDeleteTitle(room.name),
      message: t.roomDeleteMessage,
      confirmLabel: t.roomDeleteConfirm,
      cancelLabel: t.cancel,
    );
    if (!confirmed || !context.mounted) return;
    ProjectScope.edit(
      context,
      (d) => d.copyWith(
        input: d.input.copyWith(
          rooms: [
            for (final r in d.input.rooms)
              if (r.id != room.id) r,
          ],
          devices: [
            for (final x in d.input.devices)
              if (x.roomId != room.id) x,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final List<DeviceInput> devices = input.devices.where((d) => d.roomId == room.id).toList();
    final int total = devices.fold<int>(0, (s, d) => s + d.totalPowerW);
    return UiCard(
      eyebrow: roomKindLabel(context, room.kind),
      title: room.name,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${formatNumber(total / 1000, 2)} кВт',
            style: UiTextStyles.valueStrong.copyWith(color: context.uiColors.text),
          ),
          UiMenuButton(
            tooltip: t.moreActions,
            entries: [
              UiMenuEntry(
                label: t.roomRename,
                icon: UiIcons.edit,
                onPressed: () => _rename(context),
              ),
              UiMenuEntry(
                label: t.roomDeleteConfirm,
                icon: UiIcons.delete,
                destructive: true,
                onPressed: () => _delete(context),
              ),
            ],
          ),
        ],
      ),
      child: UiDivided(
        topBorder: true,
        children: [
          for (final d in devices)
            UiListRow(
              dense: true,
              title: d.name,
              subtitle: d.phases == 3 ? '3ф' : null,
              trailing: Text(
                '${d.quantity > 1 ? '${d.quantity} × ' : ''}${formatNumber(d.powerW / 1000, 2)} кВт',
              ),
              onTap: () => DeviceEditorSheet.show(context, deviceId: d.id),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: UiSpace.xs, vertical: UiSpace.xs),
            child: Align(
              alignment: Alignment.centerLeft,
              child: UiButton.ghost(
                label: t.devicesAdd,
                icon: UiIcons.add,
                small: true,
                onPressed: () => _addDevice(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
