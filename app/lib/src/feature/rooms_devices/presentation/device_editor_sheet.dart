import 'package:common_translations/common_translations.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:norms_data/norms_data.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/widget/confirm_delete.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Bottom sheet editing one device; advanced parameters in the expert mode.
class DeviceEditorSheet extends StatelessWidget {
  const DeviceEditorSheet({required this.deviceId, super.key});

  /// Device id.
  final String deviceId;

  /// Shows the sheet within the project scope of [context].
  static Future<void> show(BuildContext context, {required String deviceId}) {
    final bloc = context.read<ProjectBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: DeviceEditorSheet(deviceId: deviceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final state = context.watch<ProjectBloc>().state;
    if (state is! ProjectReady) return const SizedBox.shrink();
    final device = state.document.input.devices.where((d) => d.id == deviceId).firstOrNull;
    if (device == null) return const SizedBox.shrink();
    final expert = isExpertMode(context);

    void edit(DeviceInput Function(DeviceInput) change) => ProjectScope.edit(
      context,
      (d) => d.copyWith(
        input: d.input.copyWith(
          devices: d.input.devices.map((x) => x.id == deviceId ? change(x) : x).toList(),
        ),
      ),
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: expert ? 0.9 : 0.6,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.only(bottom: 24 + MediaQuery.viewInsetsOf(context).bottom),
        children: [
          CommitTextField(
            value: device.name,
            label: t.deviceName,
            validator: context.notBlank,
            onCommitted: (v) => edit((d) => d.copyWith(name: v.trim())),
          ),
          DecimalField(
            value: device.powerW.toDouble(),
            label: t.devicePower,
            digits: 0,
            validator: context.above(0),
            onChanged: (v) => edit((d) => d.copyWith(powerW: v!.round())),
          ),
          DecimalField(
            value: device.quantity.toDouble(),
            label: t.deviceQuantity,
            digits: 0,
            validator: context.atLeast(1),
            onChanged: (v) => edit((d) => d.copyWith(quantity: v!.round())),
          ),
          ChoiceField<DeviceConnection>(
            label: t.deviceConnection,
            value: device.connection,
            options: [
              (DeviceConnection.socket, t.connectionSocket),
              (DeviceConnection.fixed, t.connectionFixed),
            ],
            onChanged: (v) => edit((d) => d.copyWith(connection: v)),
          ),
          if (expert) ...[
            ChoiceField<int>(
              label: t.devicePhases,
              value: device.phases,
              options: const [(1, '1'), (3, '3')],
              onChanged: (v) => edit((d) => d.copyWith(phases: v)),
            ),
            DecimalField(
              value: device.cosPhi,
              label: t.deviceCosPhi,
              validator: context.between(0.1, 1),
              onChanged: (v) => edit((d) => d.copyWith(cosPhi: v)),
            ),
            DecimalField(
              value: device.usageFactor,
              label: t.deviceUsageFactor,
              validator: context.between(0, 1),
              onChanged: (v) => edit((d) => d.copyWith(usageFactor: v)),
            ),
            DecimalField(
              value: device.inrushMultiple,
              label: t.deviceInrush,
              digits: 1,
              validator: context.atLeast(1),
              onChanged: (v) => edit((d) => d.copyWith(inrushMultiple: v)),
            ),
            ChoiceField<DedicatedLine>(
              label: t.deviceDedicated,
              value: device.dedicatedLine,
              options: [
                (DedicatedLine.required, t.dedicatedRequired),
                (DedicatedLine.recommended, t.dedicatedRecommended),
                (DedicatedLine.no, t.dedicatedNo),
              ],
              onChanged: (v) => edit((d) => d.copyWith(dedicatedLine: v)),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: Text(t.deviceDelete),
              onPressed: () async {
                final confirmed = await confirmDelete(
                  context,
                  title: t.deviceDeleteTitle(device.name),
                  message: t.deviceDeleteMessage,
                  confirmLabel: t.deviceDelete,
                );
                if (!confirmed || !context.mounted) return;
                ProjectScope.edit(
                  context,
                  (d) => d.copyWith(
                    input: d.input.copyWith(
                      devices: [
                        for (final x in d.input.devices)
                          if (x.id != deviceId) x,
                      ],
                    ),
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
