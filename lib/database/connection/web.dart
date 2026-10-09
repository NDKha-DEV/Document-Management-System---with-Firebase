import 'package:drift/web.dart';
import '../study_database.dart';

Future<StudyDatabase> constructDb(String dbName) async {
  return StudyDatabase(
    WebDatabase.withStorage(
      await DriftWebStorage.indexedDbIfSupported(dbName),
      logStatements: false,
    ),
  );
}
