import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/study_database.dart';

class AddEditSubjectPage extends StatefulWidget {
  final Subject? subject;

  const AddEditSubjectPage({super.key, this.subject});

  @override
  State<AddEditSubjectPage> createState() => _AddEditSubjectPageState();
}

class _AddEditSubjectPageState extends State<AddEditSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _teacherController;
  late int _credits;
  late String _selectedColorHex;

  final List<String> _presetColors = [
    '#3b82f6', // Blue
    '#10b981', // Green
    '#f59e0b', // Amber
    '#ef4444', // Red
    '#8b5cf6', // Purple
    '#ec4899', // Pink
    '#06b6d4', // Cyan
    '#64748b', // Slate
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _codeController = TextEditingController(text: widget.subject?.code ?? '');
    _teacherController =
        TextEditingController(text: widget.subject?.teacher ?? '');
    _credits = widget.subject?.credits ?? 3;
    _selectedColorHex = widget.subject?.colorHex ?? '#3b82f6';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;

    final db = Provider.of<StudyDatabase>(context, listen: false);
    final now = DateTime.now();

    if (widget.subject == null) {
      // Create new
      final newSubject = SubjectsCompanion.insert(
        subjectPk: 'sub-${now.millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        teacher: drift.Value(_teacherController.text.trim()),
        colorHex: drift.Value(_selectedColorHex),
        icon: const drift.Value('book'),
        credits: drift.Value(_credits),
        order: const drift.Value(0),
        dateTimeModified: now,
      );
      await db.subjectsDao.insertSubject(newSubject);
    } else {
      // Update
      final updated = widget.subject!.copyWith(
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        teacher: drift.Value(_teacherController.text.trim()),
        colorHex: _selectedColorHex,
        credits: _credits,
        dateTimeModified: now,
      );
      await db.subjectsDao.updateSubject(updated.toCompanion(true));
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subject != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Môn Học' : 'Thêm Môn Học Mới'),
        actions: [
          TextButton.icon(
            onPressed: _saveSubject,
            icon: const Icon(Icons.check),
            label: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên Môn Học *',
                hintText: 'VD: Lập trình di động với Flutter',
                prefixIcon: const Icon(Icons.school_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên môn' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Mã Môn Học *',
                      hintText: 'VD: INT3120',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nhập mã môn' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    value: _credits,
                    decoration: InputDecoration(
                      labelText: 'Số Tín Chỉ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [1, 2, 3, 4, 5, 6].map((c) {
                      return DropdownMenuItem(value: c, child: Text('$c tín'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _credits = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teacherController,
              decoration: InputDecoration(
                labelText: 'Giảng Viên Giảng Dạy',
                hintText: 'VD: TS. Nguyễn Văn A',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Màu Sắc Nhận Diện',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _presetColors.map((hex) {
                final color = _parseColor(hex);
                final isSelected = _selectedColorHex == hex;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColorHex = hex),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveSubject,
              child: Text(
                isEditing ? 'Cập Nhật Môn Học' : 'Tạo Môn Học Mới',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
