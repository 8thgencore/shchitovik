import 'package:electrical_core/electrical_core.dart';
import 'package:electrical_core/src/calc/phase_balancer.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('greedy + local search reaches the optimal split of 10, 9, 8, 7, 6, 5 A', () {
    final List<PhaseLoad> loads = [
      for (final (i, a) in [10.0, 9.0, 8.0, 7.0, 6.0, 5.0].indexed)
        PhaseLoad(id: 'c$i', currentA: a),
    ];
    final Map<String, Phase> assignment = balancePhases(loads);
    final Map<Phase, double> totals = {for (final p in Phase.values) p: 0.0};
    for (final l in loads) {
      totals[assignment[l.id]!] = totals[assignment[l.id]!]! + l.currentA;
    }
    expect(totals.values.fold<double>(0, (s, v) => s + v), 45);
    expect(totals.values.toSet(), {15.0});
  });

  test('manual phases are kept', () {
    final Map<String, Phase> assignment = balancePhases(const [
      PhaseLoad(id: 'a', currentA: 10, fixedPhase: Phase.l3),
      PhaseLoad(id: 'b', currentA: 10, fixedPhase: Phase.l3),
      PhaseLoad(id: 'c', currentA: 1),
    ]);
    expect(assignment['a'], Phase.l3);
    expect(assignment['b'], Phase.l3);
    expect(assignment['c'], isNot(Phase.l3));
  });

  test('project balance conserves current and is deterministic', () {
    final ProjectInput input = DemoProjects.house();
    final ProjectResult first = calculateProject(input);
    final ProjectResult second = calculateProject(input);
    expect(first.toJson(), second.toJson());

    final PhaseBalanceResult balance = first.phaseBalance!;
    final double sum = balance.loadsA.values.fold<double>(0, (s, v) => s + v);
    final double expected = first.circuits.fold<double>(
      0,
      (s, c) => s + c.demandCurrentA * (c.phases == 3 ? 3 : 1),
    );
    expect(sum, closeTo(expected, 1e-9));
    expect(balance.imbalancePercent, lessThan(30));
  });

  test('manual phase from circuit settings is applied', () {
    final ProjectInput input = singleRoomProject(
      [
        device('a', powerW: 1000),
        device('b', powerW: 1000),
      ],
      supply: SupplyPhases.three,
      circuitSettings: const {
        'dev-a': CircuitSettings(phase: Phase.l2),
        'dev-b': CircuitSettings(phase: Phase.l2),
      },
    );
    final List<CircuitResult> circuits = calculateProject(input).circuits;
    expect(circuits.map((c) => c.phase), [Phase.l2, Phase.l2]);
    expect(circuits.map((c) => c.phaseSource), [ValueSource.manual, ValueSource.manual]);
  });
}
