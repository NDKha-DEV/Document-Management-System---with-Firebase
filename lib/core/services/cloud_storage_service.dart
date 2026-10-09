import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudStorageService {
  static final CloudStorageService _instance = CloudStorageService._internal();
  factory CloudStorageService() => _instance;
  CloudStorageService._internal();

  FirebaseStorage? get _storage {
    if (Firebase.apps.isNotEmpty) {
      try {
        return FirebaseStorage.instance;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool get isAvailable => _storage != null;

  /// Tải tệp tài liệu lên Firebase Storage
  /// Đường dẫn lưu trữ: users/{uid}/documents/{documentId}/{fileName}
  Future<String?> uploadDocumentFile({
    required String documentId,
    required String fileName,
    File? file,
    Uint8List? bytes,
    Function(double progress)? onProgress,
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw Exception('Firebase Storage chưa sẵn sàng trên nền tảng này.');
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'anonymous_user';

    // Tạo Reference đường dẫn an toàn theo user
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final ref = storage
        .ref()
        .child('users')
        .child(uid)
        .child('documents')
        .child(documentId)
        .child(sanitizedFileName);

    UploadTask uploadTask;
    final metadata = SettableMetadata(
      customMetadata: {
        'documentId': documentId,
        'uploadedAt': DateTime.now().toIso8601String(),
        'uploadedBy': uid,
      },
    );

    if (bytes != null) {
      uploadTask = ref.putData(bytes, metadata);
    } else if (file != null) {
      uploadTask = ref.putFile(file, metadata);
    } else {
      throw Exception('Không có dữ liệu tệp (file/bytes) để tải lên.');
    }

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Xóa tệp khỏi Firebase Storage dựa vào Download URL hoặc Storage Path
  Future<void> deleteDocumentFile(String fileUrl) async {
    final storage = _storage;
    if (storage == null || fileUrl.isEmpty) return;

    try {
      if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
        final ref = storage.refFromURL(fileUrl);
        await ref.delete();
      }
    } catch (e) {
      debugPrint('Thông báo: Tệp không tồn tại trên Cloud Storage hoặc đã xóa trước đó: $e');
    }
  }
}
