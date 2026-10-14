import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../database/study_database.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';
import 'add_edit_document_page.dart';

class DocumentDetailsPage extends StatelessWidget {
  final String documentPk;

  const DocumentDetailsPage({super.key, required this.documentPk});

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.blue;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openShareSheet(BuildContext context, String docId, String docTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ShareDocumentSheet(
        documentId: docId,
        documentTitle: docTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<StudyDatabase>(context);

    return StreamBuilder<List<DocumentWithDetails>>(
      stream: db.documentsDao.watchDocuments(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final match = snapshot.data!
            .where((item) => item.document.documentPk == documentPk)
            .toList();

        if (match.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Tài liệu không tồn tại hoặc đã bị xóa')),
          );
        }

        final item = match.first;
        final doc = item.document;
        final sub = item.subject;
        final type = item.docType;
        final subColor = _parseColor(sub?.colorHex);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi Tiết Tài Liệu'),
            actions: [
              IconButton(
                tooltip: 'Chia sẻ tài liệu',
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _openShareSheet(context, doc.documentPk, doc.title),
              ),
              IconButton(
                tooltip: 'Sửa tài liệu',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditDocumentPage(document: doc),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Xóa tài liệu',
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xác nhận xóa tài liệu?'),
                      content: Text('Bạn có chắc muốn xóa "${doc.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await db.documentsDao.deleteDocument(doc.documentPk);
                    // Đồng bộ xóa cả trên Supabase
                    try {
                      await SupabaseService().deleteDocument(doc.documentPk);
                    } catch (_) {}

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Title & Pin
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      doc.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (doc.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.push_pin, color: Colors.amber, size: 24),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Badges Row
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (sub != null)
                    Chip(
                      backgroundColor: subColor.withOpacity(0.15),
                      label: Text(
                        '${sub.code} • ${sub.name}',
                        style: TextStyle(
                            color: subColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (type != null)
                    Chip(
                      avatar: const Icon(Icons.category_outlined, size: 16),
                      label: Text(type.name),
                    ),
                  _buildStatusChip(doc.status),
                ],
              ),
              const SizedBox(height: 20),

              // Due Date Card
              if (doc.dueDate != null)
                Card(
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.event_available, color: Colors.blue),
                    title: Text(
                      'Hạn nộp / Lịch học: ${doc.dueDate!.day}/${doc.dueDate!.month}/${doc.dueDate!.year}',
                      style: const TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // External URL / Firebase Cloud Storage Box
              if (doc.externalUrl != null && doc.externalUrl!.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final isCloudStorage = doc.externalUrl!.contains('firebasestorage.googleapis.com') ||
                        doc.externalUrl!.contains('storage.googleapis.com');

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isCloudStorage ? Colors.deepPurple.shade200 : Colors.blue.shade200,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isCloudStorage ? Icons.cloud_download_rounded : Icons.link,
                          color: isCloudStorage ? Colors.deepPurple : Colors.blue,
                        ),
                        title: Text(
                          isCloudStorage
                              ? 'Tệp Đám Mây (Firebase Cloud Storage)'
                              : 'Mở liên kết tài liệu trực tuyến',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          isCloudStorage ? 'Bấm để mở hoặc tải tệp về máy' : doc.externalUrl!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.open_in_new, size: 20),
                        onTap: () => _launchUrl(doc.externalUrl!),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Local File Path Box
              if (doc.localFilePath != null && doc.localFilePath!.isNotEmpty) ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.teal.shade200),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.attach_file, color: Colors.teal),
                    title: const Text('Tệp đính kèm cục bộ'),
                    subtitle: Text(
                      doc.localFilePath!.split(RegExp(r'[\\/]')).last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Note Card
              if (doc.note != null && doc.note!.isNotEmpty) ...[
                const Text(
                  'Ghi chú & Tóm tắt',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    doc.note!,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Supabase Cloud Share Card
              Card(
                elevation: 0,
                color: Colors.deepPurple.shade50.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.deepPurple.shade200),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.share, color: Colors.white, size: 20),
                  ),
                  title: const Text(
                    'Chia Sẻ Tài Liệu Qua Cloud',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Phân quyền người xem (Viewer, Editor, Admin)'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => _openShareSheet(context, doc.documentPk, doc.title),
                ),
              ),

              const SizedBox(height: 24),

              // Toggle Status Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await db.documentsDao.toggleStatus(doc.documentPk, doc.status);
                },
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(
                  doc.status == 2
                      ? 'Đổi trạng thái: Chuyển về "Cần đọc"'
                      : doc.status == 1
                          ? 'Đổi trạng thái: Đánh dấu "Hoàn thành"'
                          : 'Đổi trạng thái: Chuyển sang "Đang làm"',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(int status) {
    switch (status) {
      case 2:
        return const Chip(
          backgroundColor: Color(0xFFD1FAE5),
          avatar: Icon(Icons.check_circle, color: Colors.green, size: 16),
          label: Text('Đã hoàn thành',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        );
      case 1:
        return const Chip(
          backgroundColor: Color(0xFFFEF3C7),
          avatar: Icon(Icons.timelapse, color: Colors.amber, size: 16),
          label: Text('Đang làm',
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        );
      case 0:
      default:
        return const Chip(
          avatar: Icon(Icons.radio_button_unchecked, size: 16),
          label: Text('Cần đọc'),
        );
    }
  }
}

/// Bottom Sheet Quản lý và Chia sẻ tài liệu qua Supabase
class _ShareDocumentSheet extends StatefulWidget {
  final String documentId;
  final String documentTitle;

  const _ShareDocumentSheet({
    required this.documentId,
    required this.documentTitle,
  });

  @override
  State<_ShareDocumentSheet> createState() => _ShareDocumentSheetState();
}

class _ShareDocumentSheetState extends State<_ShareDocumentSheet> {
  final _emailController = TextEditingController();
  String _selectedRole = 'viewer';
  bool _isSharing = false;
  bool _isLoadingPermissions = true;
  List<Map<String, dynamic>> _permissions = [];

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoadingPermissions = true);
    final perms = await SupabaseService().getDocumentPermissions(widget.documentId);
    if (mounted) {
      setState(() {
        _permissions = perms;
        _isLoadingPermissions = false;
      });
    }
  }

  Future<void> _onShare() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ email người nhận hợp lệ')),
      );
      return;
    }

    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập bằng tài khoản Google để thực hiện chia sẻ')),
      );
      return;
    }

    setState(() => _isSharing = true);
    final result = await SupabaseService().shareDocument(
      documentId: widget.documentId,
      recipientEmail: email,
      permissionLevel: _selectedRole,
      grantedBy: currentUser.uid,
    );

    if (mounted) {
      setState(() => _isSharing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
      if (result.success) {
        _emailController.clear();
        _loadPermissions();
      }
    }
  }

  Future<void> _onRevoke(dynamic permissionId, String email) async {
    final id = permissionId is int ? permissionId : int.tryParse(permissionId.toString()) ?? 0;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi quyền truy cập?'),
        content: Text('Bạn có chắc muốn ngừng chia sẻ tài liệu với $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await SupabaseService().revokePermission(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã thu hồi quyền của $email')),
          );
          _loadPermissions();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể thu hồi quyền, vui lòng thử lại')),
          );
        }
      }
    }
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String label;
    IconData icon;

    switch (role) {
      case 'admin':
        color = Colors.purple;
        label = 'Toàn quyền (Admin)';
        icon = Icons.security;
        break;
      case 'editor':
        color = Colors.orange;
        label = 'Chỉnh sửa (Editor)';
        icon = Icons.edit;
        break;
      case 'viewer':
      default:
        color = Colors.blue;
        label = 'Chỉ xem (Viewer)';
        icon = Icons.visibility;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isSignedIn = AuthService().isSignedIn;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.share, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chia sẻ: ${widget.documentTitle}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm người xem hoặc cộng tác viên qua tài khoản Google.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),

            if (!isSignedIn) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bạn cần đăng nhập tài khoản Google để thực hiện chia sẻ tài liệu.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Form Input
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email người nhận',
                        hintText: 'vidu@gmail.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Quyền',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'viewer', child: Text('Chỉ xem')),
                        DropdownMenuItem(value: 'editor', child: Text('Chỉnh sửa')),
                        DropdownMenuItem(value: 'admin', child: Text('Toàn quyền')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSharing ? null : _onShare,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isSharing ? 'Đang chia sẻ...' : 'Gửi lời mời chia sẻ'),
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Divider(),
            const SizedBox(height: 8),

            // Danh sách người đã được chia sẻ
            const Text(
              'Những người có quyền truy cập',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            if (_isLoadingPermissions)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_permissions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Chưa có ai được chia sẻ tài liệu này.',
                    style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _permissions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final perm = _permissions[index];
                  final email = perm['shared_with_email'] as String? ?? 'N/A';
                  final role = perm['permission_level'] as String? ?? 'viewer';
                  final permId = perm['id'];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        email.isNotEmpty ? email[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                    ),
                    title: Text(email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildRoleBadge(role),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                      tooltip: 'Thu hồi quyền',
                      onPressed: () => _onRevoke(permId, email),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
