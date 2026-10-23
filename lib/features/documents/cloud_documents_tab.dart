import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/models/cloud_document.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';
import 'cloud_document_details_page.dart';

/// Danh sách tài liệu trên Supabase.
/// [ownedByMe] = true: "Cloud của tôi"; false: "Được chia sẻ với tôi".
/// Truy vấn đi thẳng tới Supabase, RLS quyết định người dùng thấy những dòng nào.
class CloudDocumentsTab extends StatefulWidget {
  final bool ownedByMe;
  final String searchQuery;

  const CloudDocumentsTab({
    super.key,
    required this.ownedByMe,
    required this.searchQuery,
  });

  @override
  State<CloudDocumentsTab> createState() => _CloudDocumentsTabState();
}

class _CloudDocumentsTabState extends State<CloudDocumentsTab>
    with AutomaticKeepAliveClientMixin {
  Future<List<CloudDocument>>? _future;
  String? _loadedForUid;
  String _loadedQuery = '';

  @override
  bool get wantKeepAlive => true;

  void _reload() {
    setState(() {
      _loadedQuery = widget.searchQuery;
      _future = SupabaseService().searchDocuments(
        ownedByMe: widget.ownedByMe,
        searchQuery: widget.searchQuery,
      );
    });
  }

  @override
  void didUpdateWidget(covariant CloudDocumentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      // Debounce nhẹ để không gọi server mỗi lần gõ phím
      final q = widget.searchQuery;
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted && q == widget.searchQuery && q != _loadedQuery) {
          _reload();
        }
      });
    }
  }

  Future<void> _openDetails(CloudDocument doc) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CloudDocumentDetailsPage(documentId: doc.id),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      initialData: AuthService().currentUser,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          _loadedForUid = null;
          return _buildSignInPrompt();
        }
        if (_loadedForUid != user.uid) {
          _loadedForUid = user.uid;
          _loadedQuery = widget.searchQuery;
          _future = SupabaseService().searchDocuments(
            ownedByMe: widget.ownedByMe,
            searchQuery: widget.searchQuery,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _future?.catchError((_) => <CloudDocument>[]);
          },
          child: FutureBuilder<List<CloudDocument>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _buildMessage(
                  icon: Icons.cloud_off_rounded,
                  color: Colors.red.shade300,
                  title: 'Không tải được dữ liệu từ Supabase',
                  body: snapshot.error.toString(),
                  action: OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                );
              }
              final docs = snapshot.data ?? [];
              if (docs.isEmpty) {
                return _buildMessage(
                  icon: widget.ownedByMe
                      ? Icons.cloud_queue_rounded
                      : Icons.share_outlined,
                  color: Colors.grey.shade400,
                  title: widget.searchQuery.isNotEmpty
                      ? 'Không tìm thấy tài liệu khớp "${widget.searchQuery}"'
                      : widget.ownedByMe
                          ? 'Bạn chưa có tài liệu nào trên Cloud'
                          : 'Chưa có tài liệu nào được chia sẻ với bạn',
                  body: widget.ownedByMe
                      ? 'Bấm "Thêm Tài Liệu" khi đang đăng nhập để lưu lên Supabase (Database + Storage).'
                      : 'Khi người khác chia sẻ tài liệu tới ${user.email}, tài liệu sẽ xuất hiện tại đây.',
                  action: OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Làm mới'),
                  ),
                );
              }
              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: docs.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) return _buildHeader(user, docs.length);
                  final doc = docs[index - 1];
                  return _CloudDocumentCard(
                    doc: doc,
                    role: doc.roleFor(uid: user.uid, email: user.email),
                    showOwner: !widget.ownedByMe,
                    onTap: () => _openDetails(doc),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(User user, int count) {
    return Row(
      children: [
        Icon(Icons.verified_user_rounded,
            size: 16, color: Colors.deepPurple.shade300),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$count tài liệu • Supabase RLS lọc theo ${user.email}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: 'Làm mới từ Supabase',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: _reload,
        ),
      ],
    );
  }

  Widget _buildSignInPrompt() {
    return _buildMessage(
      icon: Icons.lock_person_outlined,
      color: Colors.deepPurple.shade300,
      title: 'Yêu Cầu Đăng Nhập Google',
      body: widget.ownedByMe
          ? 'Đăng nhập để lưu tài liệu lên Cloud (Supabase Storage + Database).'
          : 'Đăng nhập để xem các tài liệu được người khác chia sẻ cho bạn.',
      action: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () async {
          try {
            await AuthService().signInWithGoogle();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi đăng nhập Google: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.login),
        label: const Text('Đăng nhập bằng Google'),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    Widget? action,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 64, color: color),
                  const SizedBox(height: 16),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(body,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600)),
                  if (action != null) ...[
                    const SizedBox(height: 20),
                    action,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloudDocumentCard extends StatelessWidget {
  final CloudDocument doc;
  final DocumentRole role;
  final bool showOwner;
  final VoidCallback onTap;

  const _CloudDocumentCard({
    required this.doc,
    required this.role,
    required this.showOwner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sharedCount = doc.permissions.length;
    return Card(
      elevation: doc.isPinned ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: doc.isPinned
            ? BorderSide(color: Colors.amber.shade600, width: 1.5)
            : BorderSide(color: Colors.deepPurple.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showOwner) ...[
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: doc.ownerAvatar != null
                          ? NetworkImage(doc.ownerAvatar!)
                          : null,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: doc.ownerAvatar == null
                          ? Text(doc.displayOwner[0].toUpperCase(),
                              style: const TextStyle(fontSize: 11))
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chia sẻ bởi ${doc.displayOwner}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Text(
                        sharedCount == 0
                            ? 'Chưa chia sẻ'
                            : 'Đã chia sẻ với $sharedCount người',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  RoleBadge(role: role),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StatusIcon(status: doc.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      doc.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (doc.isPinned)
                    Icon(Icons.push_pin_rounded,
                        size: 18, color: Colors.amber.shade700),
                ],
              ),
              if (doc.note != null && doc.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  doc.note!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (doc.subjectCode != null)
                    _tag(doc.subjectCode!, Colors.blue),
                  if (doc.docType != null) _tag(doc.docType!, Colors.blueGrey),
                  if (doc.fileName != null || doc.fileUrl != null)
                    _tag(doc.fileName ?? 'Liên kết', Colors.teal,
                        icon: doc.filePath != null
                            ? Icons.cloud_done_rounded
                            : Icons.link),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class RoleBadge extends StatelessWidget {
  final DocumentRole role;
  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (role) {
      DocumentRole.owner => (Colors.green, Icons.star_rounded),
      DocumentRole.admin => (Colors.purple, Icons.security),
      DocumentRole.editor => (Colors.orange, Icons.edit),
      DocumentRole.viewer => (Colors.blue, Icons.visibility),
      DocumentRole.public => (Colors.teal, Icons.public),
      DocumentRole.none => (Colors.grey, Icons.block),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(role.label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class StatusIcon extends StatelessWidget {
  final int status;
  const StatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 2:
        return const Icon(Icons.check_circle_rounded,
            color: Colors.green, size: 22);
      case 1:
        return const Icon(Icons.timelapse_rounded,
            color: Colors.amber, size: 22);
      default:
        return const Icon(Icons.radio_button_unchecked,
            color: Colors.blueGrey, size: 22);
    }
  }
}
