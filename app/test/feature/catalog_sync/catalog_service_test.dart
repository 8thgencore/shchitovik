import 'dart:convert';

import 'package:common_database/common_database.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shchitovik/src/feature/catalog_sync/application/catalog_service.dart';
import 'package:shchitovik/src/feature/catalog_sync/data/catalog_remote_source.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Hosted files: the embedded catalogs with a new version.
  Map<String, String> hostedFiles(String version) => {
    for (final e in embeddedCatalogs.entries)
      e.key: e.key == 'apparatus_catalog'
          ? jsonEncode({...jsonDecode(e.value) as Map<String, Object?>, 'catalog_version': version})
          : e.value,
  };

  http.Client server(Map<String, String> files, {String? version, bool corrupt = false}) =>
      MockClient((request) async {
        final name = request.url.pathSegments.last;
        if (name == 'manifest.json') {
          return http.Response(
            jsonEncode({
              'schema_version': 1,
              'catalog_version': version,
              'files': {
                for (final e in files.entries)
                  e.key: {
                    'path': '${e.key}.json',
                    'sha256': sha256.convert(utf8.encode(e.value)).toString(),
                  },
              },
            }),
            200,
          );
        }
        final dataset = name.replaceAll('.json', '');
        final body = files[dataset];
        if (body == null) return http.Response('', 404);
        return http.Response.bytes(utf8.encode(corrupt ? '${body}x' : body), 200);
      });

  CatalogService service(http.Client client) => CatalogService(
    database: db,
    remote: CatalogRemoteSource(baseUrl: 'https://example.test/', client: client),
  );

  test('without a URL the embedded catalog is used and updates are disabled', () async {
    final s = CatalogService(database: db);
    expect((await s.current()).catalogVersion, EstimateCatalog.embedded.catalogVersion);
    expect(await s.checkForUpdates(), CatalogUpdateStatus.disabled);
  });

  test('a newer valid catalog is downloaded, activated and survives a restart', () async {
    final files = hostedFiles('2027-01-1');
    expect(
      await service(server(files, version: '2027-01-1')).checkForUpdates(),
      CatalogUpdateStatus.updated,
    );
    final restarted = CatalogService(database: db);
    expect((await restarted.current()).catalogVersion, '2027-01-1');
  });

  test('same version → up to date', () async {
    final version = EstimateCatalog.embedded.catalogVersion;
    final files = hostedFiles(version);
    expect(
      await service(server(files, version: version)).checkForUpdates(),
      CatalogUpdateStatus.upToDate,
    );
  });

  test('checksum mismatch keeps the current catalog', () async {
    final files = hostedFiles('2027-01-1');
    final s = service(server(files, version: '2027-01-1', corrupt: true));
    expect(await s.checkForUpdates(), CatalogUpdateStatus.failed);
    expect((await s.current()).catalogVersion, EstimateCatalog.embedded.catalogVersion);
    expect(await db.getCatalogCache(), isEmpty);
  });

  test('network error keeps the current catalog', () async {
    final s = service(MockClient((_) async => throw http.ClientException('offline')));
    expect(await s.checkForUpdates(), CatalogUpdateStatus.failed);
  });
}
