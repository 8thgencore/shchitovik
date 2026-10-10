import 'package:drift/drift.dart';

/// Projects stored as documents.
@DataClassName('ProjectRow')
class Projects extends Table {
  /// UUID.
  TextColumn get id => text()();

  /// Name shown to the user.
  TextColumn get name => text()();

  /// Free-form note.
  TextColumn get note => text().withDefault(const Constant(''))();

  /// Version of the document schema (see the app's ProjectDocument migrations).
  IntColumn get schemaVersion => integer()();

  /// `ProjectInput` as JSON.
  TextColumn get inputJson => text()();

  /// `EstimateInput` as JSON.
  TextColumn get estimateJson => text()();

  /// Creation time, UTC.
  DateTimeColumn get createdAt => dateTime()();

  /// Last change, UTC; drives ordering and future synchronization.
  DateTimeColumn get updatedAt => dateTime()();

  /// Soft delete flag (tombstone for synchronization).
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
