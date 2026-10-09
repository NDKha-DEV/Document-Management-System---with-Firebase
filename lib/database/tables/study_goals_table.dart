import 'package:drift/drift.dart';

class StudyGoals extends Table {
  TextColumn get goalPk => text()();
  TextColumn get title => text().withLength(min: 1, max: 250)();
  TextColumn get subjectFk => text().nullable()();
  IntColumn get targetCount => integer().withDefault(const Constant(5))();
  IntColumn get completedCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get dateTimeModified => dateTime()();

  @override
  Set<Column> get primaryKey => {goalPk};
}
