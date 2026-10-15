import 'dart:convert';

import 'package:electrical_core/electrical_core.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document_codec.dart';

/// `.shchitovik` project file: a JSON envelope around a [ProjectDocument].
///
/// ```json
/// {"format": "shchitovik-project", "format_version": 1, "app_version": "…",
///  "algorithm_version": "…", "exported_at": "…", "document": {…}}
/// ```
abstract final class ProjectFileCodec() {
  /// File extension without the dot.
  static const extension = 'shchitovik';

  /// MIME type used for sharing.
  static const mimeType = 'application/json';

  /// Envelope marker.
  static const format = 'shchitovik-project';

  /// Envelope version.
  static const formatVersion = 1;

  /// Encodes [document] into the file contents.
  static String encode(
    ProjectDocument document, {
    required String appVersion,
    required DateTime exportedAt,
  }) => const JsonEncoder.withIndent(' ').convert({
    'format': format,
    'format_version': formatVersion,
    'app_version': appVersion,
    'algorithm_version': algorithmVersion,
    'exported_at': exportedAt.toUtc().toIso8601String(),
    'document': ProjectDocumentCodec.encode(document),
  });

  /// Decodes file contents; throws [ProjectFormatException] with a user-facing message.
  static ProjectDocument decode(String contents) {
    final Object? json;
    try {
      json = jsonDecode(contents);
    } on FormatException {
      throw const ProjectFormatException('Файл не является проектом «Щитовика»');
    }
    if (json is! Map<String, Object?> || json['format'] != format) {
      throw const ProjectFormatException('Файл не является проектом «Щитовика»');
    }
    final Object? version = json['format_version'];
    if (version is! int || version > formatVersion) {
      throw const ProjectFormatException(
        'Файл создан более новой версией приложения. Обновите приложение.',
      );
    }
    final Object? document = json['document'];
    if (document is! Map<String, Object?>) {
      throw const ProjectFormatException('В файле нет данных проекта');
    }
    return ProjectDocumentCodec.decode(document);
  }

  /// Safe file name for [projectName].
  static String fileName(String projectName) {
    final String base = projectName.trim().replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    return '${base.isEmpty ? 'project' : base}.$extension';
  }
}
