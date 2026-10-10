import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:common_database/common_database.dart';
import 'package:crypto/crypto.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:shchitovik/src/feature/catalog_sync/data/catalog_remote_source.dart';
import 'package:shchitovik/src/feature/catalog_sync/domain/catalog_manifest.dart';

/// Outcome of an update check.
enum CatalogUpdateStatus {
  /// A newer catalog was downloaded and activated.
  updated,

  /// The hosted catalog is the one already in use.
  upToDate,

  /// Updates are not configured (no catalog URL).
  disabled,

  /// Network or validation error; the current catalog stays in use.
  failed,
}

/// Provides the price catalog: the downloaded update if valid, otherwise the embedded one.
final class CatalogService {
  CatalogService({required this._database, this._remote, EstimateCatalog? embedded})
    : _embedded = embedded ?? EstimateCatalog.embedded;

  final AppDatabase _database;
  final CatalogRemoteSource? _remote;
  final EstimateCatalog _embedded;
  EstimateCatalog? _current;

  /// Catalog to use for estimates.
  Future<EstimateCatalog> current() async => _current ??= await _loadCached() ?? _embedded;

  /// Checks the hosting and activates a newer catalog.
  ///
  /// Every file is verified by SHA-256 and parsed before anything is stored; the cache is
  /// replaced in one transaction, so a partial download never becomes active.
  Future<CatalogUpdateStatus> checkForUpdates() async {
    final remote = _remote;
    if (remote == null) return CatalogUpdateStatus.disabled;
    try {
      final manifest = await remote.manifest();
      final active = await current();
      if (manifest.catalogVersion == active.catalogVersion) return CatalogUpdateStatus.upToDate;

      final contents = <String, String>{};
      for (final MapEntry(key: dataset, value: file) in manifest.files.entries) {
        final text = await remote.file(file.path);
        if (sha256.convert(utf8.encode(text)).toString() != file.sha256) {
          throw FormatException('Checksum mismatch for $dataset');
        }
        contents[dataset] = text;
      }
      final catalog = EstimateCatalog.fromJsonStrings(contents);
      if (catalog.catalogVersion != manifest.catalogVersion) {
        throw const FormatException('Catalog version does not match the manifest');
      }
      final now = clock.now().toUtc();
      await _database.replaceCatalogCache([
        for (final e in contents.entries)
          CatalogCacheCompanion.insert(
            dataset: e.key,
            content: e.value,
            catalogVersion: manifest.catalogVersion,
            downloadedAt: now,
          ),
      ]);
      _current = catalog;
      return CatalogUpdateStatus.updated;
    } on Object {
      return CatalogUpdateStatus.failed;
    }
  }

  Future<EstimateCatalog?> _loadCached() async {
    final rows = await _database.getCatalogCache();
    final contents = {for (final r in rows) r.dataset: r.content};
    if (!catalogDatasets.every(contents.containsKey)) return null;
    try {
      return EstimateCatalog.fromJsonStrings(contents);
    } on Object {
      return null; // A broken cache must never block estimates.
    }
  }
}
