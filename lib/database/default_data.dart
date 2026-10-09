import 'package:drift/drift.dart';
import 'study_database.dart';

Future<void> populateDefaultStudyData(StudyDatabase db) async {
  final existingSubjects = await db.subjectsDao.getAllSubjects();
  if (existingSubjects.isNotEmpty) return;

  final now = DateTime.now();

  // 1. Khởi tạo Môn học mặc định
  final subMobile = SubjectsCompanion.insert(
    subjectPk: 'sub-mobile-01',
    name: 'Lập trình di động với Flutter',
    code: 'INT3120',
    teacher: const Value('TS. Nguyễn Văn Hùng'),
    colorHex: const Value('#3b82f6'),
    icon: const Value('smartphone'),
    credits: const Value(3),
    order: const Value(1),
    dateTimeModified: now,
  );

  final subAlgo = SubjectsCompanion.insert(
    subjectPk: 'sub-algo-02',
    name: 'Cấu trúc dữ liệu & Giải thuật',
    code: 'INT2204',
    teacher: const Value('PGS.TS. Trần Thị Mai'),
    colorHex: const Value('#10b981'),
    icon: const Value('account_tree'),
    credits: const Value(4),
    order: const Value(2),
    dateTimeModified: now,
  );

  final subDB = SubjectsCompanion.insert(
    subjectPk: 'sub-db-03',
    name: 'Hệ quản trị Cơ sở dữ liệu',
    code: 'INT2211',
    teacher: const Value('ThS. Lê Hoàng Nam'),
    colorHex: const Value('#f59e0b'),
    icon: const Value('storage'),
    credits: const Value(3),
    order: const Value(3),
    dateTimeModified: now,
  );

  final subAI = SubjectsCompanion.insert(
    subjectPk: 'sub-ai-04',
    name: 'Trí tuệ nhân tạo căn bản',
    code: 'INT3401',
    teacher: const Value('TS. Phạm Đức Minh'),
    colorHex: const Value('#8b5cf6'),
    icon: const Value('psychology'),
    credits: const Value(3),
    order: const Value(4),
    dateTimeModified: now,
  );

  await db.subjectsDao.insertSubject(subMobile);
  await db.subjectsDao.insertSubject(subAlgo);
  await db.subjectsDao.insertSubject(subDB);
  await db.subjectsDao.insertSubject(subAI);

  // 2. Khởi tạo Phân loại tài liệu
  final typeSlide = DocTypesCompanion.insert(
    docTypePk: 'type-slide',
    name: 'Slide bài giảng',
    colorHex: const Value('#3b82f6'),
    icon: const Value('slideshow'),
    order: const Value(1),
    dateTimeModified: now,
  );

  final typeExercise = DocTypesCompanion.insert(
    docTypePk: 'type-exercise',
    name: 'Bài tập & Đồ án',
    colorHex: const Value('#ef4444'),
    icon: const Value('assignment'),
    order: const Value(2),
    dateTimeModified: now,
  );

  final typeExam = DocTypesCompanion.insert(
    docTypePk: 'type-exam',
    name: 'Đề thi & Ôn tập',
    colorHex: const Value('#f59e0b'),
    icon: const Value('quiz'),
    order: const Value(3),
    dateTimeModified: now,
  );

  final typeRef = DocTypesCompanion.insert(
    docTypePk: 'type-ref',
    name: 'Tài liệu tham khảo',
    colorHex: const Value('#10b981'),
    icon: const Value('menu_book'),
    order: const Value(4),
    dateTimeModified: now,
  );

  await db.docTypesDao.insertDocType(typeSlide);
  await db.docTypesDao.insertDocType(typeExercise);
  await db.docTypesDao.insertDocType(typeExam);
  await db.docTypesDao.insertDocType(typeRef);

  // 3. Khởi tạo Tài liệu học tập mẫu
  final doc1 = DocumentsCompanion.insert(
    documentPk: 'doc-01',
    title: 'Slide Chương 1: Kiến trúc Flutter & Drift Local-First',
    note: const Value('Tổng quan về Widget tree, State management và SQLite.'),
    localFilePath: const Value(null),
    externalUrl: const Value('https://flutter.dev/docs'),
    subjectFk: 'sub-mobile-01',
    docTypeFk: 'type-slide',
    dueDate: Value(now.add(const Duration(days: 7))),
    status: const Value(2), // Hoàn thành
    isPinned: const Value(true),
    dateTimeCreated: now.subtract(const Duration(days: 2)),
    dateTimeModified: now,
  );

  final doc2 = DocumentsCompanion.insert(
    documentPk: 'doc-02',
    title: 'Bài tập lớn: Xây dựng App Quản lý Tài liệu Học tập',
    note: const Value('Áp dụng nguyên lý Cashew: Local-first, MultiExecutor, StreamProvider.'),
    localFilePath: const Value(null),
    externalUrl: const Value('https://github.com'),
    subjectFk: 'sub-mobile-01',
    docTypeFk: 'type-exercise',
    dueDate: Value(now.add(const Duration(days: 3))),
    status: const Value(1), // Đang làm
    isPinned: const Value(true),
    dateTimeCreated: now.subtract(const Duration(days: 1)),
    dateTimeModified: now,
  );

  final doc3 = DocumentsCompanion.insert(
    documentPk: 'doc-03',
    title: 'Tổng hợp thuật toán Đồ thị: BFS, DFS, Dijkstra',
    note: const Value('Slide tóm tắt các thuật toán đường đi ngắn nhất và cây khung nhỏ nhất.'),
    localFilePath: const Value(null),
    externalUrl: const Value(null),
    subjectFk: 'sub-algo-02',
    docTypeFk: 'type-slide',
    dueDate: Value(now.add(const Duration(days: 5))),
    status: const Value(0), // Cần đọc
    isPinned: const Value(false),
    dateTimeCreated: now,
    dateTimeModified: now,
  );

  final doc4 = DocumentsCompanion.insert(
    documentPk: 'doc-04',
    title: 'Đề cương ôn tập & Đề thi mẫu Cơ sở dữ liệu 2025',
    note: const Value('Bao gồm các bài tập về Đại số quan hệ và Chuẩn hóa 3NF/BCNF.'),
    localFilePath: const Value(null),
    externalUrl: const Value(null),
    subjectFk: 'sub-db-03',
    docTypeFk: 'type-exam',
    dueDate: Value(now.add(const Duration(days: 12))),
    status: const Value(0),
    isPinned: const Value(false),
    dateTimeCreated: now,
    dateTimeModified: now,
  );

  await db.documentsDao.insertDocument(doc1);
  await db.documentsDao.insertDocument(doc2);
  await db.documentsDao.insertDocument(doc3);
  await db.documentsDao.insertDocument(doc4);
}
