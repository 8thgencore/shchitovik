import 'package:drift/drift.dart';

/// Price catalogs downloaded from the static hosting; replace the embedded ones when present.
@DataClassName('CatalogCacheRow')
class CatalogCache extends Table {
  /// Dataset name (`apparatus_catalog`, `cable_catalog`, …).
  TextColumn get dataset => text()();

  /// Dataset JSON.
  TextColumn get content => text()();

  /// Catalog version from the manifest.
  TextColumn get catalogVersion => text()();

  /// Download time, UTC.
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {dataset};
}
