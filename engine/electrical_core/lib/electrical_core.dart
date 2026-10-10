/// Electrical calculations of a switchboard project.
///
/// Pure Dart: no Flutter dependency, deterministic, every rule references the norm it implements.
library;

export 'src/algorithm_version.dart';
export 'src/calc/cable_calculator.dart' show CableCalculator, CableLineSpec, minimumVoltageFactor;
export 'src/calc/project_calculator.dart'
    show assumedExternalLoopImpedanceOhm, calculateProject, leakageMa, statusOf, worst;
export 'src/demo/demo_projects.dart';
export 'src/model/enums.dart';
export 'src/model/labels.dart';
export 'src/model/project_input.dart';
export 'src/model/project_result.dart';
