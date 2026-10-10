import 'package:common_translations/common_translations.dart';
import 'package:flutter/material.dart';
import 'package:shchitovik/src/feature/settings/domain/model/general.dart';
import 'package:shchitovik/src/feature/settings/presentation/settings_scope.dart';

/// Screen with application settings.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final translations = context.translations;
    final general = SettingsScope.of(context).general;
    final themeMode = general.themeMode;

    return Scaffold(
      appBar: AppBar(title: Text(translations.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            title: Text(translations.interfaceModeTitle),
            subtitle: Text(translations.interfaceModeHint),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<InterfaceModeVO>(
              segments: [
                ButtonSegment(
                  value: InterfaceModeVO.simple,
                  label: Text(translations.interfaceModeSimple),
                ),
                ButtonSegment(
                  value: InterfaceModeVO.expert,
                  label: Text(translations.interfaceModeExpert),
                ),
              ],
              selected: {general.interfaceMode},
              onSelectionChanged: (selection) => SettingsScope.update(
                context,
                (settings) => settings.copyWith(
                  general: settings.general.copyWith(interfaceMode: selection.single),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(title: Text(translations.themeModeTitle)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeModeVO>(
              segments: [
                ButtonSegment(
                  value: ThemeModeVO.system,
                  label: Text(translations.themeModeSystem),
                ),
                ButtonSegment(value: ThemeModeVO.light, label: Text(translations.themeModeLight)),
                ButtonSegment(value: ThemeModeVO.dark, label: Text(translations.themeModeDark)),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) => SettingsScope.update(
                context,
                (settings) => settings.copyWith(
                  general: settings.general.copyWith(themeMode: selection.single),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
