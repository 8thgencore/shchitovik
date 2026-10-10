import 'package:clock/clock.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:flutter/services.dart';
import 'package:report_pdf/report_pdf.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';

/// Builds PDF reports of projects.
final class ReportService {
  ReportService({required this.appVersion, AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  /// Version printed in the footer.
  final String appVersion;

  final AssetBundle _bundle;
  ReportFonts? _fonts;

  /// Calculates [document] and renders the report with the estimate priced by [catalog]
  /// (the embedded catalog when omitted).
  Future<Uint8List> build(ProjectDocument document, {EstimateCatalog? catalog}) async {
    final result = calculateProject(document.input);
    return buildProjectReport(
      ProjectReportData(
        projectName: document.name,
        generatedAt: clock.now(),
        appVersion: appVersion,
        input: document.input,
        result: result,
        estimate: calculateEstimate(document.input, result, document.estimate, catalog: catalog),
      ),
      _fonts ??= ReportFonts(
        regular: await _bundle.load('assets/fonts/NotoSans-Regular.ttf'),
        bold: await _bundle.load('assets/fonts/NotoSans-Bold.ttf'),
      ),
    );
  }
}
