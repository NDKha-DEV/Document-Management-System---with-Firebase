part of '../study_database.dart';

@DriftAccessor(tables: [StudyGoals, Subjects, DeleteLogs])
class StudyGoalsDao extends DatabaseAccessor<StudyDatabase>
    with _$StudyGoalsDaoMixin {
  StudyGoalsDao(StudyDatabase db) : super(db);

  Stream<List<StudyGoal>> watchAllGoals() {
    return (select(studyGoals)
          ..orderBy([
            (g) => OrderingTerm.asc(g.dueDate),
            (g) => OrderingTerm.asc(g.title)
          ]))
        .watch();
  }

  Future<int> insertGoal(StudyGoalsCompanion goal) {
    return into(studyGoals).insert(goal);
  }

  Future<bool> updateGoal(StudyGoalsCompanion goal) {
    return update(studyGoals).replace(goal);
  }

  Future<void> deleteGoal(String pk) async {
    await transaction(() async {
      await (delete(studyGoals)..where((g) => g.goalPk.equals(pk))).go();
      await into(deleteLogs).insert(DeleteLogsCompanion.insert(
        deleteLogPk: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'Goal',
        entryPk: pk,
        dateTimeModified: DateTime.now(),
      ));
    });
  }
}
