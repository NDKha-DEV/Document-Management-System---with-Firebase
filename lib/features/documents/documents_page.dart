import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../database/study_database.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';
import 'add_edit_document_page.dart';
import 'document_details_page.dart';

class DocumentsPage extends StatefulWidget {
  final String? initialSubjectFk;

  const DocumentsPage({super.key, this.initialSubjectFk});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  String? _selectedSubjectFk;
  String? _selectedDocTypeFk;
  int? _selectedStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int _sharedRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _selectedSubjectFk = widget.initialSubjectFk;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<StudyDatabase>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm tài liệu...',
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                )
              : const Text(
                  'Kho Tài Liệu Học Tập',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
            IconButton(
              tooltip: 'Thêm tài liệu',
              icon: const Icon(Icons.note_add_rounded),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditDocumentPage(
                      initialSubjectFk: _selectedSubjectFk,
                    ),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.folder_outlined),
                text: 'Tài liệu của tôi',
              ),
              Tab(
                icon: Icon(Icons.people_alt_outlined),
                text: 'Được chia sẻ',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Tài liệu của tôi (Local-First SQLite & Stream phản ứng)
            Column(
              children: [
                _buildFilterBar(db),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<List<DocumentWithDetails>>(
                    stream: db.documentsDao.watchDocuments(
                      subjectFk: _selectedSubjectFk,
                      docTypeFk: _selectedDocTypeFk,
                      status: _selectedStatus,
                      searchQuery: _searchQuery,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_outlined,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'Không có tài liệu nào phù hợp',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedSubjectFk != null || _selectedDocTypeFk != null
                                    ? 'Thử xóa bộ lọc hoặc tìm kiếm từ khóa khác'
                                    : 'Bấm nút + bên dưới để thêm tài liệu mới',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              if (_selectedSubjectFk != null || _selectedDocTypeFk != null) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedSubjectFk = null;
                                      _selectedDocTypeFk = null;
                                      _selectedStatus = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear_all),
                                  label: const Text('Xóa bộ lọc'),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = docs[index];
                          final doc = item.document;
                          final sub = item.subject;
                          final type = item.docType;
                          final subColor = _parseColor(sub?.colorHex);

                          return Card(
                            elevation: doc.isPinned ? 3 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: doc.isPinned
                                  ? BorderSide(color: Colors.amber.shade600, width: 1.5)
                                  : BorderSide(color: Colors.grey.shade300, width: 0.5),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DocumentDetailsPage(documentPk: doc.documentPk),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Status Checkbox Icon (tap to cycle)
                                        InkWell(
                                          onTap: () async {
                                            await db.documentsDao.toggleStatus(
                                                doc.documentPk, doc.status);
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: _buildStatusIcon(doc.status),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                doc.title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: doc.status == 2
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                  color: doc.status == 2
                                                      ? Colors.grey
                                                      : null,
                                                ),
                                              ),
                                              if (doc.note != null && doc.note!.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  doc.note!,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        // Pin Icon
                                        IconButton(
                                          icon: Icon(
                                            doc.isPinned
                                                ? Icons.push_pin_rounded
                                                : Icons.push_pin_outlined,
                                            color: doc.isPinned ? Colors.amber.shade700 : Colors.grey,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            await db.documentsDao.togglePin(
                                                doc.documentPk, doc.isPinned);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Tags Row: Subject + Type + DueDate
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (sub != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: subColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              sub.code,
                                              style: TextStyle(
                                                color: subColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (type != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              type.name,
                                              style: TextStyle(
                                                color: Colors.grey.shade800,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        if (doc.dueDate != null)
                                          _buildDueDateBadge(doc.dueDate!, doc.status == 2),
                                        if (doc.externalUrl != null && doc.externalUrl!.isNotEmpty)
                                          Icon(Icons.link, size: 16, color: Colors.blue.shade600),
                                        if (doc.localFilePath != null && doc.localFilePath!.isNotEmpty)
                                          Icon(Icons.attach_file, size: 16, color: Colors.teal.shade600),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            // TAB 2: Được chia sẻ với tôi (Supabase Cloud + RLS)
            _buildSharedWithMeTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddEditDocumentPage(
                  initialSubjectFk: _selectedSubjectFk,
                ),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm Tài Liệu'),
        ),
      ),
    );
  }

  Widget _buildSharedWithMeTab() {
    final user = AuthService().currentUser;

    if (user == null || user.email == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person_outlined, size: 64, color: Colors.deepPurple.shade300),
              const SizedBox(height: 16),
              const Text(
                'Yêu Cầu Đăng Nhập Google',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Đăng nhập tài khoản Google để xem các tài liệu được người khác chia sẻ cho bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await AuthService().signInWithGoogle();
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.login),
                label: const Text('Đăng nhập bằng Google'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _sharedRefreshKey++);
      },
      child: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(_sharedRefreshKey),
        future: SupabaseService().getAccessibleDocuments(
          currentUserId: user.uid,
          currentUserEmail: user.email!,
          searchQuery: _searchQuery,
          subjectCode: _selectedSubjectFk,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data ?? [];
          // Lọc tài liệu được người khác chia sẻ (không phải do chính tôi tạo)
          final sharedDocs = allDocs.where((d) => d['owner_id'] != user.uid).toList();

          if (sharedDocs.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có tài liệu nào được chia sẻ với bạn',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Khi người dùng khác chia sẻ tài liệu đến email "${user.email}", tài liệu sẽ xuất hiện tại đây.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sharedDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = sharedDocs[index];
              final title = doc['title'] as String? ?? 'Tài liệu không tên';
              final note = doc['note'] as String?;
              final fileUrl = doc['file_url'] as String?;
              final fileName = doc['file_name'] as String?;
              final owner = doc['profiles'] as Map<String, dynamic>?;
              final ownerName = owner?['display_name'] ?? owner?['email'] ?? 'Người dùng';
              final ownerAvatar = owner?['avatar_url'] as String?;
              final perms = (doc['permissions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final myPerm = perms.firstWhere(
                (p) => p['shared_with_email'] == user.email,
                orElse: () => {'permission_level': 'viewer'},
              );
              final role = myPerm['permission_level'] as String? ?? 'viewer';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.deepPurple.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Owner info + Permission Badge
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: ownerAvatar != null ? NetworkImage(ownerAvatar) : null,
                            backgroundColor: Colors.deepPurple.shade100,
                            child: ownerAvatar == null
                                ? Text(
                                    ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Chia sẻ bởi: $ownerName',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildRoleBadge(role),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Document Title
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (note != null && note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Footer Actions: Open Cloud Storage File URL
                      if (fileUrl != null && fileUrl.isNotEmpty) ...[
                        InkWell(
                          onTap: () => _launchUrl(fileUrl),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.deepPurple.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_download_rounded, color: Colors.deepPurple, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fileName ?? 'Tệp tài liệu trên Cloud Storage',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.open_in_new, size: 16, color: Colors.deepPurple),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String label;

    switch (role) {
      case 'admin':
        color = Colors.purple;
        label = 'Admin';
        break;
      case 'editor':
        color = Colors.orange;
        label = 'Editor';
        break;
      case 'viewer':
      default:
        color = Colors.blue;
        label = 'Viewer';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFilterBar(StudyDatabase db) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Subject Filter Horizontal List
          StreamBuilder<List<Subject>>(
            stream: db.subjectsDao.watchAllSubjects(),
            builder: (context, snapshot) {
              final subjects = snapshot.data ?? [];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả môn'),
                      selected: _selectedSubjectFk == null,
                      onSelected: (val) {
                        if (val) setState(() => _selectedSubjectFk = null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...subjects.map((s) {
                      final isSelected = _selectedSubjectFk == s.subjectPk;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s.code),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => _selectedSubjectFk = val ? s.subjectPk : null);
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          // DocType Filter Horizontal List
          StreamBuilder<List<DocType>>(
            stream: db.docTypesDao.watchAllDocTypes(),
            builder: (context, snapshot) {
              final types = snapshot.data ?? [];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Mọi loại'),
                      selected: _selectedDocTypeFk == null,
                      onSelected: (val) {
                        if (val) setState(() => _selectedDocTypeFk = null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...types.map((t) {
                      final isSelected = _selectedDocTypeFk == t.docTypePk;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t.name),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => _selectedDocTypeFk = val ? t.docTypePk : null);
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(int status) {
    switch (status) {
      case 2:
        return const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24);
      case 1:
        return const Icon(Icons.timelapse_rounded, color: Colors.amber, size: 24);
      case 0:
      default:
        return const Icon(Icons.radio_button_unchecked, color: Colors.blueGrey, size: 24);
    }
  }

  Widget _buildDueDateBadge(DateTime due, bool isDone) {
    final now = DateTime.now();
    final diff = due.difference(now).inDays;
    Color bg = Colors.blue.shade50;
    Color text = Colors.blue.shade800;

    String label = '${due.day}/${due.month}';
    if (!isDone) {
      if (diff < 0) {
        bg = Colors.red.shade100;
        text = Colors.red.shade900;
        label = 'Quá hạn ($label)';
      } else if (diff == 0) {
        bg = Colors.amber.shade100;
        text = Colors.amber.shade900;
        label = 'Hôm nay';
      } else if (diff <= 3) {
        bg = Colors.orange.shade100;
        text = Colors.orange.shade900;
        label = '$diff ngày tới';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 10, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
