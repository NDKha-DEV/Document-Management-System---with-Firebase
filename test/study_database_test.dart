import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:budget/database/study_database.dart';

void main() {
  late StudyDatabase db;

  setUpAll(() {
    if (Platform.isWindows) {
      open.overrideFor(OperatingSystem.windows, () {
        return DynamicLibrary.open(File('sqlite3.dll').absolute.path);
      });
    }
  });

  setUp(() {
    // Sử dụng in-memory database phục vụ kiểm thử đơn vị
    db = StudyDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Kiểm thử CSDL StudyDatabase & DAOs (Nguyên lý Cashew)', () {
    test('1. Thêm và truy vấn môn học (SubjectsDao)', () async {
      final now = DateTime.now();
      await db.subjectsDao.insertSubject(
        SubjectsCompanion.insert(
          subjectPk: 'sub-test-01',
          name: 'Lập trình di động Flutter',
          code: 'INT3120',
          teacher: const Value('TS. Nguyễn Văn A'),
          dateTimeModified: now,
        ),
      );

      final subjects = await db.subjectsDao.getAllSubjects();
      expect(subjects.length, 1);
      expect(subjects.first.code, 'INT3120');
      expect(subjects.first.name, 'Lập trình di động Flutter');
    });

    test('2. Thêm loại tài liệu và kiểm tra (DocTypesDao)', () async {
      final now = DateTime.now();
      await db.docTypesDao.insertDocType(
        DocTypesCompanion.insert(
          docTypePk: 'type-slide',
          name: 'Slide bài giảng',
          dateTimeModified: now,
        ),
      );

      final types = await db.docTypesDao.getAllDocTypes();
      expect(types.length, 1);
      expect(types.first.name, 'Slide bài giảng');
    });

    test('3. Thêm tài liệu và kiểm tra luồng phản ứng (DocumentsDao Reactive Stream)', () async {
      final now = DateTime.now();

      await db.subjectsDao.insertSubject(
        SubjectsCompanion.insert(
          subjectPk: 'sub-01',
          name: 'Cơ sở dữ liệu',
          code: 'INT2211',
          dateTimeModified: now,
        ),
      );
      await db.docTypesDao.insertDocType(
        DocTypesCompanion.insert(
          docTypePk: 'type-01',
          name: 'Bài tập',
          dateTimeModified: now,
        ),
      );

      // Kiểm tra Stream phản ứng
      final stream = db.documentsDao.watchDocuments();
      expect(stream, emitsInOrder([
        isEmpty, // Lần 1: Chưa có tài liệu
        hasLength(1), // Lần 2: Tự động bắn ra 1 tài liệu sau khi Insert!
      ]));

      // Thực hiện Insert
      await db.documentsDao.insertDocument(
        DocumentsCompanion.insert(
          documentPk: 'doc-01',
          title: 'Bài tập chuẩn hóa 3NF',
          subjectFk: 'sub-01',
          docTypeFk: 'type-01',
          status: const Value(0),
          isPinned: const Value(true),
          dateTimeCreated: now,
          dateTimeModified: now,
        ),
      );

      // Thử toggle trạng thái: Cần đọc (0) -> Đang làm (1)
      await db.documentsDao.toggleStatus('doc-01', 0);
      final docUpdated = await db.documentsDao.getDocumentByPk('doc-01');
      expect(docUpdated?.status, 1);
    });

    test('4. Kiểm tra tính toán thống kê tiến độ học tập (SubjectsDao watchSubjectsWithStats)', () async {
      final now = DateTime.now();

      await db.subjectsDao.insertSubject(
        SubjectsCompanion.insert(
          subjectPk: 'sub-algo',
          name: 'Giải thuật',
          code: 'INT2204',
          dateTimeModified: now,
        ),
      );

      await db.docTypesDao.insertDocType(
        DocTypesCompanion.insert(
          docTypePk: 'type-ex',
          name: 'Bài tập',
          dateTimeModified: now,
        ),
      );

      // Thêm 2 tài liệu: 1 hoàn thành (status=2), 1 đang làm (status=1)
      await db.documentsDao.insertDocument(
        DocumentsCompanion.insert(
          documentPk: 'doc-algo-1',
          title: 'Bài tập 1: Sắp xếp',
          subjectFk: 'sub-algo',
          docTypeFk: 'type-ex',
          status: const Value(2),
          dateTimeCreated: now,
          dateTimeModified: now,
        ),
      );
      await db.documentsDao.insertDocument(
        DocumentsCompanion.insert(
          documentPk: 'doc-algo-2',
          title: 'Bài tập 2: Quy hoạch động',
          subjectFk: 'sub-algo',
          docTypeFk: 'type-ex',
          status: const Value(1),
          dateTimeCreated: now,
          dateTimeModified: now,
        ),
      );

      // Kiểm tra tiến độ
      final statsList = await db.subjectsDao.watchSubjectsWithStats().first;
      expect(statsList.length, 1);
      final algoStats = statsList.first;
      expect(algoStats.totalDocuments, 2);
      expect(algoStats.completedDocuments, 1);
      expect(algoStats.progress, 0.5); // 1/2 = 50%
    });
  });
}
