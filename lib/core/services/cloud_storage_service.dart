import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Kết quả tải tệp lên Supabase Storage — được lưu vào bảng documents
/// (file_path, file_name, file_size, storage_provider = 'supabase_storage').
class UploadedFile {
  final String storagePath;
  final String fileName;
  final int size;

  UploadedFile({
    required this.storagePath,
    required this.fileName,
    required this.size,
  });
}

/// Lưu tệp tài liệu trên Supabase Storage (bucket private "documents").
/// Quyền đọc/ghi do RLS trên storage.objects kiểm soát (supabase/03_setup_storage.sql):
/// chỉ chủ thư mục được tải lên/xóa; người được chia sẻ tài liệu được tạo signed URL để tải về.
class CloudStorageService {
  static final CloudStorageService _instance = CloudStorageService._internal();
  factory CloudStorageService() => _instance;
  CloudStorageService._internal();

  static const bucket = 'documents';
  static const providerName = 'supabase_storage';

  StorageFileApi? get _bucket =>
      SupabaseService().client?.storage.from(bucket);

  bool get isAvailable => _bucket != null;

  /// Đường dẫn chuẩn: users/{uid}/documents/{documentId}/{yyyyMMddHHmmss}_{tên_file}
  static String buildStoragePath({
    required String uid,
    required String documentId,
    required String fileName,
    DateTime? at,
  }) {
    final t = (at ?? DateTime.now()).toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${t.year}${two(t.month)}${two(t.day)}${two(t.hour)}${two(t.minute)}${two(t.second)}';
    final sanitized = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return 'users/$uid/documents/$documentId/${stamp}_$sanitized';
  }

  static String _contentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const types = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'zip': 'application/zip',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
    };
    return types[ext] ?? 'application/octet-stream';
  }

  /// Tải tệp tài liệu lên Supabase Storage (yêu cầu đã đăng nhập Google)
  Future<UploadedFile> uploadDocumentFile({
    required String documentId,
    required String fileName,
    File? file,
    Uint8List? bytes,
  }) async {
    final b = _bucket;
    if (b == null) {
      throw Exception('Supabase Storage chưa sẵn sàng.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Cần đăng nhập Google để tải tệp lên Cloud.');
    }

    final data = bytes ?? await file?.readAsBytes();
    if (data == null) {
      throw Exception('Không có dữ liệu tệp (file/bytes) để tải lên.');
    }

    final path = buildStoragePath(
        uid: user.uid, documentId: documentId, fileName: fileName);
    try {
      await b
          .uploadBinary(
            path,
            data,
            fileOptions: FileOptions(contentType: _contentType(fileName)),
          )
          .timeout(const Duration(seconds: 60));
    } on StorageException catch (e) {
      final rls = e.statusCode == '403' ||
          e.message.contains('row-level security') ||
          e.message.toLowerCase().contains('bucket not found');
      throw Exception(rls
          ? 'Supabase Storage từ chối (${e.message}). Đã chạy supabase/03_setup_storage.sql chưa?'
          : 'Lỗi Supabase Storage: ${e.message}');
    }
    return UploadedFile(
        storagePath: path, fileName: fileName, size: data.length);
  }

  /// Tạo link tải tạm thời (1 giờ). RLS chỉ cho người có quyền xem tài liệu tạo link.
  Future<String> createDownloadUrl(String storagePath) async {
    final b = _bucket;
    if (b == null) throw Exception('Supabase Storage chưa sẵn sàng.');
    try {
      return await b.createSignedUrl(storagePath, 3600);
    } on StorageException catch (e) {
      throw Exception(
          'Không có quyền tải tệp hoặc tệp không tồn tại (${e.message}).');
    }
  }

  /// Xóa tệp khỏi Supabase Storage (RLS: chỉ chủ thư mục)
  Future<void> deleteDocumentFile(String storagePath) async {
    final b = _bucket;
    if (b == null || storagePath.isEmpty) return;
    try {
      await b.remove([storagePath]);
    } catch (e) {
      debugPrint('Không xóa được tệp trên Storage: $e');
    }
  }
}
