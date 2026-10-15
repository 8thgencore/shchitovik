import 'package:common_database/common_database.dart';
import 'package:http/http.dart' as http;
import 'package:shchitovik/src/feature/catalog_sync/application/catalog_service.dart';
import 'package:shchitovik/src/feature/catalog_sync/data/catalog_remote_source.dart';

/// Dependencies of catalog updates.
class const CatalogContainer._(
  /// Catalog provider.
  final CatalogService catalogService,
) {
  /// Creates the container; updates are disabled when [catalogUrl] is empty.
  factory create({required AppDatabase database, required String catalogUrl}) => CatalogContainer._(
    CatalogService(
      database: database,
      remote: catalogUrl.isEmpty
          ? null
          : CatalogRemoteSource(baseUrl: catalogUrl, client: http.Client()),
    ),
  );
}
