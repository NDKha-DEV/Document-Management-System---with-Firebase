part of '../study_database.dart';

class SubjectWithStats {
  final Subject subject;
  final int totalDocuments;
  final int completedDocuments;

  SubjectWithStats({
    required this.subject,
    required this.totalDocuments,
    required this.completedDocuments,
  });

  double get progress =>
      totalDocuments == 0 ? 0.0 : (completedDocuments / totalDocuments);
}

@DriftAccessor(tables: [Subjects, Documents, DeleteLogs])
class SubjectsDao extends DatabaseAccessor<StudyDatabase>
    with _$SubjectsDaoMixin {
  SubjectsDao(StudyDatabase db) : super(db);

  Stream<List<Subject>> watchAllSubjects() {
    return (select(subjects)
          ..orderBy([
            (s) => OrderingTerm.asc(s.order),
            (s) => OrderingTerm.asc(s.name)
          ]))
        .watch();
  }

  Future<List<Subject>> getAllSubjects() {
    return (select(subjects)
          ..orderBy([
            (s) => OrderingTerm.asc(s.order),
            (s) => OrderingTerm.asc(s.name)
          ]))
        .get();
  }

  Future<Subject?> getSubjectByPk(String pk) {
    return (select(subjects)..where((s) => s.subjectPk.equals(pk)))
        .getSingleOrNull();
  }

  Future<int> insertSubject(SubjectsCompanion subject) {
    return into(subjects).insert(subject);
  }

  Future<bool> updateSubject(SubjectsCompanion subject) {
    return update(subjects).replace(subject);
  }

  Future<void> deleteSubject(String pk) async {
    await transaction(() async {
      await (delete(subjects)..where((s) => s.subjectPk.equals(pk))).go();
      await (delete(documents)..where((d) => d.subjectFk.equals(pk))).go();
      await into(deleteLogs).insert(DeleteLogsCompanion.insert(
        deleteLogPk: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'Subject',
        entryPk: pk,
        dateTimeModified: DateTime.now(),
      ));
    });
  }

  Stream<List<SubjectWithStats>> watchSubjectsWithStats() {
    final query = select(subjects).join([
      leftOuterJoin(documents, documents.subjectFk.equalsExp(subjects.subjectPk)),
    ]);

    return query.watch().map((rows) {
      final Map<String, Subject> subjectMap = {};
      final Map<String, int> totalCount = {};
      final Map<String, int> completedCount = {};

      for (final row in rows) {
        final s = row.readTable(subjects);
        subjectMap[s.subjectPk] = s;
        totalCount.putIfAbsent(s.subjectPk, () => 0);
        completedCount.putIfAbsent(s.subjectPk, () => 0);

        final d = row.readTableOrNull(documents);
        if (d != null) {
          totalCount[s.subjectPk] = (totalCount[s.subjectPk] ?? 0) + 1;
          if (d.status == 2) {
            completedCount[s.subjectPk] =
                (completedCount[s.subjectPk] ?? 0) + 1;
          }
        }
      }

      return subjectMap.values.map((s) {
        return SubjectWithStats(
          subject: s,
          totalDocuments: totalCount[s.subjectPk] ?? 0,
          completedDocuments: completedCount[s.subjectPk] ?? 0,
        );
      }).toList();
    });
  }
}
