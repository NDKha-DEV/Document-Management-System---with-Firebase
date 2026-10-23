import 'package:flutter/material.dart';
import '../../core/models/cloud_document.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';

/// Mở bottom sheet quản lý chia sẻ tài liệu qua Supabase.
/// [role] là quyền của người đang mở (owner/admin) — admin không được cấp quyền Admin.
Future<void> showShareDocumentSheet(
  BuildContext context, {
  required String documentId,
  required String documentTitle,
  DocumentRole role = DocumentRole.owner,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => ShareDocumentSheet(
      documentId: documentId,
      documentTitle: documentTitle,
      role: role,
    ),
  );
}

class ShareDocumentSheet extends StatefulWidget {
  final String documentId;
  final String documentTitle;
  final DocumentRole role;

  const ShareDocumentSheet({
    super.key,
    required this.documentId,
    required this.documentTitle,
    this.role = DocumentRole.owner,
  });

  @override
  State<ShareDocumentSheet> createState() => _ShareDocumentSheetState();
}

class _ShareDocumentSheetState extends State<ShareDocumentSheet> {
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
    final perms =
        await SupabaseService().getDocumentPermissions(widget.documentId);
    if (mounted) {
      setState(() {
        _permissions = perms;
        _isLoadingPermissions = false;
      });
    }
  }

  void _toast(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _onShare() async {
    final email = _emailController.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _toast('Vui lòng nhập địa chỉ email người nhận hợp lệ');
      return;
    }

    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      _toast('Bạn cần đăng nhập bằng tài khoản Google để thực hiện chia sẻ');
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
      _toast(result.message,
          color: result.success ? Colors.green : Colors.red);
      if (result.success) {
        _emailController.clear();
        _loadPermissions();
      }
    }
  }

  Future<void> _onRevoke(dynamic permissionId, String email) async {
    final id = permissionId is int
        ? permissionId
        : int.tryParse(permissionId.toString()) ?? 0;
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
          _toast('Đã thu hồi quyền của $email');
          _loadPermissions();
        } else {
          _toast('Không thể thu hồi quyền (RLS chặn hoặc lỗi mạng)',
              color: Colors.red);
        }
      }
    }
  }

  bool _canRevoke(String level) =>
      widget.role == DocumentRole.owner ||
      (widget.role == DocumentRole.admin && level != 'admin');

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
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.role == DocumentRole.admin
                  ? 'Bạn là Admin của tài liệu này: được chia sẻ quyền Xem / Chỉnh sửa.'
                  : 'Thêm người xem hoặc cộng tác viên qua email tài khoản Google.',
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      onSubmitted: (_) => _onShare(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Quyền',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: 'viewer', child: Text('Chỉ xem')),
                        const DropdownMenuItem(
                            value: 'editor', child: Text('Chỉnh sửa')),
                        if (widget.role.canGrantAdmin)
                          const DropdownMenuItem(
                              value: 'admin', child: Text('Toàn quyền')),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSharing ? null : _onShare,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isSharing ? 'Đang chia sẻ...' : 'Chia sẻ'),
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Divider(),
            const SizedBox(height: 8),
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
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic),
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
                  final level = perm['permission_level'] as String? ?? 'viewer';
                  final linked = perm['shared_with_user_id'] != null;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        email.isNotEmpty ? email[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                    ),
                    title: Text(email,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildRoleBadge(level),
                          if (!linked)
                            Text('Chờ đăng nhập lần đầu',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    trailing: _canRevoke(level)
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent, size: 20),
                            tooltip: 'Thu hồi quyền',
                            onPressed: () => _onRevoke(perm['id'], email),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
