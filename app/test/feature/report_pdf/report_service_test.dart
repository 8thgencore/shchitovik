import 'dart:typed_data';

import 'package:electrical_core/electrical_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';
import 'package:shchitovik/src/feature/report_pdf/application/report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a PDF with fonts from the asset bundle', () async {
    final Uint8List bytes = await ReportService(appVersion: '0.1.0+1').build(
      ProjectDocument(
        id: 'id',
        name: 'Демо',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        input: DemoProjects.oneRoomApartment(),
      ),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
