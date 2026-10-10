import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:meta/meta.dart';

/// Everything persisted about a project: metadata, calculation input and estimate choices.
///
/// Calculation results are not part of it — they are recomputed by `calculateProject`.
@immutable
final class ProjectDocument {
  const ProjectDocument({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.input,
    this.note = '',
    this.estimate = const EstimateInput(),
  });

  /// UUID.
  final String id;

  /// Name.
  final String name;

  /// Free-form note.
  final String note;

  /// Creation time, UTC.
  final DateTime createdAt;

  /// Last change, UTC.
  final DateTime updatedAt;

  /// Calculation input.
  final ProjectInput input;

  /// Estimate choices.
  final EstimateInput estimate;

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
final class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.name,
    required this.objectType,
    required this.updatedAt,
  });

  /// UUID.
  final String id;

  /// Name.
  final String name;

  /// Object type.
  final ObjectType objectType;

  /// Last change, UTC.
  final DateTime updatedAt;
}
