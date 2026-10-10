import 'package:common_database/common_database.dart';
import 'package:common_logger/common_logger.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shchitovik/src/feature/catalog_sync/injection.dart';
import 'package:shchitovik/src/feature/projects/injection.dart';
import 'package:shchitovik/src/feature/settings/injection.dart';
import 'package:shchitovik/src/logic/composition_root.dart';
import 'package:shchitovik/src/model/app_config.dart';
import 'package:shchitovik/src/model/dependencies_container.dart';
import 'package:shchitovik/src/widget/root_context.dart';

void main() {
  late AppDatabase database;

  Future<DependenciesContainer> dependencies() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    database = AppDatabase(NativeDatabase.memory());
    return DependenciesContainer(
      logger: Logger(),
      config: const AppConfig(),
      packageInfo: PackageInfo(
        appName: 'Щитовик',
        packageName: 'test',
        version: '0.1.0',
        buildNumber: '1',
      ),
      settingsContainer: await SettingsContainer.create(
        sharedPreferences: SharedPreferencesAsync(),
      ),
      database: database,
      projectsContainer: ProjectsContainer.create(database: database, appVersion: '0.1.0+1'),
      catalogContainer: CatalogContainer.create(database: database, catalogUrl: ''),
    );
  }

  /// Lets database streams and the calculation isolate deliver, then rebuilds.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
  }

  testWidgets('demo project: list → circuits → circuit details → estimate', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final deps = await tester.runAsync(dependencies);
    await tester.pumpWidget(
      RootContext(compositionResult: CompositionResult(dependencies: deps!, millisecondsSpent: 0)),
    );
    await settle(tester);
    expect(find.text('Проектов пока нет'), findsOneWidget);

    await tester.tap(find.text('1-комнатная квартира'));
    await settle(tester);
    expect(find.text('Демо: 1-комнатная квартира'), findsOneWidget);
    expect(find.text('Ввод'), findsWidgets);
    expect(find.textContaining('Рейка 1'), findsOneWidget);

    await tester.tap(find.text('Список'));
    await settle(tester);
    expect(find.textContaining('1. Освещение'), findsOneWidget);

    await tester.tap(find.textContaining('1. Освещение'));
    await settle(tester);
    expect(find.text('Приборы'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Проверки'), 300);
    expect(find.text('Проверки'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Параметры линии'), 300);
    expect(find.text('Длина, м'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle(tester);
    // The «Список» choice is remembered in the settings.
    expect(find.textContaining('1. Освещение'), findsOneWidget);
    await tester.tap(find.text('Смета').first);
    await settle(tester);
    expect(find.text('Итого'), findsOneWidget);

    await tester.tap(find.text('Помещения').first);
    await settle(tester);
    expect(find.text('Кухня'), findsOneWidget);

    await tester.tap(find.text('Объект').first);
    await settle(tester);
    expect(find.text('Название проекта'), findsOneWidget);

    await tester.runAsync(database.close);
  });

  testWidgets('new project: create → add a room from a template → circuits appear', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final deps = await tester.runAsync(dependencies);
    await tester.pumpWidget(
      RootContext(compositionResult: CompositionResult(dependencies: deps!, millisecondsSpent: 0)),
    );
    await settle(tester);

    await tester.tap(find.text('Новый проект'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Моя квартира');
    await tester.tap(find.text('Создать'));
    await settle(tester);
    expect(find.text('Название проекта'), findsOneWidget);

    await tester.tap(find.text('Помещения').first);
    await settle(tester);
    await tester.tap(find.text('Помещение'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Кухня').last);
    await settle(tester);
    expect(find.text('Варочная панель индукционная'), findsOneWidget);

    await tester.tap(find.text('Линии').first);
    await settle(tester);
    await tester.tap(find.text('Список'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.textContaining('Варочная панель индукционная'),
      300,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    expect(find.textContaining('Варочная панель индукционная'), findsOneWidget);

    await tester.runAsync(database.close);
  });

  testWidgets('expanded layout: rail navigation, the board is the home section', (tester) async {
    tester.view.physicalSize = const Size(3200, 2000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final deps = await tester.runAsync(dependencies);
    await tester.pumpWidget(
      RootContext(compositionResult: CompositionResult(dependencies: deps!, millisecondsSpent: 0)),
    );
    await settle(tester);

    await tester.tap(find.text('Частный дом'));
    await settle(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Демо: частный дом · Щит'), findsOneWidget);
    expect(find.textContaining('Рейка 1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('1. '),
      300,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    expect(find.text('Список'), findsNothing);

    await tester.tap(find.text('Помещения'));
    await settle(tester);
    expect(find.text('Демо: частный дом · Помещения'), findsOneWidget);

    await tester.runAsync(database.close);
  });
}
