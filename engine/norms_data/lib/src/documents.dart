import 'package:norms_data/src/json_reading.dart';

/// Normative document referenced by the datasets.
final class NormativeDocument {
  const NormativeDocument({
    required this.id,
    required this.title,
    required this.status,
    required this.openIssues,
  });

  /// Parses one entry of the `documents` dataset.
  factory NormativeDocument.fromJson(JsonMap json) => NormativeDocument(
    id: json['id']! as String,
    title: json['title']! as String,
    status: json['status']! as String,
    openIssues: strings(json['open_issues']),
  );

  /// Identifier referenced by datasets.
  final String id;

  /// Full title.
  final String title;

  /// Status as of the dataset version.
  final String status;

  /// Items to verify against the official text.
  final List<String> openIssues;
}
