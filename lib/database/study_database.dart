import 'package:drift/drift.dart';
import 'tables/subjects_table.dart';
import 'tables/doc_types_table.dart';
import 'tables/documents_table.dart';
import 'tables/study_goals_table.dart';
import 'tables/delete_logs_table.dart';
import 'tables/app_settings_table.dart';

export 'connection/shared.dart';

part 'study_database.g.dart';
part 'daos/subjects_dao.dart';
part 'daos/doc_types_dao.dart';
part 'daos/documents_dao.dart';
part 'daos/study_goals_dao.dart';

@DriftDatabase(
  tables: [
    Subjects,
    DocTypes,
    Documents,
    StudyGoals,
    DeleteLogs,
    AppSettings,
  ],
  daos: [
    SubjectsDao,
    DocTypesDao,
    DocumentsDao,
    StudyGoalsDao,
  ],
)
class StudyDatabase extends _$StudyDatabase {
  StudyDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
      );
}
