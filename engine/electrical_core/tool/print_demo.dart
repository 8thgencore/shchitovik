// Prints a compact summary of the demo projects: dart run tool/print_demo.dart
import 'dart:io';

import 'package:electrical_core/electrical_core.dart';

void main() {
  for (final (name, input) in [
    ('1-к квартира', DemoProjects.oneRoomApartment()),
    ('3-к квартира', DemoProjects.threeRoomApartment()),
    ('Дом', DemoProjects.house()),
  ]) {
    final ProjectResult r = calculateProject(input);
    stdout
      ..writeln('== $name: ${r.status.name}')
      ..writeln(
        '   ввод: Pуст=${(r.incomer.installedPowerW / 1000).toStringAsFixed(1)} кВт, '
        'по приборам=${(r.incomer.demandByDevicesW / 1000).toStringAsFixed(1)} кВт, '
        'по СП 256=${(r.incomer.demandNormativeW / 1000).toStringAsFixed(1)} кВт, '
        'Iр=${r.incomer.designCurrentA.toStringAsFixed(1)} А, In=${r.incomer.breakerA}',
      )
      ..writeln('   ${r.incomer.normativeMethod}');
    if (r.phaseBalance != null) {
      stdout.writeln(
        '   фазы: ${r.phaseBalance!.loadsA.map((k, v) => MapEntry(k.name, v.toStringAsFixed(1)))} '
        'дисбаланс ${r.phaseBalance!.imbalancePercent.toStringAsFixed(0)} %',
      );
    }
    for (final CircuitResult c in r.circuits) {
      final Iterable<String> failed = c.allChecks
          .where((x) => x.status == CheckStatus.failed)
          .map((x) => x.code.name);
      stdout.writeln(
        '   ${c.number.toString().padLeft(2)} ${c.name.padRight(42)} '
        'P=${c.installedPowerW.toStringAsFixed(0).padLeft(5)} Ib=${c.designCurrentA.toStringAsFixed(1).padLeft(5)} '
        '${c.protection.device.name.padRight(8)} ${c.protection.label.padRight(4)} ${c.cable.label.padRight(6)} '
        'ΔU=${c.cable.voltageDropPercent?.toStringAsFixed(2)} Ik=${c.cable.faultCurrentMinA?.toStringAsFixed(0)} '
        '${c.phase?.name ?? '3ф'} ${c.status.name} ${failed.isEmpty ? '' : failed}',
      );
    }
    for (final Issue i in r.issues) {
      stdout.writeln('   ! ${i.severity.name}: ${i.message}');
    }
    if (r.fireRcd != null) {
      stdout.writeln('   УЗО на вводе: ${r.fireRcd!.ratedA} А ${r.fireRcd!.residualMa} мА S');
    }
  }
}
