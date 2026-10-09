part of '../study_database.dart';

class DocumentWithDetails {
  final Document document;
  final Subject? subject;
  final DocType? docType;

  DocumentWithDetails({
    required this.document,
    this.subject,
    this.docType,
  });
}

@DriftAccessor(tables: [Documents, Subjects, DocTypes, DeleteLogs])
class DocumentsDao extends DatabaseAccessor<StudyDatabase>
    with _$DocumentsDaoMixin {
  DocumentsDao(StudyDatabase db) : super(db);

  Stream<List<DocumentWithDetails>> watchDocuments({
    String? subjectFk,
    String? docTypeFk,
    int? status,
    String? searchQuery,
    bool? isPinnedOnly,
  }) {
    final query = select(documents).join([
      leftOuterJoin(subjects, subjects.subjectPk.equalsExp(documents.subjectFk)),
      leftOuterJoin(docTypes, docTypes.docTypePk.equalsExp(documents.docTypeFk)),
    ]);

    if (subjectFk != null && subjectFk.isNotEmpty) {
      query.where(documents.subjectFk.equals(subjectFk));
    }

    if (docTypeFk != null && docTypeFk.isNotEmpty) {
      query.where(documents.docTypeFk.equals(docTypeFk));
    }

    if (status != null) {
      query.where(documents.status.equals(status));
    }

    if (isPinnedOnly == true) {
      query.where(documents.isPinned.equals(true));
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim().toLowerCase()}%';
      query.where(documents.title.lower().like(term) |
          documents.note.lower().like(term));
    }

    query.orderBy([
      OrderingTerm.desc(documents.isPinned),
      OrderingTerm.desc(documents.dateTimeCreated),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return DocumentWithDetails(
          document: row.readTable(documents),
          subject: row.readTableOrNull(subjects),
          docType: row.readTableOrNull(docTypes),
        );
      }).toList();
    });
  }

  Stream<List<DocumentWithDetails>> watchDeadlines() {
    final query = select(documents).join([
      leftOuterJoin(subjects, subjects.subjectPk.equalsExp(documents.subjectFk)),
      leftOuterJoin(docTypes, docTypes.docTypePk.equalsExp(documents.docTypeFk)),
    ]);

    query.where(documents.dueDate.isNotNull());
    query.orderBy([
      OrderingTerm.asc(documents.dueDate),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return DocumentWithDetails(
          document: row.readTable(documents),
          subject: row.readTableOrNull(subjects),
          docType: row.readTableOrNull(docTypes),
        );
      }).toList();
    });
  }

  Future<Document?> getDocumentByPk(String pk) {
    return (select(documents)..where((d) => d.documentPk.equals(pk)))
        .getSingleOrNull();
  }

  Future<int> insertDocument(DocumentsCompanion doc) {
    return into(documents).insert(doc);
  }

  Future<bool> updateDocument(DocumentsCompanion doc) {
    return update(documents).replace(doc);
  }

  Future<void> toggleStatus(String pk, int currentStatus) async {
    final newStatus = (currentStatus + 1) % 3;
    await (update(documents)..where((d) => d.documentPk.equals(pk))).write(
      DocumentsCompanion(
        status: Value(newStatus),
        dateTimeModified: Value(DateTime.now()),
      ),
    );
  }

  Future<void> togglePin(String pk, bool currentPinned) async {
    await (update(documents)..where((d) => d.documentPk.equals(pk))).write(
      DocumentsCompanion(
        isPinned: Value(!currentPinned),
        dateTimeModified: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteDocument(String pk) async {
    await transaction(() async {
      await (delete(documents)..where((d) => d.documentPk.equals(pk))).go();
      await into(deleteLogs).insert(DeleteLogsCompanion.insert(
        deleteLogPk: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'Document',
        entryPk: pk,
        dateTimeModified: DateTime.now(),
      ));
    });
  }
}
