import 'dart:convert';
import 'dart:io';

import 'package:norms_data/src/generated/embedded_datasets.dart';
import 'package:test/test.dart';

import '../tool/embed_data.dart';

void main() {
  test('embedded datasets are in sync with data/*.json (run tool/embed_data.dart)', () {
    final String expected = generateEmbeddedDatasets(Directory('data'));
    final String actual = File('lib/src/generated/embedded_datasets.dart').readAsStringSync();
    expect(actual, expected);
  });

  test('every dataset declares version and known source documents', () {
    final documents = jsonDecode(embeddedDatasets['documents']!) as Map<String, Object?>;
    final Set<dynamic> known = {
      for (final d in documents['documents']! as List<Object?>) (d! as Map)['id'],
    };
    for (final MapEntry<String, String> entry in embeddedDatasets.entries.where(
      (e) => e.key != 'documents',
    )) {
      final json = jsonDecode(entry.value) as Map<String, Object?>;
      expect(json['dataset_version'], isA<String>(), reason: entry.key);
      final source = json['source']! as Map<String, Object?>;
      final ids = source['documents']! as List<Object?>;
      expect(ids, isNotEmpty, reason: entry.key);
      for (final id in ids) {
        expect(known, contains(id), reason: '${entry.key} → $id');
      }
    }
  });
}
