import 'package:common_translations/common_translations.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:norms_data/norms_data.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/feature/rooms_devices/presentation/device_editor_sheet.dart';
import 'package:shchitovik/src/feature/rooms_devices/presentation/pickers.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Rooms of the project with their devices.
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  Future<void> _addRoom(BuildContext context) async {
    final template = await RoomTemplatePicker.show(context);
    if (template == null || !context.mounted) return;
    final roomId = _uuid.v4();
    ProjectScope.edit(context, (d) {
      final input = d.input;
      final sameName = input.rooms.where((r) => r.name.startsWith(template.name)).length;
      final room = RoomInput(
        id: roomId,
        name: sameName == 0 ? template.name : '${template.name} ${sameName + 1}',
        kind: template.kind,
      );
      final devices = [
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
    final t = context.translations;
    final input = (context.watch<ProjectBloc>().state as ProjectReady).document.input;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-room',
        onPressed: () => _addRoom(context),
        icon: const Icon(Icons.add),
        label: Text(t.roomsAdd),
      ),
      body: input.rooms.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(t.roomsEmpty, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
              children: [for (final room in input.rooms) _RoomCard(room: room, input: input)],
            ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.input});

  final RoomInput room;
  final ProjectInput input;

  Future<void> _addDevice(BuildContext context) async {
    final template = await DeviceTemplatePicker.show(context);
    if (!context.mounted || template == null) return;
    final device = switch (template) {
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
    final result = await RoomEditorDialog.show(context, room);
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
    final t = context.translations;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.roomDeleteTitle),
        content: Text(t.roomDeleteMessage),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.delete)),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;
    ProjectScope.edit(
      context,
      (ProjectDocument d) => d.copyWith(
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
    final t = context.translations;
    final devices = input.devices.where((d) => d.roomId == room.id).toList();
    final total = devices.fold<int>(0, (s, d) => s + d.totalPowerW);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(room.name, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text('${formatNumber(total / 1000, 2)} кВт'),
            trailing: PopupMenuButton<int>(
              onSelected: (v) => v == 0 ? _rename(context) : _delete(context),
              itemBuilder: (_) => [
                PopupMenuItem(value: 0, child: Text(t.roomRename)),
                PopupMenuItem(value: 1, child: Text(t.delete)),
              ],
            ),
          ),
          for (final d in devices)
            ListTile(
              dense: true,
              title: Text(d.name),
              subtitle: Text(
                '${d.quantity > 1 ? '${d.quantity} × ' : ''}${formatNumber(d.powerW / 1000, 2)} кВт'
                '${d.phases == 3 ? ' · 3ф' : ''}',
              ),
              onTap: () => DeviceEditorSheet.show(context, deviceId: d.id),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: TextButton.icon(
                onPressed: () => _addDevice(context),
                icon: const Icon(Icons.add),
                label: Text(t.devicesAdd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
