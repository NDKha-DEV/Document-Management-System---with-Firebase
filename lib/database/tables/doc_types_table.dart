import 'package:drift/drift.dart';

class DocTypes extends Table {
  TextColumn get docTypePk => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get colorHex => text().withDefault(const Constant('#10b981'))();
  TextColumn get icon => text().withDefault(const Constant('file'))();
  IntColumn get order => integer().withDefault(const Constant(0))();
  DateTimeColumn get dateTimeModified => dateTime()();

  @override
  Set<Column> get primaryKey => {docTypePk};
}
