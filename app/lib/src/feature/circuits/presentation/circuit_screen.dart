import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:norms_data/norms_data.dart';
import 'package:shchitovik/src/feature/circuits/presentation/review_notice.dart';
import 'package:shchitovik/src/feature/circuits/presentation/status_badge.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Details of a circuit: values, checks with references, settings and expert overrides.
class const CircuitScreen({
  /// Circuit id.
  required final String circuitId,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CommonTranslationsLocalizations t = context.translations;
    final state = context.watch<ProjectBloc>().state as ProjectReady;
    final CircuitResult? circuit = state.result.circuits
        .where((c) => c.id == circuitId)
        .firstOrNull;
    if (circuit == null) {
      return UiEmptyState(icon: UiIcons.circuits, title: t.circuitsEmpty, message: '');
    }
    final ProjectInput input = state.document.input;
    final CircuitSettings settings = input.circuitSettings[circuitId] ?? const CircuitSettings();
    final bool expert = isExpertMode(context);
    final Iterable<DeviceInput> devices = input.devices.where(
      (d) => circuit.deviceIds.contains(d.id),
    );

    void edit(CircuitSettings Function(CircuitSettings) change) => ProjectScope.edit(context, (d) {
      final CircuitSettings current = d.input.circuitSettings[circuitId] ?? const CircuitSettings();
      return d.copyWith(
        input: d.input.copyWith(
          circuitSettings: {...d.input.circuitSettings, circuitId: change(current)},
        ),
      );
    });

    final CableResult cable = circuit.cable;
    final values = <(String, String)>[
      ('IB', '${formatNumber(circuit.designCurrentA, 2)} А'),
      ('In', circuit.protection.label),
      ('Iz', '${formatNumber(cable.ampacityA)} А'),
      (
        'ΔU',
        '${formatNumber(cable.voltageDropPercent, 2)} % (≤ ${formatNumber(cable.voltageDropLimitPercent, 2)} %)',
      ),
      (
        'Iк мин',
        '${formatNumber(cable.faultCurrentMinA, 0)} А (Ia ${formatNumber(cable.instantaneousTripA, 0)} А)',
      ),
      ('Zs', '${formatNumber(cable.loopImpedanceOhm, 3)} Ом'),
      (t.circuitSection, '${cable.label} (PE ${formatNumber(cable.peSectionMm2)})'),
      (t.circuitPhase, circuit.phase?.label ?? '3ф'),
      ('cos φ', formatNumber(circuit.cosPhi, 2)),
    ];

    final header = UiCard(
      eyebrow: '${t.columnCircuit} №${circuit.number}',
      title: circuit.name,
      trailing: StatusBadge(circuit.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(UiSpace.l, 0, UiSpace.l, UiSpace.m),
            child: Text(
              circuit.protection.description,
              style: UiTextStyles.bodySmall.copyWith(color: context.uiColors.textMuted),
            ),
          ),
          UiMetricGrid(
            metrics: [
              UiMetric(
                symbol: true,
                label: 'IB',
                value: formatNumber(circuit.designCurrentA, 2),
                unit: 'А',
              ),
              UiMetric(symbol: true, label: 'In', value: circuit.protection.label),
              UiMetric(symbol: true, label: 'Iz', value: formatNumber(cable.ampacityA), unit: 'А'),
              UiMetric(
                symbol: true,
                label: 'ΔU',
                value: formatNumber(cable.voltageDropPercent, 2),
                unit: '%',
                emphasis: (cable.voltageDropPercent ?? 0) > cable.voltageDropLimitPercent
                    ? context.uiColors.danger
                    : null,
              ),
            ],
          ),
        ],
      ),
    );

    final bool loopAssumed = LoopReviewNotice.shows(state, circuit: circuit);
    // The fault-loop check passes only on the assumed impedance: that is what needs review.
    CheckStatus shown(Check check) =>
        loopAssumed &&
            check.code == CheckCode.faultDisconnection &&
            check.status == CheckStatus.passed
        ? CheckStatus.warning
        : check.status;
    // Problems first, in order of severity; passed checks keep their order below.
    const List<CheckStatus> order = [
      CheckStatus.failed,
      CheckStatus.warning,
      CheckStatus.notEvaluated,
      CheckStatus.passed,
    ];
    final List<Check> sortedChecks = [
      for (final status in order) ...circuit.allChecks.where((c) => shown(c) == status),
    ];
    final checks = UiCard(
      title: t.circuitChecks,
      child: UiDivided(
        topBorder: true,
        children: [
          for (final check in sortedChecks)
            UiListRow(
              dense: true,
              leading: CheckStatusIcon(shown(check)),
              title: check.message,
              subtitle: check.reference,
            ),
        ],
      ),
    );

    final valuesCard = UiCard(
      title: t.circuitValues,
      child: UiKeyValueList(entries: values),
    );

    final devicesCard = UiCard(
      title: t.circuitDevices,
      child: UiKeyValueList(
        entries: [
          for (final d in devices) (d.name, '${formatNumber(d.totalPowerW / 1000, 2)} кВт'),
        ],
      ),
    );

    final RcdResult? rcd = circuit.protection.rcd;
    final UiCard? rcdCard = rcd == null
        ? null
        : UiCard(
            title: t.circuitRcdReasons,
            padding: const EdgeInsets.fromLTRB(UiSpace.l, 0, UiSpace.l, UiSpace.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final reason in rcd.reasons)
                  Padding(
                    padding: const EdgeInsets.only(top: UiSpace.s),
                    child: UiNotice(message: reason),
                  ),
              ],
            ),
          );

    final settingsCard = UiFieldGroup(
      title: t.circuitSettings,
      children: [
        DecimalField(
          value: settings.lengthM ?? input.cableDefaults.lengthM,
          label: t.circuitLength,
          digits: 1,
          onChanged: (v) => edit((s) => s.copyWith(lengthM: v)),
        ),
        UiSelect<String>(
          label: t.setupMethod,
          value: settings.installationMethodId ?? input.cableDefaults.installationMethodId,
          options: [for (final m in NormsData.embedded.installationMethods) (m.id, m.title)],
          onChanged: (v) => edit((s) => s.copyWith(installationMethodId: v)),
        ),
        if (expert) ...[
          DecimalField(
            value: settings.ambientTemperatureC ?? input.cableDefaults.ambientTemperatureC,
            label: t.setupAmbient,
            digits: 0,
            onChanged: (v) => edit((s) => s.copyWith(ambientTemperatureC: v)),
          ),
          DecimalField(
            value: (settings.groupedCircuits ?? input.cableDefaults.groupedCircuits).toDouble(),
            label: t.setupGrouped,
            digits: 0,
            onChanged: (v) => edit((s) => s.copyWith(groupedCircuits: v?.round())),
          ),
        ],
      ],
    );

    final UiFieldGroup? expertCard = !expert
        ? null
        : UiFieldGroup(
            title: t.circuitExpert,
            children: [
              UiSelect<double?>(
                label: t.circuitSection,
                value: settings.sectionMm2,
                options: [
                  (null, '${t.auto} (${formatNumber(cable.sectionMm2)})'),
                  for (final s in NormsData.embedded.constants.standardSections.take(10))
                    (s, formatNumber(s)),
                ],
                onChanged: (v) => edit((s) => s.copyWith(sectionMm2: v)),
              ),
              UiSelect<double?>(
                label: t.circuitBreaker,
                value: settings.breakerA,
                options: [
                  (null, '${t.auto} (${formatNumber(circuit.protection.breakerA, 0)})'),
                  for (final r in NormsData.embedded.breakers.ratedCurrents)
                    (r, formatNumber(r, 0)),
                ],
                onChanged: (v) => edit((s) => s.copyWith(breakerA: v)),
              ),
              UiSelect<BreakerCurve?>(
                label: t.circuitCurve,
                value: settings.curve,
                options: [
                  (null, '${t.auto} (${circuit.protection.curve.name.toUpperCase()})'),
                  for (final c in BreakerCurve.values) (c, c.name.toUpperCase()),
                ],
                onChanged: (v) => edit((s) => s.copyWith(curve: v)),
              ),
              UiSelect<ProtectionDevice?>(
                label: t.circuitProtection,
                value: settings.protection,
                options: [
                  (null, t.auto),
                  (ProtectionDevice.mcb, t.protectionMcb),
                  (ProtectionDevice.mcbAndRcd, t.protectionMcbRcd),
                  (ProtectionDevice.rcbo, t.protectionRcbo),
                  (ProtectionDevice.mcbUnderGroupRcd, t.protectionGroup),
                ],
                onChanged: (v) => edit((s) => s.copyWith(protection: v)),
              ),
              if (input.supplyPhases == SupplyPhases.three && circuit.phases == 1)
                UiSelect<Phase?>(
                  label: t.circuitPhase,
                  value: settings.phase,
                  options: [(null, t.auto), for (final p in Phase.values) (p, p.label)],
                  onChanged: (v) => edit((s) => s.copyWith(phase: v)),
                ),
              if (settings.hasManualOverride)
                Align(
                  alignment: Alignment.centerLeft,
                  child: UiButton.secondary(
                    label: t.circuitResetManual,
                    icon: UiIcons.reset,
                    onPressed: () => edit(
                      (s) => s.copyWith(
                        sectionMm2: null,
                        breakerA: null,
                        curve: null,
                        protection: null,
                        phase: null,
                      ),
                    ),
                  ),
                ),
            ],
          );

    if (!context.isExpandedLayout) {
      return PageBody(
        children: [
          header,
          if (loopAssumed) LoopReviewNotice(state: state, circuit: circuit),
          if (circuit.alwaysOn) UiNotice(boxed: true, message: t.circuitAlwaysOn),
          devicesCard,
          valuesCard,
          checks,
          ?rcdCard,
          settingsCard,
          ?expertCard,
        ],
      );
    }
    return PageBody(
      children: [
        header,
        if (loopAssumed) LoopReviewNotice(state: state, circuit: circuit),
        if (circuit.alwaysOn) UiNotice(boxed: true, message: t.circuitAlwaysOn),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _Column(children: [checks, valuesCard, ?rcdCard]),
            ),
            const SizedBox(width: UiSpace.l),
            Expanded(
              flex: 2,
              child: _Column(children: [devicesCard, settingsCard, ?expertCard]),
            ),
          ],
        ),
      ],
    );
  }
}

/// Cards stacked with the section gap.
class const _Column({required final List<Widget> children}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: UiSpace.l),
        children[i],
      ],
    ],
  );
}
