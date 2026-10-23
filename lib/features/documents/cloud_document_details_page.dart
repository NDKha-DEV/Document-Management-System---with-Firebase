import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/borrow_request.dart';
import '../../core/models/cloud_document.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_storage_service.dart';
import '../../core/services/supabase_service.dart';
import 'cloud_documents_tab.dart';
import 'location_picker_dialog.dart';
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
  List<BorrowRequest> _borrowRequests = [];
  Object? _borrowRequestsError;
  bool _borrowRequestsLoading = true;
  bool _sendingBorrowRequest = false;
  int? _respondingToBorrowRequest;
  List<CloudDocument> _recommendedDocuments = [];
  Object? _recommendationsError;
  bool _recommendationsLoading = true;

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
      if (doc == null) return;
      await _loadBorrowRequests();
      await _loadRecommendations(doc);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadRecommendations(CloudDocument document) async {
    if (!mounted) return;
    final tags = document.tagList.map((tag) => tag.toLowerCase()).toSet();
    if (tags.isEmpty) {
      setState(() {
        _recommendedDocuments = [];
        _recommendationsError = null;
        _recommendationsLoading = false;
      });
      return;
    }

    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;
    setState(() {
      _recommendationsLoading = true;
      _recommendationsError = null;
    });
    try {
      final documents = await SupabaseService().searchDocuments(
        ownedByMe: document.ownerId == currentUser.uid,
      );
      if (!mounted) return;
      setState(() {
        _recommendedDocuments = documents.where((candidate) {
          return candidate.id != document.id &&
              candidate.tagList.any((tag) => tags.contains(tag.toLowerCase()));
        }).toList();
        _recommendationsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recommendationsError = e;
        _recommendationsLoading = false;
      });
    }
  }

  Future<void> _loadBorrowRequests() async {
    if (AuthService().currentUser == null) return;
    setState(() {
      _borrowRequestsLoading = true;
      _borrowRequestsError = null;
    });
    try {
      final requests = await SupabaseService()
          .getBorrowRequests(documentId: widget.documentId);
      if (!mounted) return;
      setState(() {
        _borrowRequests = requests;
        _borrowRequestsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _borrowRequestsError = e;
        _borrowRequestsLoading = false;
      });
    }
  }

  Future<void> _sendBorrowRequest(CloudDocument document) async {
    if (_sendingBorrowRequest) return;
    setState(() => _sendingBorrowRequest = true);
    final noteController = TextEditingController();
    try {
      final note = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Gửi yêu cầu mượn'),
            content: TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Lời nhắn (không bắt buộc)',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(noteController.text),
                child: const Text('Gửi yêu cầu'),
              ),
            ],
          );
        },
      );
      if (note == null || !mounted) return;
      await SupabaseService().createBorrowRequest(
        document: document,
        requestNote: note,
      );
      _toast('Đã gửi yêu cầu mượn cho chủ sở hữu', color: Colors.green);
      await _loadBorrowRequests();
    } on CloudException catch (e) {
      _toast(e.message, color: Colors.red.shade700);
    } catch (e) {
      _toast('Không gửi được yêu cầu mượn: $e', color: Colors.red.shade700);
    } finally {
      noteController.dispose();
      if (mounted) setState(() => _sendingBorrowRequest = false);
    }
  }

  Future<void> _respondToBorrowRequest(
    BorrowRequest request, {
    required String status,
  }) async {
    if (_respondingToBorrowRequest != null) return;
    setState(() => _respondingToBorrowRequest = request.id);
    final decision = status == 'approved' ? 'duyệt' : 'từ chối';
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Xác nhận $decision yêu cầu?'),
          content: Text(
            'Yêu cầu mượn tài liệu của '
            '${request.requesterEmail ?? request.requesterName ?? request.requesterId}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(decision == 'duyệt' ? 'Duyệt' : 'Từ chối'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await SupabaseService().respondToBorrowRequest(
        request: request,
        status: status,
      );
      _toast(
        status == 'approved' ? 'Đã duyệt yêu cầu mượn' : 'Đã từ chối yêu cầu',
        color: Colors.green,
      );
      await _loadBorrowRequests();
    } on CloudException catch (e) {
      _toast(e.message, color: Colors.red.shade700);
    } catch (e) {
      _toast('Không cập nhật được yêu cầu mượn: $e',
          color: Colors.red.shade700);
    } finally {
      if (mounted) setState(() => _respondingToBorrowRequest = null);
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

  Future<void> _openMapLocation(double latitude, double longitude) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$latitude,$longitude',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast('Không mở được vị trí trên bản đồ');
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
                  label: Text(const [
                    'Cần đọc',
                    'Đang làm',
                    'Hoàn thành'
                  ][doc.status.clamp(0, 2)]),
                ),
                if (doc.dueDate != null)
                  Chip(
                    avatar: const Icon(Icons.event, size: 16),
                    label: Text(
                        'Hạn: ${doc.dueDate!.day}/${doc.dueDate!.month}/${doc.dueDate!.year}'),
                  ),
              ],
            ),
            if (doc.tagList.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Tag',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: doc.tagList
                    .map((tag) => Chip(
                          avatar: const Icon(Icons.sell_outlined, size: 16),
                          label: Text(tag),
                        ))
                    .toList(),
              ),
            ],
            if ((doc.locationName?.trim().isNotEmpty ?? false) ||
                doc.latitude != null ||
                doc.longitude != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Builder(builder: (context) {
                  final latitude = doc.latitude;
                  final longitude = doc.longitude;
                  final hasValidCoordinates = latitude != null &&
                      longitude != null &&
                      latitude.isFinite &&
                      longitude.isFinite &&
                      latitude >= -90 &&
                      latitude <= 90 &&
                      longitude >= -180 &&
                      longitude <= 180;

                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(
                      doc.locationName?.trim().isNotEmpty == true
                          ? doc.locationName!.trim()
                          : 'Vị trí tài liệu',
                    ),
                    subtitle: latitude != null || longitude != null
                        ? Text(
                            'Tọa độ: ${latitude?.toString() ?? '—'}, ${longitude?.toString() ?? '—'}',
                          )
                        : null,
                    trailing: hasValidCoordinates
                        ? const Icon(Icons.map_outlined)
                        : null,
                    onTap: hasValidCoordinates
                        ? () => _openMapLocation(latitude, longitude)
                        : null,
                  );
                }),
              ),
            ],
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
            _buildBorrowRequests(doc),
            const SizedBox(height: 16),
            _buildRecommendations(doc),
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

  Widget _buildRecommendations(CloudDocument document) {
    final hasTags = document.tagList.isNotEmpty;
    final related = _recommendedDocuments;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Gợi ý theo tag',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (hasTags)
                  IconButton(
                    tooltip: 'Tải lại gợi ý',
                    onPressed: _recommendationsLoading
                        ? null
                        : () => _loadRecommendations(document),
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            if (!hasTags)
              Text(
                'Tài liệu chưa có tag để tìm gợi ý.',
                style: TextStyle(color: Colors.grey.shade700),
              )
            else if (_recommendationsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_recommendationsError != null) ...[
              Text(
                'Không tải được gợi ý: $_recommendationsError',
                style: TextStyle(color: Colors.red.shade700),
              ),
              TextButton.icon(
                onPressed: () => _loadRecommendations(document),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ] else if (related.isEmpty)
              Text(
                'Chưa tìm thấy tài liệu khác có tag trùng trong Cloud.',
                style: TextStyle(color: Colors.grey.shade700),
              )
            else
              ...related.map(
                (candidate) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: Text(candidate.title),
                  subtitle: Text(candidate.tagList.join(', ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CloudDocumentDetailsPage(documentId: candidate.id),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowRequests(CloudDocument doc) {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox.shrink();

    final isOwner = doc.ownerId == user.uid;
    final requests = _borrowRequests.where((request) {
      return isOwner
          ? request.ownerId == user.uid && request.requesterId != user.uid
          : request.requesterId == user.uid;
    }).toList();
    final hasActiveRequest = requests.any(
      (request) => request.status == 'pending' || request.status == 'approved',
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.handshake_outlined, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOwner ? 'Yêu cầu mượn tài liệu' : 'Yêu cầu mượn của bạn',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tải lại yêu cầu',
                  onPressed:
                      _borrowRequestsLoading ? null : _loadBorrowRequests,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (!isOwner) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sendingBorrowRequest ||
                          hasActiveRequest ||
                          _borrowRequestsLoading
                      ? null
                      : () => _sendBorrowRequest(doc),
                  icon: _sendingBorrowRequest
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    hasActiveRequest
                        ? 'Đang có yêu cầu chờ duyệt/đã duyệt'
                        : 'Gửi yêu cầu mượn',
                  ),
                ),
              ),
            ],
            if (_borrowRequestsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_borrowRequestsError != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Không tải được yêu cầu mượn: $_borrowRequestsError',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              TextButton.icon(
                onPressed: _loadBorrowRequests,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ] else if (requests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  isOwner
                      ? 'Chưa có yêu cầu mượn.'
                      : 'Bạn chưa gửi yêu cầu mượn tài liệu này.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              )
            else
              ...requests.map(_buildBorrowRequestTile),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowRequestTile(BorrowRequest request) {
    final isPending = request.status == 'pending';
    final isResponding = _respondingToBorrowRequest == request.id;
    final statusColor = switch (request.status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      'returned' => Colors.blueGrey,
      _ => Colors.orange,
    };

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.requesterName ??
                      request.requesterEmail ??
                      'Người gửi: ${request.requesterId}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Chip(
                label: Text(request.statusLabel),
                labelStyle: TextStyle(color: statusColor, fontSize: 12),
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: statusColor.withOpacity(0.45)),
                backgroundColor: statusColor.withOpacity(0.08),
              ),
            ],
          ),
          if (request.requestNote?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text('Lời nhắn: ${request.requestNote}'),
          ],
          if (request.responseNote?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text('Phản hồi: ${request.responseNote}'),
          ],
          if (request.borrowDate != null || request.returnDueDate != null) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (request.borrowDate != null)
                  'Ngày mượn: ${_formatBorrowDate(request.borrowDate!)}',
                if (request.returnDueDate != null)
                  'Hạn trả: ${_formatBorrowDate(request.returnDueDate!)}',
              ].join(' • '),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
          if (isPending &&
              AuthService().currentUser?.uid == request.ownerId) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: isResponding
                      ? null
                      : () => _respondToBorrowRequest(
                            request,
                            status: 'rejected',
                          ),
                  icon: const Icon(Icons.close),
                  label: const Text('Từ chối'),
                ),
                FilledButton.icon(
                  onPressed: isResponding
                      ? null
                      : () => _respondToBorrowRequest(
                            request,
                            status: 'approved',
                          ),
                  icon: isResponding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Duyệt'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatBorrowDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

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
                .map((p) =>
                    '${p['shared_with_email']} (${p['permission_level']})')
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
                    r.detail ??
                        (r.allowed ? 'Server cho phép' : 'Server chặn (RLS)'),
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
  late final TextEditingController _tags;
  late final TextEditingController _locationName;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late int _status;
  late bool _pinned;
  DateTime? _dueDate;

  Future<void> _pickLocationPoint() async {
    final point = await LocationPickerDialog.show(
      context,
      initialLatitude: double.tryParse(_latitude.text.trim()),
      initialLongitude: double.tryParse(_longitude.text.trim()),
    );
    if (point != null && mounted) {
      setState(() {
        _latitude.text = point.latitude.toStringAsFixed(6);
        _longitude.text = point.longitude.toStringAsFixed(6);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.doc.title);
    _note = TextEditingController(text: widget.doc.note ?? '');
    _subjectCode = TextEditingController(text: widget.doc.subjectCode ?? '');
    _tags = TextEditingController(text: widget.doc.tags ?? '');
    _locationName = TextEditingController(text: widget.doc.locationName ?? '');
    _latitude =
        TextEditingController(text: widget.doc.latitude?.toString() ?? '');
    _longitude =
        TextEditingController(text: widget.doc.longitude?.toString() ?? '');
    _status = widget.doc.status;
    _pinned = widget.doc.isPinned;
    _dueDate = widget.doc.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _subjectCode.dispose();
    _tags.dispose();
    _locationName.dispose();
    _latitude.dispose();
    _longitude.dispose();
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
            const SizedBox(height: 12),
            TextField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Tag',
                helperText: 'Phân tách nhiều tag bằng dấu phẩy',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationName,
              decoration: const InputDecoration(
                  labelText: 'Tên vị trí', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth < 420
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        controller: _latitude,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: const InputDecoration(
                            labelText: 'Vĩ độ', border: OutlineInputBorder()),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        controller: _longitude,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: const InputDecoration(
                            labelText: 'Kinh độ', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                );
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickLocationPoint,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Chọn điểm trên bản đồ'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                final title = _title.text.trim();
                if (title.isEmpty) return;
                final latitudeText = _latitude.text.trim();
                final longitudeText = _longitude.text.trim();
                final latitude =
                    latitudeText.isEmpty ? null : double.tryParse(latitudeText);
                final longitude = longitudeText.isEmpty
                    ? null
                    : double.tryParse(longitudeText);
                if ((latitudeText.isNotEmpty &&
                        (latitude == null ||
                            !latitude.isFinite ||
                            latitude < -90 ||
                            latitude > 90)) ||
                    (longitudeText.isNotEmpty &&
                        (longitude == null ||
                            !longitude.isFinite ||
                            longitude < -180 ||
                            longitude > 180))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vĩ độ/kinh độ không hợp lệ')),
                  );
                  return;
                }
                final parsedTags = _tags.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
                Navigator.pop(context, {
                  'title': title,
                  'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
                  'subject_code': _subjectCode.text.trim().isEmpty
                      ? null
                      : _subjectCode.text.trim(),
                  'status': _status,
                  'is_pinned': _pinned,
                  'due_date': _dueDate?.toUtc().toIso8601String(),
                  'tags': parsedTags.isEmpty ? null : parsedTags.join(', '),
                  'location_name': _locationName.text.trim().isEmpty
                      ? null
                      : _locationName.text.trim(),
                  'latitude': latitude,
                  'longitude': longitude,
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
