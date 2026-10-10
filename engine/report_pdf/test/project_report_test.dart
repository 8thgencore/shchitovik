import 'dart:io';
import 'dart:typed_data';

import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:report_pdf/report_pdf.dart';
import 'package:test/test.dart';

ByteData font(String name) =>
    ByteData.sublistView(File('../../app/assets/fonts/$name').readAsBytesSync());

void main() {
  final fonts = ReportFonts(
    regular: font('NotoSans-Regular.ttf'),
    bold: font('NotoSans-Bold.ttf'),
  );

  for (final (name, input) in [
    ('apartment', DemoProjects.oneRoomApartment()),
    ('house', DemoProjects.house()),
  ]) {
    test('$name report is a multi-page PDF', () async {
      final result = calculateProject(input);
      final bytes = await buildProjectReport(
        ProjectReportData(
          projectName: 'Демо: $name',
          generatedAt: DateTime.utc(2026, 10, 8, 12),
          appVersion: '0.1.0+1',
          input: input,
          result: result,
          estimate: calculateEstimate(input, result, const EstimateInput()),
        ),
        fonts,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(20000));
      final out = Directory('build')..createSync();
      File('${out.path}/report_$name.pdf').writeAsBytesSync(bytes);
    });
  }

  test('report without estimate and without lengths', () async {
    final input = DemoProjects.oneRoomApartment().copyWith(cableDefaults: const CableDefaults());
    final bytes = await buildProjectReport(
      ProjectReportData(
        projectName: 'Без длин',
        generatedAt: DateTime.utc(2026),
        appVersion: '0.1.0+1',
        input: input,
        result: calculateProject(input),
      ),
      fonts,
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
