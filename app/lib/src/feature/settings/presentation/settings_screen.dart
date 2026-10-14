import 'package:common_translations/common_translations.dart';
import 'package:common_ui/common_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shchitovik/src/feature/settings/domain/model/general.dart';
import 'package:shchitovik/src/feature/settings/presentation/settings_scope.dart';
import 'package:shchitovik/src/logic/app_router.dart';
import 'package:shchitovik/src/widget/form_fields.dart';

/// Screen with application settings.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.translations;
    final general = SettingsScope.of(context).general;

    void update(GeneralSettings Function(GeneralSettings) change) => SettingsScope.update(
      context,
      (settings) => settings.copyWith(general: change(settings.general)),
    );

    return Scaffold(
      appBar: UiTopBar(
        title: t.settingsTitle,
        large: context.isExpandedLayout,
        leading: UiIconButton(
          icon: UiIcons.back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.projects),
        ),
      ),
      body: PageBody(
        maxWidth: UiBreakpoints.formMax,
        children: [
          UiFieldGroup(
            title: t.interfaceModeTitle,
            children: [
              Text(
                t.interfaceModeHint,
                style: UiTextStyles.bodySmall.copyWith(color: context.uiColors.textMuted),
              ),
              UiSegmented<InterfaceModeVO>(
                segments: [
                  UiSegment(value: InterfaceModeVO.simple, label: t.interfaceModeSimple),
                  UiSegment(value: InterfaceModeVO.expert, label: t.interfaceModeExpert),
                ],
                selected: general.interfaceMode,
                onChanged: (v) => update((g) => g.copyWith(interfaceMode: v)),
              ),
            ],
          ),
          UiFieldGroup(
            title: t.themeModeTitle,
            children: [
              UiSegmented<ThemeModeVO>(
                segments: [
                  UiSegment(value: ThemeModeVO.system, label: t.themeModeSystem),
                  UiSegment(value: ThemeModeVO.light, label: t.themeModeLight),
                  UiSegment(value: ThemeModeVO.dark, label: t.themeModeDark),
                ],
                selected: general.themeMode,
                onChanged: (v) => update((g) => g.copyWith(themeMode: v)),
              ),
            ],
          ),
          if (kDebugMode)
            UiCard(
              child: UiListRow(
                leading: const Icon(UiIcons.board),
                title: 'Компоненты интерфейса',
                subtitle: 'Только в отладочной сборке',
                chevron: true,
                onTap: () => context.go(AppRoutes.uiGallery),
              ),
            ),
        ],
      ),
    );
  }
}
