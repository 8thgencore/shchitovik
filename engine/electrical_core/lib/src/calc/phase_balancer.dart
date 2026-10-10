import 'package:electrical_core/src/calc/tolerance.dart';
import 'package:electrical_core/src/model/enums.dart';

/// Single-phase load to place on a phase.
final class PhaseLoad {
  const PhaseLoad({required this.id, required this.currentA, this.fixedPhase});

  /// Circuit id.
  final String id;

  /// Expected current, A.
  final double currentA;

  /// Manual phase; such loads are never moved.
  final Phase? fixedPhase;
}

/// Imbalance (max − min) / max · 100 of [loads].
double imbalancePercent(Map<Phase, double> loads) {
  final values = loads.values;
  final max = values.reduce((a, b) => a > b ? a : b);
  final min = values.reduce((a, b) => a < b ? a : b);
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
  final total = {for (final p in Phase.values) p: base[p] ?? 0.0};
  final assignment = <String, Phase>{};
  for (final load in loads.where((l) => l.fixedPhase != null)) {
    assignment[load.id] = load.fixedPhase!;
    total[load.fixedPhase!] = total[load.fixedPhase!]! + load.currentA;
  }

  final movable = loads.where((l) => l.fixedPhase == null).toList()
    ..sort((a, b) {
      final byCurrent = b.currentA.compareTo(a.currentA);
      return byCurrent != 0 ? byCurrent : a.id.compareTo(b.id);
    });

  double spread(Map<Phase, double> t) {
    final v = t.values;
    return v.reduce((a, b) => a > b ? a : b) - v.reduce((a, b) => a < b ? a : b);
  }

  for (final load in movable) {
    Phase? best;
    double? bestMax;
    double? bestSpread;
    for (final phase in Phase.values) {
      final trial = {...total, phase: total[phase]! + load.currentA};
      final max = trial.values.reduce((a, b) => a > b ? a : b);
      final s = spread(trial);
      final better =
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

  final byId = {for (final l in movable) l.id: l};
  for (var iteration = 0; iteration < 200; iteration++) {
    final current = spread(total);
    var bestGain = epsilon;
    void Function()? bestMove;

    for (final a in movable) {
      final pa = assignment[a.id]!;
      for (final target in Phase.values.where((p) => p != pa)) {
        final trial = {...total, pa: total[pa]! - a.currentA, target: total[target]! + a.currentA};
        final gain = current - spread(trial);
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
        final pb = assignment[b.id]!;
        if (pa == pb) continue;
        final delta = a.currentA - byId[b.id]!.currentA;
        final trial = {...total, pa: total[pa]! - delta, pb: total[pb]! + delta};
        final gain = current - spread(trial);
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
