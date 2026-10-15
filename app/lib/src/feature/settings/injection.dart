import 'package:shared_preferences/shared_preferences.dart';

import 'package:shchitovik/src/feature/settings/application/settings_service.dart';
import 'package:shchitovik/src/feature/settings/data/repositories/settings_repository_impl.dart';

/// Container with global settings state.
class const SettingsContainer._(
  /// Service for managing settings.
  final SettingsService settingsService,
) {
  /// Create a new [SettingsContainer] with the given [sharedPreferences].
  static Future<SettingsContainer> create({
    required SharedPreferencesAsync sharedPreferences,
  }) async {
    final settingsRepository = SettingsRepositoryImpl(
      sharedPreferences: sharedPreferences,
    );

    final SettingsServiceImpl settingsService = await SettingsServiceImpl.create(
      repository: settingsRepository,
    );

    return SettingsContainer._(settingsService);
  }
}
