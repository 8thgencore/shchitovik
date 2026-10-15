import 'package:electrical_core/src/calc/tolerance.dart';
import 'package:electrical_core/src/model/enums.dart';

/// Single-phase load to place on a phase.
final class const PhaseLoad({
  /// Circuit id.
  required final String id,

  /// Expected current, A.
  required final double currentA,

  /// Manual phase; such loads are never moved.
  final Phase? fixedPhase,
});

/// Imbalance (max − min) / max · 100 of [loads].
double imbalancePercent(Map<Phase, double> loads) {
  final Iterable<double> values = loads.values;
  final double max = values.reduce((a, b) => a > b ? a : b);
  final double min = values.reduce((a, b) => a < b ? a : b);
  return max <= epsilon ? 0 : (max - min) / max * 100;
}

/// Distributes single-phase loads over L1–L3, starting from [base] (three-phase loads).
///
/// 1. Manual phases are applied first.
/// 2. The rest are placed greedily in descending order of current (ties by id) on the phase
///    giving the smallest maximum load; ties: smaller resulting spread, then L1 → L2 → L3.
/// 3. Local search: the single move or pairwise swap that reduces the spread max − min the
///    most is applied, until no move improves it by more than [epsilon].
/// Deterministic for equal input.
Map<String, Phase> balancePhases(List<PhaseLoad> loads, {Map<Phase, double> base = const {}}) {
  final Map<Phase, double> total = {for (final p in Phase.values) p: base[p] ?? 0.0};
  final assignment = <String, Phase>{};
  for (final PhaseLoad load in loads.where((l) => l.fixedPhase != null)) {
    assignment[load.id] = load.fixedPhase!;
    total[load.fixedPhase!] = total[load.fixedPhase!]! + load.currentA;
  }

  final List<PhaseLoad> movable = loads.where((l) => l.fixedPhase == null).toList()
    ..sort((a, b) {
      final int byCurrent = b.currentA.compareTo(a.currentA);
      return byCurrent != 0 ? byCurrent : a.id.compareTo(b.id);
    });

  double spread(Map<Phase, double> t) {
    final Iterable<double> v = t.values;
    return v.reduce((a, b) => a > b ? a : b) - v.reduce((a, b) => a < b ? a : b);
  }

  for (final load in movable) {
    Phase? best;
    double? bestMax;
    double? bestSpread;
    for (final Phase phase in Phase.values) {
      final Map<Phase, double> trial = {...total, phase: total[phase]! + load.currentA};
      final double max = trial.values.reduce((a, b) => a > b ? a : b);
      final double s = spread(trial);
      final bool better =
          best == null ||
          max < bestMax! - epsilon ||
          ((max - bestMax).abs() <= epsilon && s < bestSpread! - epsilon);
      if (better) {
        best = phase;
        bestMax = max;
        bestSpread = s;
      }
    }
    assignment[load.id] = best!;
    total[best] = total[best]! + load.currentA;
  }

  final Map<String, PhaseLoad> byId = {for (final l in movable) l.id: l};
  for (var iteration = 0; iteration < 200; iteration++) {
    final double current = spread(total);
    double bestGain = epsilon;
    void Function()? bestMove;

    for (final a in movable) {
      final Phase pa = assignment[a.id]!;
      for (final Phase target in Phase.values.where((p) => p != pa)) {
        final Map<Phase, double> trial = {
          ...total,
          pa: total[pa]! - a.currentA,
          target: total[target]! + a.currentA,
        };
        final double gain = current - spread(trial);
        if (gain > bestGain) {
          bestGain = gain;
          bestMove = () {
            assignment[a.id] = target;
            total
              ..[pa] = total[pa]! - a.currentA
              ..[target] = total[target]! + a.currentA;
          };
        }
      }
      for (final b in movable) {
        if (b.id.compareTo(a.id) <= 0) continue;
        final Phase pb = assignment[b.id]!;
        if (pa == pb) continue;
        final double delta = a.currentA - byId[b.id]!.currentA;
        final Map<Phase, double> trial = {...total, pa: total[pa]! - delta, pb: total[pb]! + delta};
        final double gain = current - spread(trial);
        if (gain > bestGain) {
          bestGain = gain;
          bestMove = () {
            assignment[a.id] = pb;
            assignment[b.id] = pa;
            total
              ..[pa] = total[pa]! - delta
              ..[pb] = total[pb]! + delta;
          };
        }
      }
    }
    if (bestMove == null) break;
    bestMove();
  }
  return assignment;
}
