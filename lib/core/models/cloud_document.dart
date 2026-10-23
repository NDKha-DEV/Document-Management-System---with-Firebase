/// Vai trò của người dùng hiện tại đối với một tài liệu trên Supabase.
/// Phản chiếu hàm public.document_role() trong supabase/01_setup_schema_rls.sql
/// (giao diện chỉ dùng để ẩn/hiện nút; quyết định cuối cùng luôn do RLS).
enum DocumentRole { owner, admin, editor, viewer, public, none }

extension DocumentRoleX on DocumentRole {
  bool get canView => this != DocumentRole.none;
  bool get canEdit =>
      this == DocumentRole.owner ||
      this == DocumentRole.admin ||
      this == DocumentRole.editor;
  bool get canShare => this == DocumentRole.owner || this == DocumentRole.admin;
  bool get canGrantAdmin => this == DocumentRole.owner;
  bool get canDelete => this == DocumentRole.owner;

  String get label {
    switch (this) {
      case DocumentRole.owner:
        return 'Chủ sở hữu';
      case DocumentRole.admin:
        return 'Toàn quyền (Admin)';
      case DocumentRole.editor:
        return 'Chỉnh sửa (Editor)';
      case DocumentRole.viewer:
        return 'Chỉ xem (Viewer)';
      case DocumentRole.public:
        return 'Công khai';
      case DocumentRole.none:
        return 'Không có quyền';
    }
  }

  static DocumentRole fromLevel(String? level) {
    switch (level) {
      case 'admin':
        return DocumentRole.admin;
      case 'editor':
        return DocumentRole.editor;
      case 'viewer':
        return DocumentRole.viewer;
      default:
        return DocumentRole.none;
    }
  }
}

/// Một dòng của bảng public.documents (kèm hồ sơ chủ sở hữu và quyền chia sẻ
/// mà RLS cho phép người dùng hiện tại nhìn thấy).
class CloudDocument {
  final String id;
  final String ownerId;
  final String title;
  final String? note;
  final String? subjectCode;
  final String? subjectName;
  final String? docType;
  final int status;
  final DateTime? dueDate;
  final bool isPinned;
  final String? fileUrl;
  final String? filePath;
  final String? fileName;
  final int fileSize;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;
  final String? tags;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerAvatar;
  final List<Map<String, dynamic>> permissions;

  CloudDocument({
    required this.id,
    required this.ownerId,
    required this.title,
    this.note,
    this.subjectCode,
    this.subjectName,
    this.docType,
    this.status = 0,
    this.dueDate,
    this.isPinned = false,
    this.fileUrl,
    this.filePath,
    this.fileName,
    this.fileSize = 0,
    this.isPublic = false,
    this.tags,
    this.locationName,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
    this.ownerName,
    this.ownerEmail,
    this.ownerAvatar,
    this.permissions = const [],
  });

  List<String> get tagList {
    if (tags == null || tags!.trim().isEmpty) return [];
    return tags!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  factory CloudDocument.fromMap(Map<String, dynamic> m) {
    final owner = m['profiles'] is Map ? m['profiles'] as Map : null;
    return CloudDocument(
      id: m['id'] as String,
      ownerId: m['owner_id'] as String,
      title: (m['title'] as String?) ?? 'Tài liệu không tên',
      note: m['note'] as String?,
      subjectCode: m['subject_code'] as String?,
      subjectName: m['subject_name'] as String?,
      docType: m['doc_type'] as String?,
      status: (m['status'] as num?)?.toInt() ?? 0,
      dueDate: _parseDate(m['due_date']),
      isPinned: m['is_pinned'] == true,
      fileUrl: m['file_url'] as String?,
      filePath: m['file_path'] as String?,
      fileName: m['file_name'] as String?,
      fileSize: (m['file_size'] as num?)?.toInt() ?? 0,
      isPublic: m['is_public'] == true,
      tags: m['tags'] as String?,
      locationName: m['location_name'] as String?,
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      createdAt: _parseDate(m['created_at']),
      updatedAt: _parseDate(m['updated_at']),
      updatedBy: m['updated_by'] as String?,
      ownerName: owner?['display_name'] as String?,
      ownerEmail: owner?['email'] as String?,
      ownerAvatar: owner?['avatar_url'] as String?,
      permissions: (m['permissions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }

  static DateTime? _parseDate(dynamic v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  /// Quyền của người dùng (uid/email) đối với tài liệu này.
  DocumentRole roleFor({required String uid, String? email}) {
    if (ownerId == uid) return DocumentRole.owner;
    final myEmail = email?.trim().toLowerCase();
    DocumentRole best = DocumentRole.none;
    for (final p in permissions) {
      final matches = p['shared_with_user_id'] == uid ||
          (myEmail != null &&
              (p['shared_with_email'] as String?)?.toLowerCase() == myEmail);
      if (!matches) continue;
      final r = DocumentRoleX.fromLevel(p['permission_level'] as String?);
      if (best == DocumentRole.none || r.index < best.index) best = r;
    }
    if (best != DocumentRole.none) return best;
    return isPublic ? DocumentRole.public : DocumentRole.none;
  }

  String get displayOwner => ownerName ?? ownerEmail ?? 'Người dùng';
}
