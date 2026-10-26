// PROTOTYPE — renders the board variants to PNGs: `flutter test --update-goldens <this file>`.
import 'dart:async';
import 'dart:io';

import 'package:common_database/common_database.dart';
import 'package:common_logger/common_logger.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shchitovik/src/feature/catalog_sync/injection.dart';
import 'package:shchitovik/src/feature/circuits/presentation/switchboard_view.dart';
import 'package:shchitovik/src/feature/projects/injection.dart';
import 'package:shchitovik/src/feature/settings/injection.dart';
import 'package:shchitovik/src/logic/composition_root.dart';
import 'package:shchitovik/src/model/app_config.dart';
import 'package:shchitovik/src/model/dependencies_container.dart';
import 'package:shchitovik/src/widget/root_context.dart';

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final List<int> bytes = File('../common/common_ui/assets/fonts/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  }
  await loader.load();
}

void main() {
  late AppDatabase database;

  setUpAll(() async {
    await _font('packages/common_ui/IBMPlexSans', [
      'IBMPlexSans-Regular.ttf',
      'IBMPlexSans-Medium.ttf',
      'IBMPlexSans-SemiBold.ttf',
    ]);
    await _font('packages/common_ui/IBMPlexMono', [
      'IBMPlexMono-Regular.ttf',
      'IBMPlexMono-Medium.ttf',
      'IBMPlexMono-SemiBold.ttf',
    ]);
    await _font('packages/common_ui/Lucide', ['Lucide-300.ttf']);
  });

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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> closeDatabase(WidgetTester tester) async {
    var closed = false;
    unawaited(database.close().then((_) => closed = true));
    for (var i = 0; i < 50 && !closed; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    }
  }

  for (final (demo, tag) in [('1-комнатная квартира', 'flat'), ('Частный дом', 'house')]) {
    for (final (width, height) in [(390.0, 1600.0), (900.0, 1400.0), (1440.0, 1100.0)]) {
      testWidgets('shots $tag $width', (tester) async {
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final DependenciesContainer? deps = await tester.runAsync(dependencies);
        await tester.pumpWidget(
          RootContext(
            compositionResult: CompositionResult(dependencies: deps!, millisecondsSpent: 0),
          ),
        );
        await settle(tester);
        await tester.tap(find.text(demo));
        await settle(tester);
        for (final v in ['', 'A', 'B', 'C']) {
          final BuildContext ctx = tester.element(find.byType(SwitchboardView));
          final GoRouter router = GoRouter.of(ctx);
          final Uri uri = router.routerDelegate.currentConfiguration.uri;
          router.go(
            Uri(path: uri.path, queryParameters: v.isEmpty ? null : {'board': v}).toString(),
          );
          await settle(tester);
          await expectLater(
            find.byType(RootContext),
            matchesGoldenFile('prototype_shots/${tag}_${width.toInt()}_${v.isEmpty ? '0' : v}.png'),
          );
        }
        await closeDatabase(tester);
      });
    }
  }
}
