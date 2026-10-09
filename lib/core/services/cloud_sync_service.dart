import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/study_database.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  FirebaseFirestore? get _firestore {
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseFirestore.instance;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Thực hiện đồng bộ hai chiều toàn bộ dữ liệu (Subjects & Documents)
  Future<SyncResult> syncAll(StudyDatabase db) async {
    final firestore = _firestore;
    final user = FirebaseAuth.instance.currentUser;

    if (firestore == null || user == null) {
      return SyncResult(
        success: false,
        message: 'Bạn chưa đăng nhập Google hoặc Firebase chưa sẵn sàng.',
      );
    }

    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Tiến trình đồng bộ đang chạy, vui lòng chờ trong giây lát.',
      );
    }

    _isSyncing = true;
    int pushedCount = 0;
    int pulledCount = 0;

    try {
      final userDocRef = firestore.collection('users').doc(user.uid);

      // 1. Đồng bộ Môn Học (Subjects) lên Cloud
      final localSubjects = await db.subjectsDao.getAllSubjects();
      for (final sub in localSubjects) {
        await userDocRef.collection('subjects').doc(sub.subjectPk).set({
          'subjectPk': sub.subjectPk,
          'name': sub.name,
          'code': sub.code,
          'colorHex': sub.colorHex,
          'teacher': sub.teacher,
          'credits': sub.credits,
          'dateTimeModified': sub.dateTimeModified.toIso8601String(),
        }, SetOptions(merge: true));
        pushedCount++;
      }

      // 2. Kéo Môn Học từ Cloud về SQLite nếu chưa có
      final remoteSubjects = await userDocRef.collection('subjects').get();
      for (final doc in remoteSubjects.docs) {
        final data = doc.data();
        final existing = localSubjects.where((s) => s.subjectPk == doc.id).toList();
        if (existing.isEmpty) {
          await db.subjectsDao.insertSubject(
            SubjectsCompanion.insert(
              subjectPk: data['subjectPk'] ?? doc.id,
              name: data['name'] ?? '',
              code: data['code'] ?? '',
              colorHex: drift.Value(data['colorHex']),
              teacher: drift.Value(data['teacher']),
              credits: drift.Value(data['credits'] ?? 3),
              dateTimeModified: DateTime.tryParse(data['dateTimeModified'] ?? '') ?? DateTime.now(),
            ),
          );
          pulledCount++;
        }
      }

      // 3. Đồng bộ Tài Liệu (Documents) lên Cloud
      final localDocDetails = await db.documentsDao.watchDocuments().first;
      for (final item in localDocDetails) {
        final d = item.document;
        await userDocRef.collection('documents').doc(d.documentPk).set({
          'documentPk': d.documentPk,
          'title': d.title,
          'note': d.note,
          'localFilePath': d.localFilePath,
          'externalUrl': d.externalUrl,
          'subjectFk': d.subjectFk,
          'docTypeFk': d.docTypeFk,
          'dueDate': d.dueDate?.toIso8601String(),
          'status': d.status,
          'isPinned': d.isPinned,
          'dateTimeCreated': d.dateTimeCreated.toIso8601String(),
          'dateTimeModified': d.dateTimeModified.toIso8601String(),
        }, SetOptions(merge: true));
        pushedCount++;
      }

      // 4. Kéo Tài Liệu từ Cloud về SQLite nếu chưa có hoặc có bản mới hơn
      final remoteDocs = await userDocRef.collection('documents').get();
      for (final doc in remoteDocs.docs) {
        final data = doc.data();
        final localMatch = localDocDetails
            .where((item) => item.document.documentPk == doc.id)
            .toList();

        final remoteModified = DateTime.tryParse(data['dateTimeModified'] ?? '') ?? DateTime.now();

        if (localMatch.isEmpty) {
          // Thêm mới vào SQLite
          await db.documentsDao.insertDocument(
            DocumentsCompanion.insert(
              documentPk: data['documentPk'] ?? doc.id,
              title: data['title'] ?? 'Tài liệu đồng bộ',
              note: drift.Value(data['note']),
              localFilePath: drift.Value(data['localFilePath']),
              externalUrl: drift.Value(data['externalUrl']),
              subjectFk: data['subjectFk'] ?? '',
              docTypeFk: data['docTypeFk'] ?? '',
              dueDate: drift.Value(data['dueDate'] != null ? DateTime.tryParse(data['dueDate']) : null),
              status: drift.Value(data['status'] ?? 0),
              isPinned: drift.Value(data['isPinned'] ?? false),
              dateTimeCreated: DateTime.tryParse(data['dateTimeCreated'] ?? '') ?? DateTime.now(),
              dateTimeModified: remoteModified,
            ),
          );
          pulledCount++;
        }
      }

      // 5. Đồng bộ Tombstone xóa (DeleteLogs)
      final deleteLogs = await (db.select(db.deleteLogs)).get();
      for (final log in deleteLogs) {
        if (log.type == 'Document') {
          await userDocRef.collection('documents').doc(log.entryPk).delete();
        } else if (log.type == 'Subject') {
          await userDocRef.collection('subjects').doc(log.entryPk).delete();
        }
      }

      _lastSyncTime = DateTime.now();
      return SyncResult(
        success: true,
        message: 'Đồng bộ Cloud thành công ($pushedCount đẩy lên, $pulledCount kéo về).',
      );
    } catch (e) {
      debugPrint('Lỗi tiến trình Cloud Sync: $e');
      return SyncResult(
        success: false,
        message: 'Lỗi trong quá trình đồng bộ: $e',
      );
    } finally {
      _isSyncing = false;
    }
  }
}

class SyncResult {
  final bool success;
  final String message;

  SyncResult({required this.success, required this.message});
}
