import 'dart:convert';

import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shchitovik/src/feature/project_io/domain/project_file_codec.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document_codec.dart';

void main() {
  final document = ProjectDocument(
    id: 'id-1',
    name: 'Квартира',
    note: 'заметка',
    createdAt: DateTime.utc(2026, 10, 8),
    updatedAt: DateTime.utc(2026, 10, 8, 12),
    input: DemoProjects.oneRoomApartment(),
  );

  test('round trip', () {
    final file = ProjectFileCodec.encode(
      document,
      appVersion: '0.1.0',
      exportedAt: DateTime.utc(2026, 10, 9),
    );
    final json = jsonDecode(file) as Map<String, Object?>;
    expect(json['format'], 'shchitovik-project');
    expect(json['algorithm_version'], algorithmVersion);
    final decoded = ProjectFileCodec.decode(file);
    expect(ProjectDocumentCodec.encode(decoded), ProjectDocumentCodec.encode(document));
  });

  test('round trip keeps a manual switchboard arrangement', () {
    final manual = document.copyWith(
      estimate: const EstimateInput(
        board: BoardArrangement(
          enclosure: (2, 18),
          rails: [
            ['incomer/mcb', 'c2'],
            ['c1'],
          ],
        ),
      ),
    );
    final file = ProjectFileCodec.encode(
      manual,
      appVersion: '0.1.0',
      exportedAt: DateTime.utc(2026),
    );
    final board = ProjectFileCodec.decode(file).estimate.board;
    expect(board.enclosure, (2, 18));
    expect(board.rails, manual.estimate.board.rails);
  });

  test('rejects foreign files and newer versions', () {
    expect(() => ProjectFileCodec.decode('{"a":1}'), throwsA(isA<ProjectFormatException>()));
    final newer = jsonEncode({
      'format': 'shchitovik-project',
      'format_version': 99,
      'document': <String, Object?>{},
    });
    expect(
      () => ProjectFileCodec.decode(newer),
      throwsA(
        isA<ProjectFormatException>().having(
          (e) => e.message,
          'message',
          contains('новой версией'),
        ),
      ),
    );
    final newerSchema = {...ProjectDocumentCodec.encode(document), 'schema_version': 99};
    expect(() => ProjectDocumentCodec.decode(newerSchema), throwsA(isA<ProjectFormatException>()));
  });

  test('corrupted document is reported, not thrown as a raw error', () {
    final broken = {...ProjectDocumentCodec.encode(document)}..remove('input');
    expect(() => ProjectDocumentCodec.decode(broken), throwsA(isA<ProjectFormatException>()));
  });

  test('file name is safe', () {
    expect(ProjectFileCodec.fileName('Дом / дача: 2026'), 'Дом_дача_2026.shchitovik');
    expect(ProjectFileCodec.fileName('   '), 'project.shchitovik');
  });
}
