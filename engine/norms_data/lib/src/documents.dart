import 'package:norms_data/src/json_reading.dart';

/// Normative document referenced by the datasets.
final class const NormativeDocument({
  /// Identifier referenced by datasets.
  required final String id,

  /// Full title.
  required final String title,

  /// Status as of the dataset version.
  required final String status,

  /// Items to verify against the official text.
  required final List<String> openIssues,
}) {
  /// Parses one entry of the `documents` dataset.
  factory fromJson(JsonMap json) => NormativeDocument(
    id: json['id']! as String,
    title: json['title']! as String,
    status: json['status']! as String,
    openIssues: strings(json['open_issues']),
  );
}
