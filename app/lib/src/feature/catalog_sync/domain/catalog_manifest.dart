import 'package:meta/meta.dart';

/// Datasets that make up a complete price catalog.
const catalogDatasets = [
  'apparatus_catalog',
  'cable_catalog',
  'auxiliary_devices',
  'fallback_prices',
];

/// `catalog/manifest.json` on the static hosting.
///
/// ```json
/// {"schema_version": 1, "catalog_version": "2026-10-1", "published_at": "…",
///  "files": {"apparatus_catalog": {"path": "apparatus_catalog.json", "sha256": "…"}, …}}
/// ```
@immutable
final class const CatalogManifest({
  /// Catalog version.
  required final String catalogVersion,

  /// Files by dataset name: relative path and SHA-256 of the content.
  required final Map<String, ({String path, String sha256})> files,
}) {
  /// Parses the manifest; throws [FormatException] if it is not usable.
  factory fromJson(Map<String, Object?> json) {
    if (json['schema_version'] != supportedSchemaVersion) {
      throw FormatException('Unsupported manifest schema ${json['schema_version']}');
    }
    final Object? files = json['files'];
    if (files is! Map<String, Object?>) {
      throw const FormatException('No files in the manifest');
    }
    final parsed = <String, ({String path, String sha256})>{};
    for (final String dataset in catalogDatasets) {
      final Object? file = files[dataset];
      if (file is! Map<String, Object?> || file['path'] is! String || file['sha256'] is! String) {
        throw FormatException('Missing dataset $dataset');
      }
      parsed[dataset] = (
        path: file['path']! as String,
        sha256: (file['sha256']! as String).toLowerCase(),
      );
    }
    final Object? version = json['catalog_version'];
    if (version is! String || version.isEmpty) {
      throw const FormatException('No catalog version');
    }
    return CatalogManifest(catalogVersion: version, files: parsed);
  }

  /// Manifest schema this app understands.
  static const supportedSchemaVersion = 1;
}
