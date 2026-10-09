import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/study_database.dart';
import '../documents/document_details_page.dart';

class DeadlinesPage extends StatelessWidget {
  const DeadlinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<StudyDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch Nộp & Deadline',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<DocumentWithDetails>>(
        stream: db.documentsDao.watchDeadlines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allWithDeadlines = snapshot.data ?? [];
          if (allWithDeadlines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_outlined,
                      size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có bài tập hay deadline nào',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text('Khi thêm tài liệu có đặt hạn nộp, lịch sẽ hiển thị tại đây'),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final endOfWeek = today.add(const Duration(days: 7));

          final overdue = <DocumentWithDetails>[];
          final dueToday = <DocumentWithDetails>[];
          final thisWeek = <DocumentWithDetails>[];
          final future = <DocumentWithDetails>[];
          final completed = <DocumentWithDetails>[];

          for (final item in allWithDeadlines) {
            final due = item.document.dueDate!;
            final dueDay = DateTime(due.year, due.month, due.day);

            if (item.document.status == 2) {
              completed.add(item);
            } else if (dueDay.isBefore(today)) {
              overdue.add(item);
            } else if (dueDay.isAtSameMomentAs(today)) {
              dueToday.add(item);
            } else if (dueDay.isBefore(endOfWeek)) {
              thisWeek.add(item);
            } else {
              future.add(item);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (overdue.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Quá Hạn (${overdue.length})',
                  Colors.red,
                  Icons.warning_amber_rounded,
                ),
                ...overdue.map((i) => _buildDeadlineCard(context, db, i, Colors.red)),
                const SizedBox(height: 16),
              ],
              if (dueToday.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Hôm Nay (${dueToday.length})',
                  Colors.amber.shade800,
                  Icons.alarm_on_rounded,
                ),
                ...dueToday
                    .map((i) => _buildDeadlineCard(context, db, i, Colors.amber.shade800)),
                const SizedBox(height: 16),
              ],
              if (thisWeek.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Tuần Này (${thisWeek.length})',
                  Colors.blue,
                  Icons.calendar_today_rounded,
                ),
                ...thisWeek
                    .map((i) => _buildDeadlineCard(context, db, i, Colors.blue)),
                const SizedBox(height: 16),
              ],
              if (future.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Sắp Tới (${future.length})',
                  Colors.teal,
                  Icons.next_plan_outlined,
                ),
                ...future.map((i) => _buildDeadlineCard(context, db, i, Colors.teal)),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Đã Hoàn Thành (${completed.length})',
                  Colors.green,
                  Icons.check_circle_outline,
                ),
                ...completed
                    .map((i) => _buildDeadlineCard(context, db, i, Colors.green)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineCard(
      BuildContext context, StudyDatabase db, DocumentWithDetails item, Color accentColor) {
    final doc = item.document;
    final sub = item.subject;
    final due = doc.dueDate!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        leading: Checkbox(
          value: doc.status == 2,
          activeColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (val) async {
            await db.documentsDao.toggleStatus(doc.documentPk, doc.status);
          },
        ),
        title: Text(
          doc.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: doc.status == 2 ? TextDecoration.lineThrough : null,
            color: doc.status == 2 ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          '${sub?.code ?? "Môn học"} • Hạn: ${due.day}/${due.month}/${due.year}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DocumentDetailsPage(documentPk: doc.documentPk),
            ),
          );
        },
      ),
    );
  }
}
