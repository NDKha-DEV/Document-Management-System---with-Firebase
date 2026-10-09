import 'package:drift/drift.dart';

class Subjects extends Table {
  TextColumn get subjectPk => text()();
  TextColumn get name => text().withLength(min: 1, max: 250)();
  TextColumn get code => text().withLength(min: 1, max: 50)();
  TextColumn get teacher => text().nullable()();
  TextColumn get colorHex => text().withDefault(const Constant('#3b82f6'))();
  TextColumn get icon => text().withDefault(const Constant('book'))();
  IntColumn get credits => integer().withDefault(const Constant(3))();
  IntColumn get order => integer().withDefault(const Constant(0))();
  DateTimeColumn get dateTimeModified => dateTime()();

  @override
  Set<Column> get primaryKey => {subjectPk};
}
