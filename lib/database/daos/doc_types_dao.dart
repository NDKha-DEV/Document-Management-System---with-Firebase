part of '../study_database.dart';

@DriftAccessor(tables: [DocTypes, DeleteLogs])
class DocTypesDao extends DatabaseAccessor<StudyDatabase>
    with _$DocTypesDaoMixin {
  DocTypesDao(StudyDatabase db) : super(db);

  Stream<List<DocType>> watchAllDocTypes() {
    return (select(docTypes)
          ..orderBy([
            (t) => OrderingTerm.asc(t.order),
            (t) => OrderingTerm.asc(t.name)
          ]))
        .watch();
  }

  Future<List<DocType>> getAllDocTypes() {
    return (select(docTypes)
          ..orderBy([
            (t) => OrderingTerm.asc(t.order),
            (t) => OrderingTerm.asc(t.name)
          ]))
        .get();
  }

  Future<int> insertDocType(DocTypesCompanion docType) {
    return into(docTypes).insert(docType);
  }

  Future<bool> updateDocType(DocTypesCompanion docType) {
    return update(docTypes).replace(docType);
  }

  Future<void> deleteDocType(String pk) async {
    await transaction(() async {
      await (delete(docTypes)..where((t) => t.docTypePk.equals(pk))).go();
      await into(deleteLogs).insert(DeleteLogsCompanion.insert(
        deleteLogPk: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'DocType',
        entryPk: pk,
        dateTimeModified: DateTime.now(),
      ));
    });
  }
}
