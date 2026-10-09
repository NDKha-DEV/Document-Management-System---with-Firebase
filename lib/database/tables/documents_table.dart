import 'package:drift/drift.dart';

class Documents extends Table {
  TextColumn get documentPk => text()();
  TextColumn get title => text().withLength(min: 1, max: 250)();
  TextColumn get note => text().nullable()();
  TextColumn get localFilePath => text().nullable()();
  TextColumn get externalUrl => text().nullable()();
  TextColumn get subjectFk => text()();
  TextColumn get docTypeFk => text()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))(); // 0: To Read, 1: In Progress, 2: Completed
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dateTimeCreated => dateTime()();
  DateTimeColumn get dateTimeModified => dateTime()();

  @override
  Set<Column> get primaryKey => {documentPk};
}
