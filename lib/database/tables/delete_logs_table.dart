import 'package:drift/drift.dart';

class DeleteLogs extends Table {
  TextColumn get deleteLogPk => text()();
  TextColumn get type => text()(); // 'Document', 'Subject', 'DocType', 'Goal'
  TextColumn get entryPk => text()();
  DateTimeColumn get dateTimeModified => dateTime()();

  @override
  Set<Column> get primaryKey => {deleteLogPk};
}
