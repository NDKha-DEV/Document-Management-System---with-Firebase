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
  TextColumn get tags => text().nullable()(); // Comma-separated tags (e.g. "Giáo trình,Lý thuyết,Chương 1")
  TextColumn get locationName => text().nullable()(); // Physical location detail (e.g. "Kệ 3, Ngăn B, Thư viện A")
  RealColumn get latitude => real().nullable()(); // Physical GPS Latitude
  RealColumn get longitude => real().nullable()(); // Physical GPS Longitude
  DateTimeColumn get dateTimeCreated => dateTime()();
  DateTimeColumn get dateTimeModified => dateTime()();

  @override
  Set<Column> get primaryKey => {documentPk};
}
