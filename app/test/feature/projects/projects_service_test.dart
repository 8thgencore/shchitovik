import 'package:clock/clock.dart';
import 'package:common_database/common_database.dart';
import 'package:drift/native.dart';
import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shchitovik/src/feature/projects/application/projects_service.dart';
import 'package:shchitovik/src/feature/projects/data/repositories/projects_repository_impl.dart';
import 'package:shchitovik/src/feature/projects/public/domain/project_document_codec.dart';

void main() {
  late AppDatabase db;
  late ProjectsService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ProjectsService(
      repository: ProjectsRepositoryImpl(database: db),
      appVersion: '0.1.0+1',
    );
  });
  tearDown(() => db.close());

  test('demo project is stored and read back losslessly', () async {
    final created = await service.createDemo(DemoProjectKind.house);
    final read = await service.watchProject(created.id).first;
    expect(read!.name, 'Демо: частный дом');
    expect(read.input.toJson(), DemoProjects.house().toJson());
    expect(read.id, isNot(isEmpty));
  });

  test('update keeps id and creation time, bumps update time; list is ordered', () async {
    final a = await withClock(
      Clock.fixed(DateTime.utc(2026)),
      () => service.create(
        name: 'A',
        objectType: ObjectType.apartment,
        supplyPhases: SupplyPhases.single,
      ),
    );
    await withClock(
      Clock.fixed(DateTime.utc(2026, 1, 2)),
      () => service.createDemo(DemoProjectKind.oneRoomApartment),
    );
    final updated = await withClock(
      Clock.fixed(DateTime.utc(2026, 1, 3)),
      () => service.update(
        a.id,
        (d) => d.copyWith(
          name: 'A2',
          estimate: const EstimateInput(scenario: EstimateScenario.premium),
        ),
      ),
    );
    expect(updated.createdAt, a.createdAt);
    expect(updated.updatedAt, DateTime.utc(2026, 1, 3));
    final list = await service.watchProjects().first;
    expect(list.first.name, 'A2');
    expect((await service.watchProject(a.id).first)!.estimate.scenario, EstimateScenario.premium);
  });

  test('export → import creates an independent copy', () async {
    final source = await service.createDemo(DemoProjectKind.oneRoomApartment);
    final file = await service.export(source.id);
    final imported = await service.import(file);
    expect(imported.id, isNot(source.id));
    expect(imported.input.toJson(), source.input.toJson());
    expect((await service.watchProjects().first).length, 2);
  });

  test('duplicate and delete', () async {
    final source = await service.createDemo(DemoProjectKind.threeRoomApartment);
    final copy = await service.duplicate(source.id);
    expect(copy.name, 'Демо: 3-комнатная квартира (копия)');
    await service.delete(source.id);
    expect((await service.watchProjects().first).map((p) => p.id), [copy.id]);
  });

  test('invalid file gives a user-facing error', () async {
    expect(() => service.import('not json'), throwsA(isA<ProjectFormatException>()));
  });
}
