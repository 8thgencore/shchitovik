import 'package:common_database/src/tables/catalog_cache_table.dart';
import 'package:common_database/src/tables/projects_table.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// {@template database}
/// The drift-managed database of the app.
///
/// Projects are stored as documents (input and estimate choices as JSON); calculation
/// results are never stored — they are recomputed from the input.
/// {@endtemplate}
@DriftDatabase(tables: [Projects, CatalogCache])
class AppDatabase extends _$AppDatabase {
  /// {@macro database}
  new(super.e);

  /// {@macro database}
  new defaults({required String name})
    : super(
        driftDatabase(
          name: name,
          native: const DriftNativeOptions(shareAcrossIsolates: true),
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(catalogCache);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Live list of projects that are not deleted, most recently updated first.
  Stream<List<ProjectRow>> watchProjects() =>
      (select(projects)
            ..where((p) => p.isDeleted.equals(false))
            ..orderBy([(p) => OrderingTerm.desc(p.updatedAt), (p) => OrderingTerm.asc(p.id)]))
          .watch();

  /// Live project by [id]; `null` if missing or deleted.
  Stream<ProjectRow?> watchProject(String id) => (select(
    projects,
  )..where((p) => p.id.equals(id) & p.isDeleted.equals(false))).watchSingleOrNull();

  /// Project by [id], including deleted ones.
  Future<ProjectRow?> getProject(String id) =>
      (select(projects)..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Inserts or replaces a project.
  Future<void> upsertProject(ProjectsCompanion row) => into(projects).insertOnConflictUpdate(row);

  /// Cached catalog datasets; empty if no update has been downloaded.
  Future<List<CatalogCacheRow>> getCatalogCache() => select(catalogCache).get();

  /// Replaces all cached catalog datasets atomically.
  Future<void> replaceCatalogCache(List<CatalogCacheCompanion> rows) => transaction(() async {
    await delete(catalogCache).go();
    await batch((b) => b.insertAll(catalogCache, rows));
  });

  /// Marks a project deleted (kept for future synchronization).
  Future<void> softDeleteProject(String id, DateTime at) =>
      (update(projects)..where((p) => p.id.equals(id))).write(
        ProjectsCompanion(isDeleted: const Value(true), updatedAt: Value(at)),
      );
}
