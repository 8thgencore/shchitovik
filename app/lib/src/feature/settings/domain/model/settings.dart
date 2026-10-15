import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shchitovik/src/feature/settings/domain/model/general.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

/// Settings for the app.
@freezed
abstract class Settings with _$Settings {
  const factory({@Default(GeneralSettings()) GeneralSettings general}) = _Settings;

  factory fromJson(Map<String, Object?> json) => _$SettingsFromJson(json);
}
