import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import '../config/supabase_config.dart';
import '../models/cloud_document.dart';
import '../models/borrow_request.dart';

/// Lỗi Supabase đã được dịch sang thông báo dễ hiểu.
class CloudException implements Exception {
  final String message;
  final bool blockedByRls;
  CloudException(this.message, {this.blockedByRls = false});

  @override
  String toString() => message;
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const _documentSelect = '''
    *,
    profiles:owner_id (display_name, email, avatar_url),
    permissions:document_permissions (
      id, shared_with_email, shared_with_user_id, permission_level
    )
  ''';

  SupabaseClient? _client;
  bool _isInitialized = false;

  /// Lỗi gần nhất khi lưu tài liệu (hiển thị cho người dùng để chẩn đoán)
  String? lastSaveError;

  bool get isInitialized => _isInitialized;
  SupabaseClient? get client => _client;

  /// Supabase gọi hàm này trước mỗi request: gửi Firebase ID token làm JWT.
  /// Supabase (Third-Party Auth: Firebase) xác minh chữ ký token, RLS đọc claim sub/email.
  Future<String?> _firebaseAccessToken() async {
    if (Firebase.apps.isEmpty) return null;
    return fb.FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<void> initialize() async {
    await SupabaseConfig.loadConfig();
    if (!SupabaseConfig.isConfigured) {
      debugPrint('Supabase chưa được điền URL/Key.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        accessToken: _firebaseAccessToken,
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
      if (_isInitialized) {
        await Supabase.instance.dispose();
      }
      await Supabase.initialize(
        url: url.trim(),
        anonKey: anonKey.trim(),
        accessToken: _firebaseAccessToken,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Lỗi cập nhật cấu hình Supabase: $e');
      return false;
    }
  }

  SupabaseClient _requireClient() {
    final c = _client;
    if (c == null) {
      throw CloudException(
          'Supabase chưa sẵn sàng. Kiểm tra Project URL / Key trong Cài đặt.');
    }
    return c;
  }

  fb.User _requireUser() {
    final user =
        Firebase.apps.isEmpty ? null : fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw CloudException('Bạn cần đăng nhập Google để dùng tính năng Cloud.');
    }
    return user;
  }

  /// Chuyển lỗi PostgREST thành thông báo tiếng Việt.
  CloudException _translate(Object e) {
    if (e is CloudException) return e;
    if (e is PostgrestException) {
      final code = e.code ?? '';
      if (code == '42501' || e.message.contains('row-level security')) {
        return CloudException(
          'Bị chặn bởi chính sách bảo mật RLS: bạn không có quyền thực hiện thao tác này.',
          blockedByRls: true,
        );
      }
      if (code.startsWith('PGRST3') ||
          e.message.toLowerCase().contains('jwt')) {
        return CloudException(
            'Supabase từ chối token Firebase (${e.message}). Hãy bật Authentication > Third-Party Auth > Firebase (project study-materials-app-8fcf8).');
      }
      if (code == '42P01' || code == 'PGRST205' || code == 'PGRST202') {
        return CloudException(
            'Thiếu bảng/hàm trên Supabase. Hãy chạy supabase/01_setup_schema_rls.sql trong SQL Editor.');
      }
      if (code == '23505') {
        return CloudException('Dữ liệu bị trùng (${e.details ?? e.message}).');
      }
      return CloudException('Lỗi Supabase [$code]: ${e.message}');
    }
    return CloudException('Lỗi kết nối Supabase: $e');
  }

  /// Mô tả lỗi kèm mã gốc của Postgres/PostgREST để dễ chẩn đoán
  String _describe(Object e) {
    if (e is PostgrestException) {
      return '${_translate(e).message} [${e.code}: ${e.message}${e.details != null ? ' | ${e.details}' : ''}]';
    }
    return _translate(e).message;
  }

  /// Chẩn đoán ghi dữ liệu: upsert hồ sơ, upsert tài liệu thử, cập nhật, rồi xóa.
  Future<List<(bool, String)>> diagnoseWrites(fb.User user) async {
    final c = _requireClient();
    final out = <(bool, String)>[];
    final testId = 'diag-${user.uid}';

    Future<void> step(String label, Future<void> Function() run) async {
      try {
        await run();
        out.add((true, label));
      } catch (e) {
        out.add((false, '$label: ${_describe(e)}'));
      }
    }

    await step('Ghi hồ sơ (profiles upsert)', () async {
      await c.from('profiles').upsert({
        'id': user.uid,
        'email': (user.email ?? '').toLowerCase(),
        'display_name': user.displayName ?? 'Sinh viên',
        'avatar_url': user.photoURL,
      });
    });
    await step('Tạo tài liệu thử (documents upsert)', () async {
      await c.from('documents').upsert({
        'id': testId,
        'owner_id': user.uid,
        'title': 'Tài liệu chẩn đoán',
      });
    });
    await step('Cập nhật tài liệu thử (upsert lần 2)', () async {
      await c.from('documents').upsert({
        'id': testId,
        'owner_id': user.uid,
        'title': 'Tài liệu chẩn đoán (2)',
      });
    });
    await step('Xóa tài liệu thử', () async {
      await c.from('documents').delete().eq('id', testId);
    });
    return out;
  }

  /// Chẩn đoán: Supabase nhận diện token Firebase hiện tại là ai?
  Future<Map<String, dynamic>> whoAmI() async {
    final c = _requireClient();
    try {
      final res = await c.rpc('whoami');
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      throw _translate(e);
    }
  }

  /// 1. Đồng bộ Hồ sơ Người dùng (Profiles) từ Firebase Auth sang Supabase
  Future<void> syncUserProfile(fb.User user) async {
    final c = _client;
    if (c == null) return;

    try {
      await c.from('profiles').upsert({
        'id': user.uid,
        'email': (user.email ?? '').toLowerCase(),
        'display_name': user.displayName ?? 'Sinh viên',
        'avatar_url': user.photoURL,
        'last_sign_in_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('Đã đồng bộ profile ${user.email} sang Supabase.');
    } catch (e) {
      debugPrint('Lỗi đồng bộ profile sang Supabase: ${_translate(e)}');
    }
  }

  /// Loại bỏ ký tự đặc biệt của cú pháp filter PostgREST
  String _sanitizeSearch(String q) =>
      q.replaceAll(RegExp(r'[,()%*\\"]'), ' ').trim();

  /// 2. Tìm kiếm tài liệu trên Supabase. RLS tự lọc những dòng người dùng được xem.
  ///    [ownedByMe] = true: chỉ tài liệu của tôi; false: chỉ tài liệu người khác chia sẻ.
  Future<List<CloudDocument>> searchDocuments({
    required bool ownedByMe,
    String? searchQuery,
  }) async {
    final c = _requireClient();
    final user = _requireUser();

    try {
      var query = c.from('documents').select(_documentSelect);
      query = ownedByMe
          ? query.eq('owner_id', user.uid)
          : query.neq('owner_id', user.uid);

      final term = _sanitizeSearch(searchQuery ?? '');
      if (term.isNotEmpty) {
        query = query.or(
            'title.ilike.%$term%,note.ilike.%$term%,subject_code.ilike.%$term%,subject_name.ilike.%$term%,file_name.ilike.%$term%');
      }

      final response = await query
          .order('is_pinned', ascending: false)
          .order('updated_at', ascending: false);

      return response
          .map<CloudDocument>((m) => CloudDocument.fromMap(m))
          .toList();
    } catch (e) {
      throw _translate(e);
    }
  }

  /// Lấy 1 tài liệu (null nếu không tồn tại hoặc RLS không cho xem)
  Future<CloudDocument?> getDocument(String documentId) async {
    final c = _requireClient();
    try {
      final row = await c
          .from('documents')
          .select(_documentSelect)
          .eq('id', documentId)
          .maybeSingle();
      return row == null ? null : CloudDocument.fromMap(row);
    } catch (e) {
      throw _translate(e);
    }
  }

  /// 3. Tạo mới hoặc cập nhật tài liệu của chính mình (owner) lên Supabase.
  ///    Các trường file chỉ ghi khi có giá trị, tránh xóa mất file cũ khi sửa.
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
    String? tags,
    String? locationName,
    double? latitude,
    double? longitude,
    String? filePath,
    String? fileName,
    int? fileSize,
    bool? isPublic,
  }) async {
    final c = _client;
    if (c == null) return false;

    final data = <String, dynamic>{
      'id': documentId,
      'owner_id': ownerId,
      'title': title,
      'note': note,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'doc_type': docType ?? 'Bài tập',
      'status': status ?? 0,
      'due_date': dueDate?.toUtc().toIso8601String(),
      'is_pinned': isPinned ?? false,
      'file_url': fileUrl,
      'tags': tags,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
    };
    if (filePath != null) {
      data['file_path'] = filePath;
      data['storage_provider'] = 'supabase_storage';
    }
    if (fileName != null) data['file_name'] = fileName;
    if (fileSize != null) data['file_size'] = fileSize;
    if (isPublic != null) data['is_public'] = isPublic;

    lastSaveError = null;
    try {
      await c.from('documents').upsert(data);
      return true;
    } catch (e) {
      lastSaveError = _describe(e);
      debugPrint('Lỗi lưu tài liệu lên Supabase: $lastSaveError');
      return false;
    }
  }

  /// Cập nhật một phần tài liệu (owner / admin / editor).
  /// Ném CloudException(blockedByRls) nếu RLS không cho sửa (0 dòng bị ảnh hưởng).
  Future<void> updateDocument(
      String documentId, Map<String, dynamic> fields) async {
    final c = _requireClient();
    try {
      final rows = await c
          .from('documents')
          .update(fields)
          .eq('id', documentId)
          .select('id');
      if (rows.isEmpty) {
        throw CloudException(
          'Bị chặn bởi RLS: bạn chỉ có quyền xem tài liệu này, không được sửa.',
          blockedByRls: true,
        );
      }
    } catch (e) {
      throw _translate(e);
    }
  }

  /// Đồng bộ nhẹ từ thao tác cục bộ (đổi trạng thái / ghim). Bỏ qua lỗi.
  Future<void> patchOwnDocumentSilently(
      String documentId, Map<String, dynamic> fields) async {
    final c = _client;
    final signedIn = Firebase.apps.isNotEmpty &&
        fb.FirebaseAuth.instance.currentUser != null;
    if (c == null || !signedIn) return;
    try {
      await c.from('documents').update(fields).eq('id', documentId);
    } catch (e) {
      debugPrint('Không đồng bộ được thay đổi lên Supabase: $e');
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

    final email = recipientEmail.trim().toLowerCase();
    final me = Firebase.apps.isEmpty
        ? null
        : fb.FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (email == me) {
      return ShareResult(
          success: false, message: 'Không thể tự chia sẻ cho chính mình.');
    }

    try {
      // Tìm xem người nhận đã có tài khoản trong bảng profiles chưa
      final userLookup = await c
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      final String? recipientUid =
          userLookup != null ? userLookup['id'] as String? : null;

      await c.from('document_permissions').upsert({
        'document_id': documentId,
        'shared_with_email': email,
        'shared_with_user_id': recipientUid,
        'permission_level': permissionLevel,
        'granted_by': grantedBy,
      }, onConflict: 'document_id,shared_with_email');

      return ShareResult(
        success: true,
        message: recipientUid != null
            ? 'Đã chia sẻ cho $email với quyền $permissionLevel.'
            : 'Đã chia sẻ cho $email ($permissionLevel). Người này sẽ thấy tài liệu khi đăng nhập lần đầu.',
      );
    } catch (e) {
      final err = _translate(e);
      debugPrint('Lỗi chia sẻ tài liệu: $err');
      return ShareResult(
        success: false,
        message: err.blockedByRls
            ? 'Bị chặn bởi RLS: bạn không có quyền chia sẻ tài liệu này${permissionLevel == 'admin' ? ' với quyền Admin' : ''}.'
            : err.message,
      );
    }
  }

  /// 5. Lấy Danh sách Người đã được Chia sẻ của 1 Tài liệu
  Future<List<Map<String, dynamic>>> getDocumentPermissions(
      String documentId) async {
    final c = _client;
    if (c == null) return [];

    try {
      final response = await c
          .from('document_permissions')
          .select('*')
          .eq('document_id', documentId)
          .order('created_at');
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
      final rows = await c
          .from('document_permissions')
          .delete()
          .eq('id', permissionId)
          .select('id');
      return rows.isNotEmpty;
    } catch (e) {
      debugPrint('Lỗi thu hồi quyền: $e');
      return false;
    }
  }

  /// Creates a pending borrow request for the loaded Cloud document.
  Future<BorrowRequest> createBorrowRequest({
    required CloudDocument document,
    String? requestNote,
  }) async {
    final c = _requireClient();
    final user = _requireUser();
    if (document.ownerId == user.uid) {
      throw CloudException('Bạn không thể gửi yêu cầu mượn tài liệu của mình.');
    }

    try {
      final existing = await c
          .from('borrow_requests')
          .select('id')
          .eq('document_id', document.id)
          .eq('requester_id', user.uid)
          .eq('status', 'pending')
          .maybeSingle();
      if (existing != null) {
        throw CloudException('Bạn đã có yêu cầu mượn đang chờ duyệt.');
      }

      final row = await c
          .from('borrow_requests')
          .insert({
            'document_id': document.id,
            'requester_id': user.uid,
            'owner_id': document.ownerId,
            'status': 'pending',
            'request_note': requestNote == null || requestNote.trim().isEmpty
                ? null
                : requestNote.trim(),
          })
          .select()
          .single();
      return BorrowRequest.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw _translate(e);
    }
  }

  /// Lists requests visible to the current Firebase user under Supabase RLS.
  Future<List<BorrowRequest>> getBorrowRequests({String? documentId}) async {
    final c = _requireClient();
    final user = _requireUser();
    try {
      var query = c
          .from('borrow_requests')
          .select('*')
          .or('requester_id.eq.${user.uid},owner_id.eq.${user.uid}');
      if (documentId != null) {
        query = query.eq('document_id', documentId);
      }
      final rows = await query.order('created_at', ascending: false);
      return rows
          .map<BorrowRequest>(
              (row) => BorrowRequest.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } catch (e) {
      throw _translate(e);
    }
  }

  /// Owner-side decision. The client guard complements, but does not replace,
  /// the current RLS policies.
  Future<BorrowRequest> respondToBorrowRequest({
    required BorrowRequest request,
    required String status,
    String? responseNote,
  }) async {
    final c = _requireClient();
    final user = _requireUser();
    if (request.ownerId != user.uid) {
      throw CloudException('Chỉ chủ sở hữu mới có thể xử lý yêu cầu mượn.');
    }
    if (request.status != 'pending' ||
        (status != 'approved' && status != 'rejected')) {
      throw CloudException('Trạng thái yêu cầu mượn không hợp lệ.');
    }

    try {
      final row = await c
          .from('borrow_requests')
          .update({
            'status': status,
            'response_note': responseNote == null || responseNote.trim().isEmpty
                ? null
                : responseNote.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', request.id)
          .eq('status', 'pending')
          .select()
          .maybeSingle();
      if (row == null) {
        throw CloudException(
            'Yêu cầu không còn chờ duyệt hoặc bạn không có quyền xử lý.');
      }
      return BorrowRequest.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw _translate(e);
    }
  }

  /// 7. Xóa Tài liệu trên Supabase (CASCADE xóa sạch quyền trong document_permissions)
  /// Trả về true nếu có dòng bị xóa (RLS chỉ cho owner xóa).
  Future<bool> deleteDocument(String documentId) async {
    final c = _client;
    if (c == null) return false;

    try {
      final rows =
          await c.from('documents').delete().eq('id', documentId).select('id');
      return rows.isNotEmpty;
    } catch (e) {
      debugPrint('Lỗi xóa tài liệu trên Supabase: $e');
      return false;
    }
  }

  /// 8. Kiểm thử quyền thật trên server: gửi thẳng request tới Supabase
  ///    (bỏ qua mọi kiểm tra ở giao diện) và ghi nhận RLS cho phép hay chặn.
  Future<List<PermissionProbe>> probePermissions(CloudDocument doc) async {
    final c = _requireClient();
    final user = _requireUser();
    final results = <PermissionProbe>[];

    // XEM
    try {
      final row =
          await c.from('documents').select('id').eq('id', doc.id).maybeSingle();
      results.add(PermissionProbe('Xem tài liệu (SELECT)', row != null));
    } catch (e) {
      results.add(PermissionProbe('Xem tài liệu (SELECT)', false,
          detail: _translate(e).message));
    }

    // TẢI TỆP: xin signed URL từ Supabase Storage (RLS trên storage.objects)
    if (doc.filePath != null) {
      try {
        await c.storage.from('documents').createSignedUrl(doc.filePath!, 60);
        results.add(PermissionProbe('Tải tệp đính kèm (Storage)', true));
      } catch (e) {
        results.add(PermissionProbe('Tải tệp đính kèm (Storage)', false));
      }
    }

    // SỬA: ghi lại đúng giá trị hiện tại (không làm thay đổi nội dung)
    try {
      final rows = await c
          .from('documents')
          .update({'title': doc.title})
          .eq('id', doc.id)
          .select('id');
      results.add(PermissionProbe('Sửa tài liệu (UPDATE)', rows.isNotEmpty));
    } catch (e) {
      results.add(PermissionProbe('Sửa tài liệu (UPDATE)', false,
          detail: _translate(e).message));
    }

    // CHIA SẺ: thử cấp quyền viewer cho một email kiểm thử, nếu được thì thu hồi ngay
    const probeEmail = 'rls-probe@example.invalid';
    try {
      final rows = await c.from('document_permissions').insert({
        'document_id': doc.id,
        'shared_with_email': probeEmail,
        'permission_level': 'viewer',
        'granted_by': user.uid,
      }).select('id');
      results
          .add(PermissionProbe('Chia sẻ tiếp (INSERT quyền)', rows.isNotEmpty));
      if (rows.isNotEmpty) {
        await c
            .from('document_permissions')
            .delete()
            .eq('id', rows.first['id'] as int);
      }
    } catch (e) {
      final err = _translate(e);
      results.add(PermissionProbe('Chia sẻ tiếp (INSERT quyền)', false,
          detail: err.blockedByRls ? null : err.message));
    }

    // XÓA: chỉ thử thật khi KHÔNG phải chủ sở hữu (tránh xóa mất tài liệu của chính mình)
    if (doc.ownerId == user.uid) {
      results.add(PermissionProbe('Xóa tài liệu (DELETE)', true,
          detail:
              'Chủ sở hữu luôn được xóa (không chạy thử để tránh mất dữ liệu)'));
    } else {
      try {
        final rows =
            await c.from('documents').delete().eq('id', doc.id).select('id');
        results.add(PermissionProbe('Xóa tài liệu (DELETE)', rows.isNotEmpty));
      } catch (e) {
        results.add(PermissionProbe('Xóa tài liệu (DELETE)', false,
            detail: _translate(e).message));
      }
    }

    return results;
  }
}

class ShareResult {
  final bool success;
  final String message;

  ShareResult({required this.success, required this.message});
}

class PermissionProbe {
  final String action;
  final bool allowed;
  final String? detail;

  PermissionProbe(this.action, this.allowed, {this.detail});
}
