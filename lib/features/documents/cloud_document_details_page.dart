import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/cloud_document.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_storage_service.dart';
import '../../core/services/supabase_service.dart';
import 'cloud_documents_tab.dart';
import 'share_document_sheet.dart';

/// Chi tiết tài liệu trên Supabase — nút thao tác hiển thị theo quyền,
/// và mục "Kiểm thử quyền trên server" gửi request thật để chứng minh RLS.
class CloudDocumentDetailsPage extends StatefulWidget {
  final String documentId;

  const CloudDocumentDetailsPage({super.key, required this.documentId});

  @override
  State<CloudDocumentDetailsPage> createState() =>
      _CloudDocumentDetailsPageState();
}

class _CloudDocumentDetailsPageState extends State<CloudDocumentDetailsPage> {
  CloudDocument? _doc;
  Object? _error;
  bool _loading = true;
  bool _probing = false;
  List<PermissionProbe>? _probeResults;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final doc = await SupabaseService().getDocument(widget.documentId);
      if (!mounted) return;
      setState(() {
        _doc = doc;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  DocumentRole get _role {
    final user = AuthService().currentUser;
    final doc = _doc;
    if (user == null || doc == null) return DocumentRole.none;
    return doc.roleFor(uid: user.uid, email: user.email);
  }

  void _toast(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _update(Map<String, dynamic> fields, String successMsg) async {
    try {
      await SupabaseService().updateDocument(widget.documentId, fields);
      _toast(successMsg, color: Colors.green);
      await _load();
    } on CloudException catch (e) {
      _toast(e.message, color: e.blockedByRls ? Colors.red.shade700 : null);
    }
  }

  Future<void> _openEditSheet() async {
    final doc = _doc!;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditCloudDocumentSheet(doc: doc),
    );
    if (result != null) {
      await _update(result, 'Đã cập nhật tài liệu trên Supabase');
    }
  }

  Future<void> _delete() async {
    final doc = _doc!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài liệu trên Cloud?'),
        content: Text(
            'Xóa "${doc.title}" khỏi Supabase, mọi quyền chia sẻ và tệp trên Supabase Storage.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final removed = await SupabaseService().deleteDocument(doc.id);
    if (!mounted) return;
    if (!removed) {
      _toast('Bị chặn bởi RLS: chỉ chủ sở hữu mới được xóa tài liệu.',
          color: Colors.red.shade700);
      return;
    }
    if (doc.filePath != null) {
      await CloudStorageService().deleteDocumentFile(doc.filePath!);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    _toast('Đã xóa tài liệu khỏi Cloud');
  }

  Future<void> _runProbe() async {
    setState(() {
      _probing = true;
      _probeResults = null;
    });
    try {
      final results = await SupabaseService().probePermissions(_doc!);
      if (!mounted) return;
      setState(() => _probeResults = results);
      await _load(); // tài liệu có thể đã bị xóa nếu RLS sai
    } on CloudException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _probing = false);
    }
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast('Không mở được tệp');
    }
  }

  /// Xin signed URL (hết hạn sau 1 giờ) — RLS chỉ cấp cho người có quyền xem tài liệu
  Future<void> _openStoredFile(String path) async {
    try {
      final url = await CloudStorageService().createDownloadUrl(path);
      await _openFile(url);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''),
          color: Colors.red.shade700);
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_loading && _doc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tài liệu Cloud')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error?.toString() ??
                  'Tài liệu không tồn tại hoặc bạn không còn quyền truy cập (RLS).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final doc = _doc!;
    final role = _role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài Liệu Cloud'),
        actions: [
          if (role.canShare)
            IconButton(
              tooltip: 'Chia sẻ',
              icon: const Icon(Icons.share_outlined),
              onPressed: () async {
                await showShareDocumentSheet(context,
                    documentId: doc.id, documentTitle: doc.title, role: role);
                _load();
              },
            ),
          if (role.canEdit)
            IconButton(
              tooltip: 'Sửa',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _openEditSheet,
            ),
          if (role.canDelete)
            IconButton(
              tooltip: 'Xóa',
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              onPressed: _delete,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildRoleBanner(doc, role),
            const SizedBox(height: 16),
            Text(doc.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (doc.subjectCode != null)
                  Chip(
                      label: Text(
                          '${doc.subjectCode}${doc.subjectName != null ? ' • ${doc.subjectName}' : ''}')),
                if (doc.docType != null)
                  Chip(
                      avatar: const Icon(Icons.category_outlined, size: 16),
                      label: Text(doc.docType!)),
                Chip(
                  avatar: StatusIcon(status: doc.status),
                  label: Text(const ['Cần đọc', 'Đang làm', 'Hoàn thành'][
                      doc.status.clamp(0, 2)]),
                ),
                if (doc.dueDate != null)
                  Chip(
                    avatar: const Icon(Icons.event, size: 16),
                    label: Text(
                        'Hạn: ${doc.dueDate!.day}/${doc.dueDate!.month}/${doc.dueDate!.year}'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (doc.filePath != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.deepPurple.shade200),
                ),
                child: ListTile(
                  leading: const Icon(Icons.cloud_download_rounded,
                      color: Colors.deepPurple),
                  title: Text(
                    doc.fileName ?? 'Tệp đính kèm',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Supabase Storage • ${_formatSize(doc.fileSize)}\n${doc.filePath}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () => _openStoredFile(doc.filePath!),
                ),
              ),
            if (doc.fileUrl != null && doc.fileUrl!.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                child: ListTile(
                  leading: const Icon(Icons.link, color: Colors.blue),
                  title: const Text('Mở liên kết tài liệu',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(doc.fileUrl!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () => _openFile(doc.fileUrl!),
                ),
              ),
            if (doc.note != null && doc.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Ghi chú',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(doc.note!,
                    style: const TextStyle(fontSize: 15, height: 1.5)),
              ),
            ],
            const SizedBox(height: 16),
            if (doc.updatedAt != null)
              Text(
                'Cập nhật lần cuối: ${_formatDate(doc.updatedAt!)}'
                '${doc.updatedBy != null && doc.updatedBy != doc.ownerId ? ' (bởi cộng tác viên)' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 16),
            if (role.canEdit)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _update(
                  {'status': (doc.status + 1) % 3},
                  'Đã đổi trạng thái học tập',
                ),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Đổi trạng thái học tập'),
              ),
            if (role.canShare) ...[
              const SizedBox(height: 10),
              _buildPermissionsSummary(doc),
            ],
            const SizedBox(height: 24),
            _buildProbeCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBanner(CloudDocument doc, DocumentRole role) {
    final caps = <String>[
      'Xem',
      if (role.canEdit) 'Sửa',
      if (role.canShare) 'Chia sẻ',
      if (role.canDelete) 'Xóa',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage:
                doc.ownerAvatar != null ? NetworkImage(doc.ownerAvatar!) : null,
            child: doc.ownerAvatar == null
                ? Text(doc.displayOwner[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chủ sở hữu: ${doc.displayOwner}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Quyền của bạn: ${caps.join(' • ')}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
          RoleBadge(role: role),
        ],
      ),
    );
  }

  Widget _buildPermissionsSummary(CloudDocument doc) {
    return Card(
      elevation: 0,
      color: Colors.deepPurple.shade50.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple.shade200),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Icon(Icons.group_add, color: Colors.white, size: 20),
        ),
        title: const Text('Quản lý chia sẻ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(doc.permissions.isEmpty
            ? 'Chưa chia sẻ với ai'
            : doc.permissions
                .map((p) => '${p['shared_with_email']} (${p['permission_level']})')
                .join(', ')),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () async {
          await showShareDocumentSheet(context,
              documentId: doc.id, documentTitle: doc.title, role: _role);
          _load();
        },
      ),
    );
  }

  Widget _buildProbeCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueGrey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.policy_rounded, color: Colors.blueGrey),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Kiểm thử quyền trên server (RLS)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Gửi thẳng các lệnh SELECT / UPDATE / chia sẻ / DELETE tới Supabase, bỏ qua giao diện, '
              'để xác minh chính sách Row Level Security cho tài khoản hiện tại.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _probing ? null : _runProbe,
                icon: _probing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(_probing ? 'Đang kiểm thử...' : 'Chạy kiểm thử'),
              ),
            ),
            if (_probeResults != null) ...[
              const SizedBox(height: 8),
              ..._probeResults!.map(
                (r) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    r.allowed ? Icons.check_circle : Icons.block,
                    color: r.allowed ? Colors.green : Colors.red,
                  ),
                  title: Text(r.action),
                  subtitle: Text(
                    r.detail ?? (r.allowed ? 'Server cho phép' : 'Server chặn (RLS)'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Form sửa thông tin tài liệu trên Supabase (dành cho owner / admin / editor)
class _EditCloudDocumentSheet extends StatefulWidget {
  final CloudDocument doc;
  const _EditCloudDocumentSheet({required this.doc});

  @override
  State<_EditCloudDocumentSheet> createState() =>
      _EditCloudDocumentSheetState();
}

class _EditCloudDocumentSheetState extends State<_EditCloudDocumentSheet> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _subjectCode;
  late int _status;
  late bool _pinned;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.doc.title);
    _note = TextEditingController(text: widget.doc.note ?? '');
    _subjectCode = TextEditingController(text: widget.doc.subjectCode ?? '');
    _status = widget.doc.status;
    _pinned = widget.doc.isPinned;
    _dueDate = widget.doc.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _subjectCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Cập nhật thông tin tài liệu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: 'Tiêu đề *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectCode,
              decoration: const InputDecoration(
                  labelText: 'Mã môn học', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _status.clamp(0, 2),
              decoration: const InputDecoration(
                  labelText: 'Trạng thái', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Cần đọc')),
                DropdownMenuItem(value: 1, child: Text('Đang làm')),
                DropdownMenuItem(value: 2, child: Text('Hoàn thành')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 0),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_dueDate == null
                  ? 'Chưa đặt hạn nộp'
                  : 'Hạn nộp: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
              trailing: _dueDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ghim tài liệu'),
              value: _pinned,
              onChanged: (v) => setState(() => _pinned = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final title = _title.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(context, {
                  'title': title,
                  'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
                  'subject_code': _subjectCode.text.trim().isEmpty
                      ? null
                      : _subjectCode.text.trim(),
                  'status': _status,
                  'is_pinned': _pinned,
                  'due_date': _dueDate?.toUtc().toIso8601String(),
                });
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Lưu lên Supabase'),
            ),
          ],
        ),
      ),
    );
  }
}
