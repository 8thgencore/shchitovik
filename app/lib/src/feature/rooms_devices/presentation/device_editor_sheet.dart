import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:norms_data/norms_data.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Bottom sheet editing one device; advanced parameters in the expert mode.
class const DeviceEditorSheet({
  /// Device id.
  required final String deviceId,
  super.key,
}) extends StatelessWidget {
  /// Shows the sheet within the project scope of [context].
  static Future<void> show(BuildContext context, {required String deviceId}) {
    final ProjectBloc bloc = context.read<ProjectBloc>();
    return showUiSheet<void>(
      context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: DeviceEditorSheet(deviceId: deviceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final ProjectState state = context.watch<ProjectBloc>().state;
    if (state is! ProjectReady) {
      return const SizedBox.shrink();
    }
    final DeviceInput? device = state.document.input.devices
        .where((d) => d.id == deviceId)
        .firstOrNull;
    if (device == null) {
      return const SizedBox.shrink();
    }
    final bool expert = isExpertMode(context);
    final singlePhaseSupply = state.document.input.supplyPhases == SupplyPhases.single;

    void edit(DeviceInput Function(DeviceInput) change) => ProjectScope.edit(
      context,
      (d) => d.copyWith(
        input: d.input.copyWith(
          devices: d.input.devices.map((x) => x.id == deviceId ? change(x) : x).toList(),
        ),
      ),
    );

    final fields = <Widget>[
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
      UiSelect<DeviceConnection>(
        label: t.deviceConnection,
        value: device.connection,
        options: [
          (DeviceConnection.socket, t.connectionSocket),
          (DeviceConnection.fixed, t.connectionFixed),
        ],
        onChanged: (v) => edit((d) => d.copyWith(connection: v)),
      ),
      UiSwitchRow(
        title: t.deviceAlwaysOn,
        subtitle: t.deviceAlwaysOnHint,
        value: device.alwaysOn,
        onChanged: (v) => edit((d) => d.copyWith(alwaysOn: v)),
      ),
      if (singlePhaseSupply && device.phases == 3)
        UiNotice(tone: UiTone.danger, message: t.deviceThreePhaseOnSingle),
      if (expert) ...[
        // A single-phase supply takes single-phase devices only; the choice stays visible
        // for a three-phase device so it can be switched back.
        if (!singlePhaseSupply || device.phases == 3)
          UiSelect<int>(
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
        UiSelect<DedicatedLine>(
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
      Align(
        alignment: Alignment.centerLeft,
        child: UiButton.secondary(
          icon: UiIcons.delete,
          label: t.deviceDelete,
          onPressed: () async {
            final bool confirmed = await showUiConfirm(
              context,
              title: t.deviceDeleteTitle(device.name),
              message: t.deviceDeleteMessage,
              confirmLabel: t.deviceDelete,
              cancelLabel: t.cancel,
            );
            if (!confirmed || !context.mounted) {
              return;
            }
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
    ];
    return UiSheet(
      title: device.name,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(UiSpace.xl, UiSpace.s, UiSpace.xl, UiSpace.xl),
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(height: UiSpace.l),
            fields[i],
          ],
        ],
      ),
    );
  }
}
