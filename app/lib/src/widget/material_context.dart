import 'package:common_translations/common_translations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shchitovik/src/feature/settings/domain/model/general.dart';
import 'package:shchitovik/src/feature/settings/presentation/settings_scope.dart';
import 'package:shchitovik/src/logic/app_router.dart';
import 'package:shchitovik/src/widget/media_query_override.dart';

/// Entry point for the application that uses [MaterialApp].
class MaterialContext extends StatefulWidget {
  const MaterialContext({super.key});

  @override
  State<MaterialContext> createState() => _MaterialContextState();
}

class _MaterialContextState extends State<MaterialContext> {
  /// This global key is needed for Flutter to work properly
  /// when Widgets Inspector is enabled.
  static final _globalKey = GlobalKey(debugLabel: 'MaterialContext');

  // Seed color is temporary until the design system is introduced.
  static const _seedColor = Color(0xFF1565C0);

  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final themeMode = settings.general.themeMode;
    final locale = settings.general.locale;

    final materialThemeMode = switch (themeMode) {
      ThemeModeVO.system => ThemeMode.system,
      ThemeModeVO.light => ThemeMode.light,
      ThemeModeVO.dark => ThemeMode.dark,
    };

    return MaterialApp.router(
      onGenerateTitle: (context) => context.translations.appTitle,
      localizationsDelegates: CommonTranslations.localizationsDelegates,
      supportedLocales: CommonTranslations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: _seedColor),
      darkTheme: ThemeData(colorSchemeSeed: _seedColor, brightness: Brightness.dark),
      themeMode: materialThemeMode,
      locale: locale,
      routerConfig: _router,
      builder: (context, child) {
        return KeyedSubtree(
          key: _globalKey,
          child: MediaQueryRootOverride(child: child!),
        );
      },
    );
  }
}
