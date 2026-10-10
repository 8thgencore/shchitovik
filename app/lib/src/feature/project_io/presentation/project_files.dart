import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shchitovik/src/feature/project_io/domain/project_file_codec.dart';

/// Platform file operations for projects and reports (share sheet on mobile, download on web).
abstract final class ProjectFiles {
  /// Shares or downloads a `.shchitovik` file.
  static Future<void> shareProject({required String projectName, required String contents}) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(utf8.encode(contents), mimeType: ProjectFileCodec.mimeType)],
          fileNameOverrides: [ProjectFileCodec.fileName(projectName)],
        ),
      );

  /// Lets the user pick a project file; returns its text or `null` if cancelled.
  ///
  /// Any file type is allowed: Android does not filter custom extensions reliably, so the
  /// contents are validated by `ProjectFileCodec` instead.
  static Future<String?> pickProjectFile() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes(), allowMalformed: true);
  }
}
