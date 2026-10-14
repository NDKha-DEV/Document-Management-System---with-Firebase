import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import '../../database/study_database.dart';
import '../../core/services/cloud_storage_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';

class AddEditDocumentPage extends StatefulWidget {
  final Document? document;
  final String? initialSubjectFk;

  const AddEditDocumentPage({
    super.key,
    this.document,
    this.initialSubjectFk,
  });

  @override
  State<AddEditDocumentPage> createState() => _AddEditDocumentPageState();
}

class _AddEditDocumentPageState extends State<AddEditDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late TextEditingController _urlController;

  String? _selectedSubjectFk;
  String? _selectedDocTypeFk;
  DateTime? _dueDate;
  int _status = 0;
  bool _isPinned = false;
  String? _localFilePath;
  Uint8List? _fileBytes;
  String? _pickedFileName;
  bool _uploadToCloud = true;
  bool _isSaving = false;

  List<Subject> _subjects = [];
  List<DocType> _docTypes = [];
  bool _isLoadingDropdowns = true;

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    _titleController = TextEditingController(text: d?.title ?? '');
    _noteController = TextEditingController(text: d?.note ?? '');
    _urlController = TextEditingController(text: d?.externalUrl ?? '');
    _selectedSubjectFk = d?.subjectFk ?? widget.initialSubjectFk;
    _selectedDocTypeFk = d?.docTypeFk;
    _dueDate = d?.dueDate;
    _status = d?.status ?? 0;
    _isPinned = d?.isPinned ?? false;
    _localFilePath = d?.localFilePath;

    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    final db = Provider.of<StudyDatabase>(context, listen: false);
    final subs = await db.subjectsDao.getAllSubjects();
    final types = await db.docTypesDao.getAllDocTypes();

    setState(() {
      _subjects = subs;
      _docTypes = types;
      if (_selectedSubjectFk == null && subs.isNotEmpty) {
        _selectedSubjectFk = subs.first.subjectPk;
      }
      if (_selectedDocTypeFk == null && types.isNotEmpty) {
        _selectedDocTypeFk = types.first.docTypePk;
      }
      _isLoadingDropdowns = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'zip', 'png', 'jpg'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      setState(() {
        _localFilePath = file.path;
        _pickedFileName = file.name;
        _fileBytes = file.bytes;
      });
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectFk == null || _selectedDocTypeFk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn Môn học và Phân loại tài liệu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final db = Provider.of<StudyDatabase>(context, listen: false);
    final now = DateTime.now();
    final docPk = widget.document?.documentPk ?? 'doc-${now.millisecondsSinceEpoch}';

    String? finalUrl = _urlController.text.trim().isEmpty ? null : _urlController.text.trim();

    // Tải tệp lên Firebase Cloud Storage nếu được chọn
    if (_uploadToCloud && (_fileBytes != null || _localFilePath != null)) {
      try {
        final fileName = _pickedFileName ?? (_localFilePath?.split(RegExp(r'[\\/]')).last ?? 'file_attachment');
        File? uploadFile;
        if (!kIsWeb && _localFilePath != null) {
          uploadFile = File(_localFilePath!);
        }

        final cloudUrl = await CloudStorageService().uploadDocumentFile(
          documentId: docPk,
          fileName: fileName,
          file: uploadFile,
          bytes: _fileBytes,
        );

        if (cloudUrl != null) {
          finalUrl = cloudUrl; // Lưu URL Cloud Storage làm externalUrl
        }
      } catch (e) {
        debugPrint('Thông báo tải lên Cloud Storage: $e');
        // Tiếp tục lưu cục bộ mà không gián đoạn người dùng
      }
    }

    if (widget.document == null) {
      // Insert
      final newDoc = DocumentsCompanion.insert(
        documentPk: docPk,
        title: _titleController.text.trim(),
        note: drift.Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
        localFilePath: drift.Value(_localFilePath ?? _pickedFileName),
        externalUrl: drift.Value(finalUrl),
        subjectFk: _selectedSubjectFk!,
        docTypeFk: _selectedDocTypeFk!,
        dueDate: drift.Value(_dueDate),
        status: drift.Value(_status),
        isPinned: drift.Value(_isPinned),
        dateTimeCreated: now,
        dateTimeModified: now,
      );
      await db.documentsDao.insertDocument(newDoc);
    } else {
      // Update
      final updated = widget.document!.copyWith(
        title: _titleController.text.trim(),
        note: drift.Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
        localFilePath: drift.Value(_localFilePath ?? widget.document!.localFilePath),
        externalUrl: drift.Value(finalUrl),
        subjectFk: _selectedSubjectFk!,
        docTypeFk: _selectedDocTypeFk!,
        dueDate: drift.Value(_dueDate),
        status: _status,
        isPinned: _isPinned,
        dateTimeModified: now,
      );
      await db.documentsDao.updateDocument(updated.toCompanion(true));
    }

    // Tự động đồng bộ tài liệu sang Supabase nếu người dùng đã đăng nhập Google
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser != null) {
        final subMatch = _subjects.where((s) => s.subjectPk == _selectedSubjectFk);
        final subName = subMatch.isNotEmpty ? subMatch.first.name : null;
        final typeMatch = _docTypes.where((t) => t.docTypePk == _selectedDocTypeFk);
        final docTypeName = typeMatch.isNotEmpty ? typeMatch.first.name : null;

        await SupabaseService().saveDocument(
          documentId: docPk,
          ownerId: currentUser.uid,
          title: _titleController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          subjectCode: _selectedSubjectFk,
          subjectName: subName,
          docType: docTypeName,
          status: _status,
          dueDate: _dueDate,
          isPinned: _isPinned,
          fileUrl: finalUrl,
          fileName: _pickedFileName,
          fileSize: _fileBytes?.length ?? 0,
        );
      }
    } catch (e) {
      debugPrint('Thông báo đồng bộ Supabase: $e');
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(finalUrl != null && finalUrl.contains('firebasestorage')
              ? 'Đã lưu tài liệu và tải tệp lên Firebase Cloud Storage!'
              : 'Đã lưu tài liệu thành công!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.document != null;

    if (_isLoadingDropdowns) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isUserSignedIn = AuthService().isSignedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa Tài Liệu' : 'Thêm Tài Liệu Mới'),
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: _saveDocument,
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
            // Title Input
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tiêu Đề Tài Liệu *',
                hintText: 'VD: Slide Chương 3, Bài tập lớn cuối kỳ...',
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề tài liệu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Subject Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSubjectFk,
              decoration: InputDecoration(
                labelText: 'Môn Học *',
                prefixIcon: const Icon(Icons.school_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _subjects.map((sub) {
                return DropdownMenuItem(
                  value: sub.subjectPk,
                  child: Text('${sub.code} - ${sub.name}', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSubjectFk = val);
              },
            ),
            const SizedBox(height: 16),
            // DocType & Status Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDocTypeFk,
                    decoration: InputDecoration(
                      labelText: 'Phân Loại *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _docTypes.map((type) {
                      return DropdownMenuItem(
                        value: type.docTypePk,
                        child: Text(type.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDocTypeFk = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'Trạng Thái',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Cần đọc')),
                      DropdownMenuItem(value: 1, child: Text('Đang làm')),
                      DropdownMenuItem(value: 2, child: Text('Hoàn thành')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Liên Kết Web hoặc Tải từ Đám mây (URL)',
                hintText: 'https://drive.google.com/... hoặc link tải tài liệu',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            // File Attachment Picker Box
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ListTile(
                leading: Icon(
                  _pickedFileName != null || _localFilePath != null
                      ? Icons.insert_drive_file_rounded
                      : Icons.attach_file_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  _pickedFileName ??
                      (_localFilePath != null
                          ? _localFilePath!.split(RegExp(r'[\\/]')).last
                          : 'Đính kèm tệp từ máy (PDF, Docx, Slide...)'),
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: _pickedFileName != null || _localFilePath != null
                    ? const Text('Bấm để đổi tệp khác', style: TextStyle(fontSize: 12))
                    : const Text('Hỗ trợ tải lên Firebase Cloud Storage', style: TextStyle(fontSize: 12)),
                trailing: _pickedFileName != null || _localFilePath != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() {
                          _localFilePath = null;
                          _pickedFileName = null;
                          _fileBytes = null;
                        }),
                      )
                    : null,
                onTap: _pickFile,
              ),
            ),
            if ((_pickedFileName != null || _localFilePath != null) && isUserSignedIn) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                dense: true,
                secondary: const Icon(Icons.cloud_upload_rounded, color: Colors.blue),
                title: const Text('Tự động tải tệp lên Firebase Cloud Storage'),
                subtitle: const Text('Lưu trữ đám mây giúp mở tệp từ bất kỳ thiết bị nào'),
                value: _uploadToCloud,
                onChanged: (val) => setState(() => _uploadToCloud = val),
              ),
            ],
            const SizedBox(height: 16),
            // Due Date Picker Box
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ListTile(
                leading: const Icon(Icons.event_rounded, color: Colors.blue),
                title: Text(
                  _dueDate != null
                      ? 'Hạn nộp: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                      : 'Chưa đặt hạn nộp (Deadline)',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: const Text('Nhắc nhở bài tập và lịch thi', style: TextStyle(fontSize: 12)),
                trailing: _dueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _dueDate = null),
                      )
                    : const Icon(Icons.calendar_month, size: 20),
                onTap: _selectDueDate,
              ),
            ),
            const SizedBox(height: 16),
            // Pin Switch
            SwitchListTile(
              title: const Text('Ghim lên đầu danh sách (Quan trọng)'),
              subtitle: const Text('Hiển thị ưu tiên khi mở danh sách tài liệu'),
              value: _isPinned,
              onChanged: (val) => setState(() => _isPinned = val),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Ghi Chú & Tóm Tắt Nội Dung',
                hintText: 'Ghi chú các ý chính của bài giảng, yêu cầu bài tập...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _saveDocument,
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('Đang lưu và tải lên Cloud...'),
                      ],
                    )
                  : Text(
                      isEditing ? 'Cập Nhật Tài Liệu' : 'Lưu Tài Liệu Mới',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
