// Prints the estimate of the demo projects: dart run tool/print_estimate.dart
import 'dart:io';

import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';

String rub(int kopecks) => (kopecks / 100).toStringAsFixed(0);

void main() {
  for (final scenario in EstimateScenario.values) {
    final input = DemoProjects.oneRoomApartment();
    final result = calculateProject(input);
    final estimate = calculateEstimate(input, result, EstimateInput(scenario: scenario));
    stdout.writeln('== 1-к квартира, ${scenario.name}: ${rub(estimate.total.minKopecks)}…'
        '${rub(estimate.total.typicalKopecks)}…${rub(estimate.total.maxKopecks)} ₽, модулей ${estimate.moduleUnits}');
    if (scenario == EstimateScenario.standard) {
      for (final l in estimate.lines) {
        stdout.writeln('   ${l.category.name.padRight(9)} ${l.title.padRight(40)} ${l.description.padRight(48)} '
            '${l.quantity.toString().padLeft(5)} ${l.unit} ${rub(l.total.typicalKopecks).padLeft(6)} ${l.source.name} '
            '${l.compatibility?.status.name ?? ''} ${l.missing}');
      }
      for (final w in estimate.warnings) {
        stdout.writeln('   ! ${w.message}');
      }
    }
  }
}
