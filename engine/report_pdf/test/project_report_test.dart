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

  test('switchboard section is drawn with a split group warning', () async {
    final input = DemoProjects.threeRoomApartment().copyWith(rcdStrategy: RcdStrategy.groupedRcd);
    final result = calculateProject(input);
    final estimate = calculateEstimate(input, result, const EstimateInput());
    final items = switchboardItems(input, result, estimate);
    final auto = layoutSwitchboard(items);
    // Group RCD moved to the end of the last rail: the group is split.
    final rcd = items.firstWhere((i) => i.kind == BoardItemKind.groupRcd);
    final board = arrangeSwitchboard(
      items,
      placeBoardItem(const BoardArrangement(), auto, rcd.id, auto.rails.length - 1, 99),
    );
    expect(board.warnings.whereType<BoardGroupSplit>(), isNotEmpty);
    Future<Uint8List> build(SwitchboardLayout? board) => buildProjectReport(
      ProjectReportData(
        projectName: 'Щит',
        generatedAt: DateTime.utc(2026, 10, 14),
        appVersion: '0.1.0+1',
        input: input,
        result: result,
        estimate: estimate,
        board: board,
      ),
      fonts,
    );
    final without = await build(null);
    final withBoard = await build(board);
    File('build/report_board.pdf').writeAsBytesSync(withBoard);
    File('build/report_no_board.pdf').writeAsBytesSync(without);
    // The rails are vector boxes and text: the report grows by the board.
    expect(withBoard.length, greaterThan(without.length + 2000));
  });

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
