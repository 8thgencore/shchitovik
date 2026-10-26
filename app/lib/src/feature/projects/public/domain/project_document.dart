import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:meta/meta.dart';

/// Everything persisted about a project: metadata, calculation input and estimate choices.
///
/// Calculation results are not part of it – they are recomputed by `calculateProject`.
@immutable
final class const ProjectDocument({
  /// UUID.
  required final String id,

  /// Name.
  required final String name,

  /// Creation time, UTC.
  required final DateTime createdAt,

  /// Last change, UTC.
  required final DateTime updatedAt,

  /// Calculation input.
  required final ProjectInput input,

  /// Free-form note.
  final String note = '',

  /// Estimate choices.
  final EstimateInput estimate = const EstimateInput(),
}) {
  /// Returns a copy with the given fields replaced.
  ProjectDocument copyWith({
    String? id,
    String? name,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProjectInput? input,
    EstimateInput? estimate,
  }) => ProjectDocument(
    id: id ?? this.id,
    name: name ?? this.name,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    input: input ?? this.input,
    estimate: estimate ?? this.estimate,
  );
}

/// Short project info for lists.
@immutable
final class const ProjectSummary({
  /// UUID.
  required final String id,

  /// Name.
  required final String name,

  /// Object type.
  required final ObjectType objectType,

  /// Last change, UTC.
  required final DateTime updatedAt,
});
