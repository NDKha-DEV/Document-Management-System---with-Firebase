import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  SupabaseClient? get client => _client;

  Future<void> initialize() async {
    await SupabaseConfig.loadConfig();
    if (!SupabaseConfig.isConfigured) {
      debugPrint('Supabase chưa được điền URL/Anon Key. Đang hoạt động ở chế độ chờ cấu hình.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('Supabase đã khởi tạo thành công.');
    } catch (e) {
      debugPrint('Lỗi khởi tạo Supabase: $e');
      _isInitialized = false;
    }
  }

  Future<bool> updateConfiguration(String url, String anonKey) async {
    await SupabaseConfig.updateConfig(url, anonKey);
    try {
      await Supabase.initialize(
        url: url.trim(),
        anonKey: anonKey.trim(),
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Lỗi cập nhật cấu hình Supabase: $e');
      return false;
    }
  }

  /// 1. Đồng bộ Hồ sơ Người dùng (Profiles) từ Firebase Auth sang Supabase
  Future<void> syncUserProfile(fb.User user) async {
    final c = _client;
    if (c == null) return;

    try {
      await c.from('profiles').upsert({
        'id': user.uid,
        'email': user.email ?? '',
        'display_name': user.displayName ?? 'Sinh viên',
        'avatar_url': user.photoURL,
        'last_sign_in_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Đã đồng bộ profile ${user.email} sang Supabase.');
    } catch (e) {
      debugPrint('Lỗi đồng bộ profile sang Supabase: $e');
    }
  }

  /// 2. Lấy Danh sách Tài liệu Của Tôi và Tài Liệu Được Chia Sẻ Cho Tôi
  Future<List<Map<String, dynamic>>> getAccessibleDocuments({
    required String currentUserId,
    required String currentUserEmail,
    String? searchQuery,
    String? subjectCode,
  }) async {
    final c = _client;
    if (c == null) return [];

    try {
      // Thiết lập header ngữ cảnh cho Row Level Security (RLS)
      var query = c.from('documents').select('''
        *,
        profiles:owner_id (display_name, email, avatar_url),
        permissions:document_permissions (
          id, shared_with_email, permission_level
        )
      ''');

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = searchQuery.trim();
        query = query.or('title.ilike.%$term%,note.ilike.%$term%');
      }

      if (subjectCode != null && subjectCode.isNotEmpty) {
        query = query.eq('subject_code', subjectCode);
      }

      final response = await query
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Lỗi truy vấn tài liệu Supabase: $e');
      return [];
    }
  }

  /// 3. Lưu hoặc Cập nhật Tài liệu lên Supabase
  Future<bool> saveDocument({
    required String documentId,
    required String ownerId,
    required String title,
    String? note,
    String? subjectCode,
    String? subjectName,
    String? docType,
    int? status,
    DateTime? dueDate,
    bool? isPinned,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    bool? isPublic,
  }) async {
    final c = _client;
    if (c == null) return false;

    try {
      await c.from('documents').upsert({
        'id': documentId,
        'owner_id': ownerId,
        'title': title,
        'note': note,
        'subject_code': subjectCode,
        'subject_name': subjectName,
        'doc_type': docType ?? 'Bài tập',
        'status': status ?? 0,
        'due_date': dueDate?.toIso8601String(),
        'is_pinned': isPinned ?? false,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize ?? 0,
        'storage_provider': 'firebase_storage',
        'is_public': isPublic ?? false,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Lỗi lưu tài liệu lên Supabase: $e');
      return false;
    }
  }

  /// 4. Chia sẻ Tài liệu cho Người Dùng Khác
  /// permissionLevel: 'viewer', 'editor', 'admin'
  Future<ShareResult> shareDocument({
    required String documentId,
    required String recipientEmail,
    required String permissionLevel,
    required String grantedBy,
  }) async {
    final c = _client;
    if (c == null) {
      return ShareResult(success: false, message: 'Supabase chưa sẵn sàng.');
    }

    try {
      // Tìm xem người nhận đã có tài khoản trong bảng profiles chưa
      final userLookup = await c
          .from('profiles')
          .select('id')
          .eq('email', recipientEmail.trim().toLowerCase())
          .maybeSingle();

      final String? recipientUid = userLookup != null ? userLookup['id'] as String? : null;

      // Thêm hoặc cập nhật quyền chia sẻ
      await c.from('document_permissions').upsert({
        'document_id': documentId,
        'shared_with_email': recipientEmail.trim().toLowerCase(),
        'shared_with_user_id': recipientUid,
        'permission_level': permissionLevel,
        'granted_by': grantedBy,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'document_id,shared_with_email');

      return ShareResult(
        success: true,
        message: 'Đã chia sẻ tài liệu thành công cho $recipientEmail với quyền $permissionLevel.',
      );
    } catch (e) {
      debugPrint('Lỗi chia sẻ tài liệu: $e');
      return ShareResult(
        success: false,
        message: 'Lỗi khi chia sẻ tài liệu: $e',
      );
    }
  }

  /// 5. Lấy Danh sách Người đã được Chia sẻ của 1 Tài liệu
  Future<List<Map<String, dynamic>>> getDocumentPermissions(String documentId) async {
    final c = _client;
    if (c == null) return [];

    try {
      final response = await c
          .from('document_permissions')
          .select('*')
          .eq('document_id', documentId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Lỗi lấy danh sách quyền: $e');
      return [];
    }
  }

  /// 6. Thu hồi Quyền Chia sẻ
  Future<bool> revokePermission(int permissionId) async {
    final c = _client;
    if (c == null) return false;

    try {
      await c.from('document_permissions').delete().eq('id', permissionId);
      return true;
    } catch (e) {
      debugPrint('Lỗi thu hồi quyền: $e');
      return false;
    }
  }

  /// 7. Xóa Tài liệu trên Supabase (CASCADE xóa sạch quyền trong document_permissions)
  Future<bool> deleteDocument(String documentId) async {
    final c = _client;
    if (c == null) return false;

    try {
      await c.from('documents').delete().eq('id', documentId);
      return true;
    } catch (e) {
      debugPrint('Lỗi xóa tài liệu trên Supabase: $e');
      return false;
    }
  }
}

class ShareResult {
  final bool success;
  final String message;

  ShareResult({required this.success, required this.message});
}
