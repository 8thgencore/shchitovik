import 'package:flutter_test/flutter_test.dart';
import 'package:shchitovik/src/feature/settings/application/settings_service.dart';
import 'package:shchitovik/src/feature/settings/domain/model/general.dart';
import 'package:shchitovik/src/feature/settings/domain/model/settings.dart';
import 'package:shchitovik/src/feature/settings/domain/repositories/settings_repository.dart';

final class _InMemorySettingsRepository() implements SettingsRepository {
  Settings? stored;

  @override
  Future<Settings> read() async => stored ?? const Settings();

  @override
  Future<void> save(Settings settings) async => stored = settings;
}

void main() {
  test('defaults to Russian locale and simple interface mode', () async {
    final SettingsServiceImpl service = await SettingsServiceImpl.create(
      repository: _InMemorySettingsRepository(),
    );

    expect(service.current.general.locale.languageCode, 'ru');
    expect(service.current.general.interfaceMode, InterfaceModeVO.simple);
    expect(service.current.general.circuitsView, CircuitsViewVO.board);
  });

  test('update persists and emits new settings', () async {
    final repository = _InMemorySettingsRepository();
    final SettingsServiceImpl service = await SettingsServiceImpl.create(repository: repository);

    final Future<void> emitted = expectLater(
      service.stream.map((s) => s.general.themeMode),
      emits(ThemeModeVO.dark),
    );
    await service.update(
      (s) => s.copyWith(general: s.general.copyWith(themeMode: ThemeModeVO.dark)),
    );

    await emitted;
    expect(repository.stored?.general.themeMode, ThemeModeVO.dark);
  });

  test('settings survive JSON round trip', () {
    const settings = Settings(
      general: GeneralSettings(
        themeMode: ThemeModeVO.light,
        interfaceMode: InterfaceModeVO.expert,
        circuitsView: CircuitsViewVO.list,
      ),
    );

    expect(Settings.fromJson(settings.toJson()), settings);
  });
}
