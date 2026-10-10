import 'package:common_database/common_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  ProjectsCompanion row(String id, DateTime updated) => ProjectsCompanion.insert(
    id: id,
    name: 'Проект $id',
    schemaVersion: 1,
    inputJson: '{}',
    estimateJson: '{}',
    createdAt: DateTime.utc(2026),
    updatedAt: updated,
  );

  test('upsert, order by update time, soft delete', () async {
    await db.upsertProject(row('a', DateTime.utc(2026, 2)));
    await db.upsertProject(row('b', DateTime.utc(2026, 3)));
    expect((await db.watchProjects().first).map((p) => p.id), ['b', 'a']);

    await db.upsertProject(
      row('a', DateTime.utc(2026, 4)).copyWith(name: const Value('Новое имя')),
    );
    final list = await db.watchProjects().first;
    expect(list.map((p) => p.id), ['a', 'b']);
    expect(list.first.name, 'Новое имя');

    await db.softDeleteProject('a', DateTime.utc(2026, 5));
    expect((await db.watchProjects().first).map((p) => p.id), ['b']);
    expect(await db.watchProject('a').first, isNull);
    expect((await db.getProject('a'))!.isDeleted, isTrue);
  });

  test('catalog cache is replaced atomically', () async {
    CatalogCacheCompanion row(String dataset, String version) => CatalogCacheCompanion.insert(
      dataset: dataset,
      content: '{}',
      catalogVersion: version,
      downloadedAt: DateTime.utc(2026),
    );
    await db.replaceCatalogCache([row('a', '1'), row('b', '1')]);
    await db.replaceCatalogCache([row('a', '2')]);
    final rows = await db.getCatalogCache();
    expect(rows.map((r) => (r.dataset, r.catalogVersion)), [('a', '2')]);
  });
}
