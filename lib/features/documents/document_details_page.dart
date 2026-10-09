import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../database/study_database.dart';
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
              ],

              const SizedBox(height: 30),
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
