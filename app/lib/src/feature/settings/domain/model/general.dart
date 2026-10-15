import 'dart:ui' show Locale;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'general.freezed.dart';
part 'general.g.dart';

/// Possible theme modes for the application.
enum ThemeModeVO() {
  light,
  dark,
  system,
}

/// Interface complexity: the simple mode hides advanced calculation parameters.
enum InterfaceModeVO() {
  simple,
  expert,
}

/// What the circuits step shows in the compact layout.
enum CircuitsViewVO() {
  board,
  list,
}

/// General application settings.
@freezed
abstract class GeneralSettings with _$GeneralSettings {
  const factory({
    @Default(Locale('ru')) @JsonKey(toJson: _localeToJson, fromJson: _localeFromJson) Locale locale,
    @Default(ThemeModeVO.system) ThemeModeVO themeMode,
    @Default(InterfaceModeVO.simple) InterfaceModeVO interfaceMode,
    @Default(CircuitsViewVO.board) CircuitsViewVO circuitsView,
  }) = _GeneralSettings;

  factory fromJson(Map<String, Object?> json) => _$GeneralSettingsFromJson(json);
}

String _localeToJson(Locale locale) => locale.toString();
Locale _localeFromJson(String json) => Locale(json);
