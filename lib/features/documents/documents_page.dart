import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/study_database.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/account_button.dart';
import 'add_edit_document_page.dart';
import 'cloud_documents_tab.dart';
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

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<StudyDatabase>(context);

    return DefaultTabController(
      length: 3,
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
            const AccountButton(),
            IconButton(
              tooltip: 'Tìm kiếm (trên máy & Supabase)',
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
                icon: Icon(Icons.phone_android_rounded),
                text: 'Trên máy',
              ),
              Tab(
                icon: Icon(Icons.cloud_outlined),
                text: 'Cloud của tôi',
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
                                            SupabaseService()
                                                .patchOwnDocumentSilently(
                                                    doc.documentPk, {
                                              'status': (doc.status + 1) % 3
                                            });
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
                                            SupabaseService()
                                                .patchOwnDocumentSilently(
                                                    doc.documentPk, {
                                              'is_pinned': !doc.isPinned
                                            });
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

            // TAB 2: Tài liệu của tôi trên Supabase Cloud
            CloudDocumentsTab(ownedByMe: true, searchQuery: _searchQuery),

            // TAB 3: Được chia sẻ với tôi (Supabase Cloud + RLS)
            CloudDocumentsTab(ownedByMe: false, searchQuery: _searchQuery),
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
