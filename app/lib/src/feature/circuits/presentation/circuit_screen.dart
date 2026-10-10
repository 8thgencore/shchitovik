import 'package:common_translations/common_translations.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:norms_data/norms_data.dart';
import 'package:shchitovik/src/feature/circuits/presentation/status_badge.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/formatting.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_scope.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Details of a circuit: values, checks with references, settings and expert overrides.
class CircuitScreen extends StatelessWidget {
  const CircuitScreen({required this.circuitId, super.key});

  /// Circuit id.
  final String circuitId;

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final state = context.watch<ProjectBloc>().state as ProjectReady;
    final circuit = state.result.circuits.where((c) => c.id == circuitId).firstOrNull;
    if (circuit == null) return Center(child: Text(t.circuitsEmpty));
    final input = state.document.input;
    final settings = input.circuitSettings[circuitId] ?? const CircuitSettings();
    final expert = isExpertMode(context);
    final devices = input.devices.where((d) => circuit.deviceIds.contains(d.id));

    void edit(CircuitSettings Function(CircuitSettings) change) => ProjectScope.edit(context, (d) {
      final current = d.input.circuitSettings[circuitId] ?? const CircuitSettings();
      return d.copyWith(
        input: d.input.copyWith(
          circuitSettings: {...d.input.circuitSettings, circuitId: change(current)},
        ),
      );
    });

    final cable = circuit.cable;
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ListTile(
          leading: StatusIcon(circuit.status),
          title: Text(
            '${circuit.number}. ${circuit.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text('${circuit.protection.description} · ${circuit.status.label}'),
        ),
        SectionTitle(t.circuitDevices),
        for (final d in devices)
          ListTile(
            dense: true,
            title: Text(d.name),
            trailing: Text('${formatNumber(d.totalPowerW / 1000, 2)} кВт'),
          ),
        SectionTitle(t.circuitValues),
        for (final (label, value) in values)
          ListTile(dense: true, title: Text(label), trailing: Text(value)),
        SectionTitle(t.circuitChecks),
        for (final check in circuit.allChecks)
          ListTile(
            dense: true,
            leading: CheckStatusIcon(check.status),
            title: Text(check.message),
            subtitle: check.reference == null ? null : Text(check.reference!),
          ),
        if (circuit.protection.rcd != null) ...[
          SectionTitle(t.circuitRcdReasons),
          for (final reason in circuit.protection.rcd!.reasons)
            ListTile(dense: true, title: Text(reason)),
        ],
        SectionTitle(t.circuitSettings),
        DecimalField(
          value: settings.lengthM ?? input.cableDefaults.lengthM,
          label: t.circuitLength,
          digits: 1,
          onChanged: (v) => edit((s) => s.copyWith(lengthM: v)),
        ),
        ChoiceField<String>(
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
          SectionTitle(t.circuitExpert),
          ChoiceField<double?>(
            label: t.circuitSection,
            value: settings.sectionMm2,
            options: [
              (null, '${t.auto} (${formatNumber(cable.sectionMm2)})'),
              for (final s in NormsData.embedded.constants.standardSections.take(10))
                (s, formatNumber(s)),
            ],
            onChanged: (v) => edit((s) => s.copyWith(sectionMm2: v)),
          ),
          ChoiceField<double?>(
            label: t.circuitBreaker,
            value: settings.breakerA,
            options: [
              (null, '${t.auto} (${formatNumber(circuit.protection.breakerA, 0)})'),
              for (final r in NormsData.embedded.breakers.ratedCurrents) (r, formatNumber(r, 0)),
            ],
            onChanged: (v) => edit((s) => s.copyWith(breakerA: v)),
          ),
          ChoiceField<BreakerCurve?>(
            label: t.circuitCurve,
            value: settings.curve,
            options: [
              (null, '${t.auto} (${circuit.protection.curve.name.toUpperCase()})'),
              for (final c in BreakerCurve.values) (c, c.name.toUpperCase()),
            ],
            onChanged: (v) => edit((s) => s.copyWith(curve: v)),
          ),
          ChoiceField<ProtectionDevice?>(
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
            ChoiceField<Phase?>(
              label: t.circuitPhase,
              value: settings.phase,
              options: [(null, t.auto), for (final p in Phase.values) (p, p.label)],
              onChanged: (v) => edit((s) => s.copyWith(phase: v)),
            ),
          if (settings.hasManualOverride)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => edit(
                  (s) => s.copyWith(
                    sectionMm2: null,
                    breakerA: null,
                    curve: null,
                    protection: null,
                    phase: null,
                  ),
                ),
                child: Text(t.circuitResetManual),
              ),
            ),
        ],
      ],
    );
  }
}
