import 'dart:async';

import 'package:common_database/common_database.dart';
import 'package:common_logger/common_logger.dart';
import 'package:common_ui/common_ui.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shchitovik/src/feature/catalog_sync/injection.dart';
import 'package:shchitovik/src/feature/circuits/presentation/switchboard_view.dart';
import 'package:shchitovik/src/feature/projects/injection.dart';
import 'package:shchitovik/src/feature/projects/public/presentation/project_bloc.dart';
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

  /// Finds a `material_ui` [Tooltip] by its message.
  ///
  /// `find.byTooltip` matches only the `flutter/material` tooltip.
  Finder byTooltip(String message) =>
      find.byWidgetPredicate((widget) => widget is Tooltip && widget.message == message);

  /// Lets database streams and the calculation isolate deliver, then rebuilds.
  ///
  /// The final pump advances the fake clock past a Material route transition.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Closes the database from the fake zone, pumping until it is done.
  ///
  /// Drift releases a cancelled stream query with a zero timer in the zone that created it;
  /// a `close` awaited in the real zone would wait for that fake timer forever.
  Future<void> closeDatabase(WidgetTester tester) async {
    var closed = false;
    unawaited(database.close().then((_) => closed = true));
    for (var i = 0; i < 50 && !closed; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    }
    expect(closed, isTrue, reason: 'database did not close');
  }

  testWidgets('demo project: list → circuits → circuit details → estimate', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final DependenciesContainer? deps = await tester.runAsync(dependencies);
    await tester.pumpWidget(
      RootContext(compositionResult: CompositionResult(dependencies: deps!, millisecondsSpent: 0)),
    );
    await settle(tester);
    expect(find.text('Проектов пока нет'), findsOneWidget);

    await tester.tap(find.text('1-комнатная квартира'));
    await settle(tester);
    expect(find.text('Демо: 1-комнатная квартира'), findsOneWidget);
    expect(find.text('Ввод'), findsWidgets);
    expect(find.textContaining('РЕЙКА 1'), findsOneWidget);
    expect(find.byType(UiListRow), findsNothing);

    await tester.tap(find.text('Список'));
    await settle(tester);
    expect(find.byType(UiListRow), findsWidgets);

    // The review notice of the assumed loop impedance sits above the list.
    expect(find.text('15 линий требуют проверки'), findsOneWidget);
    await tester.ensureVisible(find.textContaining('Освещение').first);
    await settle(tester);
    await tester.tap(find.textContaining('Освещение').first);
    await settle(tester);
    final Finder page = find
        .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    expect(find.text('Ток КЗ посчитан по принятому сопротивлению сети'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Приборы'), 300, scrollable: page);
    expect(find.text('Приборы'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Проверки'), 300, scrollable: page);
    expect(find.text('Проверки'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Параметры линии'), 300, scrollable: page);
    expect(find.text('Длина, м'), findsOneWidget);

    await tester.tap(byTooltip('Назад'));
    await settle(tester);
    // The «Список» choice is remembered in the settings.
    expect(find.byType(UiListRow), findsWidgets);
    await tester.tap(find.text('Смета').first);
    await settle(tester);
    expect(find.text('Итого'), findsOneWidget);

    await tester.tap(find.text('Помещения').first);
    await settle(tester);
    expect(find.text('Кухня'), findsOneWidget);

    await tester.tap(find.text('Объект').first);
    await settle(tester);
    expect(find.text('Название проекта'), findsOneWidget);

    await closeDatabase(tester);
  });

  testWidgets('new project: create → add a room from a template → circuits appear', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final DependenciesContainer? deps = await tester.runAsync(dependencies);
    await tester.pumpWidget(
      RootContext(compositionResult: CompositionResult(dependencies: deps!, millisecondsSpent: 0)),
    );
    await settle(tester);

    await tester.tap(find.text('Создать проект'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Моя квартира');
    await tester.tap(find.text('Создать'));
    await settle(tester);
    expect(find.text('Название проекта'), findsOneWidget);

    await tester.tap(find.text('Помещения').first);
    await settle(tester);
    await tester.tap(find.text('Добавить помещение'));
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

    await closeDatabase(tester);
  });

  testWidgets('expanded layout: sidebar navigation, the board is the home section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(3200, 2000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final DependenciesContainer? deps = await tester.runAsync(dependencies);
    await tester.pumpWidget(
      RootContext(compositionResult: CompositionResult(dependencies: deps!, millisecondsSpent: 0)),
    );
    await settle(tester);

    await tester.tap(find.text('Частный дом'));
    await settle(tester);
    final Finder title = find.descendant(of: find.byType(UiTopBar), matching: find.text('Щит'));
    expect(find.byType(UiSidebar), findsOneWidget);
    expect(find.text('Демо: частный дом'), findsOneWidget);
    expect(title, findsOneWidget);
    expect(find.textContaining('РЕЙКА 1'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(UiTable),
      300,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    expect(find.text('Список'), findsNothing);

    await tester.tap(find.text('Помещения'));
    await settle(tester);
    expect(
      find.descendant(of: find.byType(UiTopBar), matching: find.text('Помещения')),
      findsOneWidget,
    );

    await closeDatabase(tester);
  });

  testWidgets('board: rearrange a device, the arrangement is saved, reset returns to auto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(3200, 2000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final DependenciesContainer? deps = await tester.runAsync(dependencies);
    await tester.pumpWidget(
      RootContext(compositionResult: CompositionResult(dependencies: deps!, millisecondsSpent: 0)),
    );
    await settle(tester);
    await tester.tap(find.text('Частный дом'));
    await settle(tester);

    expect(find.text('Раскладка вручную'), findsNothing);
    await tester.tap(find.text('Переставить'));
    await tester.pump();
    final Finder incomer = find.descendant(
      of: find.byType(SwitchboardView),
      matching: find.text('Ввод'),
    );
    await tester.tap(incomer);
    await tester.pump();
    await tester.tap(byTooltip('Сдвинуть вправо'));
    await settle(tester);
    // The arrangement comes back from the database through the project stream.
    expect(find.text('Раскладка вручную'), findsOneWidget);
    final ProjectReady board = tester.widget<SwitchboardView>(find.byType(SwitchboardView)).state;
    expect(board.document.estimate.board.rails!.first.take(2), [
      isNot('incomer/mcb'),
      'incomer/mcb',
    ]);

    await tester.tap(find.text('Готово'));
    await tester.pump();
    await tester.tap(find.text('Сбросить раскладку'));
    await settle(tester);
    expect(find.text('Раскладка вручную'), findsNothing);

    await closeDatabase(tester);
  });
}
