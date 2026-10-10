import 'dart:io';

import 'package:test/test.dart';

import '../tool/embed_data.dart';

void main() {
  test('embedded catalogs are in sync with data/*.json (run tool/embed_data.dart)', () {
    expect(
      File('lib/src/generated/embedded_catalogs.dart').readAsStringSync(),
      generateEmbeddedCatalogs(Directory('data')),
    );
  });
}
