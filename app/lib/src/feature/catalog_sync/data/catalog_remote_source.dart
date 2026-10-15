import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shchitovik/src/feature/catalog_sync/domain/catalog_manifest.dart';

/// Reads the catalog from the static hosting (`<base>/catalog/…`).
final class CatalogRemoteSource({
  /// Base URL, e.g. `https://example.ru`.
  required final String baseUrl,
  required final http.Client _client,
}) {
  static const _timeout = Duration(seconds: 20);

  Uri _uri(String path) => Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/catalog/$path');

  /// Downloads and parses the manifest.
  Future<CatalogManifest> manifest() async =>
      CatalogManifest.fromJson(jsonDecode(await _get('manifest.json')) as Map<String, Object?>);

  /// Downloads a dataset file as text.
  Future<String> file(String path) => _get(path);

  Future<String> _get(String path) async {
    final http.Response response = await _client.get(_uri(path)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', _uri(path));
    }
    return utf8.decode(response.bodyBytes);
  }
}
