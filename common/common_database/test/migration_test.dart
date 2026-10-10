import 'package:common_database/common_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Schema 1 as shipped (projects only).
const _schemaV1 = '''
CREATE TABLE "projects" (
  "id" TEXT NOT NULL, "name" TEXT NOT NULL, "note" TEXT NOT NULL DEFAULT '',
  "schema_version" INTEGER NOT NULL, "input_json" TEXT NOT NULL, "estimate_json" TEXT NOT NULL,
  "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL,
  "is_deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("is_deleted" IN (0, 1)),
  PRIMARY KEY ("id"));
INSERT INTO projects VALUES ('p1', 'Старый', '', 1, '{}', '{}', 1767225600, 1767225600, 0);
''';

void main() {
  test('upgrade 1 → 2 keeps projects and adds the catalog cache', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(_schemaV1);
          raw.userVersion = 1;
        },
      ),
    );
    addTearDown(db.close);

    final projects = await db.watchProjects().first;
    expect(projects.single.name, 'Старый');
    expect(await db.getCatalogCache(), isEmpty);
  });
}
