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
import 'location_picker_dialog.dart';

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
  late TextEditingController _tagsController;
  late TextEditingController _locationNameController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

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
    _tagsController = TextEditingController(text: d?.tags ?? '');
    _locationNameController =
        TextEditingController(text: d?.locationName ?? '');
    _latitudeController =
        TextEditingController(text: d?.latitude?.toString() ?? '');
    _longitudeController =
        TextEditingController(text: d?.longitude?.toString() ?? '');
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
    _tagsController.dispose();
    _locationNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'zip',
        'png',
        'jpg'
      ],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      setState(() {
        _localFilePath = kIsWeb ? null : file.path;
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

  Future<void> _pickLocationPoint() async {
    final point = await LocationPickerDialog.show(
      context,
      initialLatitude: double.tryParse(_latitudeController.text.trim()),
      initialLongitude: double.tryParse(_longitudeController.text.trim()),
    );
    if (point != null && mounted) {
      setState(() {
        _latitudeController.text = point.latitude.toStringAsFixed(6);
        _longitudeController.text = point.longitude.toStringAsFixed(6);
      });
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectFk == null || _selectedDocTypeFk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn Môn học và Phân loại tài liệu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final db = Provider.of<StudyDatabase>(context, listen: false);
    final now = DateTime.now();
    final docPk =
        widget.document?.documentPk ?? 'doc-${now.millisecondsSinceEpoch}';

    final String? finalUrl =
        _urlController.text.trim().isEmpty ? null : _urlController.text.trim();
    final parsedTags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
    final tags = parsedTags.isEmpty ? null : parsedTags.join(', ');
    final locationName = _locationNameController.text.trim().isEmpty
        ? null
        : _locationNameController.text.trim();
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    // Tải tệp MỚI CHỌN lên Supabase Storage (chỉ khi đã đăng nhập Google)
    UploadedFile? uploaded;
    String? uploadError;
    final hasNewFile = _fileBytes != null || _pickedFileName != null;
    if (_uploadToCloud && hasNewFile && AuthService().isSignedIn) {
      try {
        final fileName = _pickedFileName ??
            (_localFilePath?.split(RegExp(r'[\\/]')).last ?? 'file_attachment');
        File? uploadFile;
        if (!kIsWeb && _localFilePath != null) {
          uploadFile = File(_localFilePath!);
        }

        uploaded = await CloudStorageService().uploadDocumentFile(
          documentId: docPk,
          fileName: fileName,
          file: uploadFile,
          bytes: _fileBytes,
        );
      } catch (e) {
        debugPrint('Thông báo tải lên Cloud Storage: $e');
        uploadError = e.toString();
        // Tiếp tục lưu thông tin tài liệu, chỉ báo lỗi tải tệp
      }
    }

    if (widget.document == null) {
      // Insert
      final newDoc = DocumentsCompanion.insert(
        documentPk: docPk,
        title: _titleController.text.trim(),
        note: drift.Value(_noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim()),
        localFilePath: drift.Value(_localFilePath ?? _pickedFileName),
        externalUrl: drift.Value(finalUrl),
        subjectFk: _selectedSubjectFk!,
        docTypeFk: _selectedDocTypeFk!,
        dueDate: drift.Value(_dueDate),
        status: drift.Value(_status),
        isPinned: drift.Value(_isPinned),
        tags: drift.Value(tags),
        locationName: drift.Value(locationName),
        latitude: drift.Value(latitude),
        longitude: drift.Value(longitude),
        dateTimeCreated: now,
        dateTimeModified: now,
      );
      await db.documentsDao.insertDocument(newDoc);
    } else {
      // Update
      final updated = widget.document!.copyWith(
        title: _titleController.text.trim(),
        note: drift.Value(_noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim()),
        localFilePath:
            drift.Value(_localFilePath ?? widget.document!.localFilePath),
        externalUrl: drift.Value(finalUrl),
        subjectFk: _selectedSubjectFk!,
        docTypeFk: _selectedDocTypeFk!,
        dueDate: drift.Value(_dueDate),
        status: _status,
        isPinned: _isPinned,
        tags: drift.Value(tags),
        locationName: drift.Value(locationName),
        latitude: drift.Value(latitude),
        longitude: drift.Value(longitude),
        dateTimeModified: now,
      );
      await db.documentsDao.updateDocument(updated.toCompanion(true));
    }

    var supabaseSyncSucceeded = true;

    // Tự động đồng bộ tài liệu sang Supabase nếu người dùng đã đăng nhập Google
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser != null) {
        final subMatch =
            _subjects.where((s) => s.subjectPk == _selectedSubjectFk);
        final subName = subMatch.isNotEmpty ? subMatch.first.name : null;
        final subCode = subMatch.isNotEmpty ? subMatch.first.code : null;
        final typeMatch =
            _docTypes.where((t) => t.docTypePk == _selectedDocTypeFk);
        final docTypeName = typeMatch.isNotEmpty ? typeMatch.first.name : null;

        supabaseSyncSucceeded = await SupabaseService().saveDocument(
          documentId: docPk,
          ownerId: currentUser.uid,
          title: _titleController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          subjectCode: subCode,
          subjectName: subName,
          docType: docTypeName,
          status: _status,
          dueDate: _dueDate,
          isPinned: _isPinned,
          tags: tags,
          locationName: locationName,
          latitude: latitude,
          longitude: longitude,
          fileUrl: finalUrl,
          filePath: uploaded?.storagePath,
          fileName: uploaded?.fileName,
          fileSize: uploaded?.size,
        );
      }
    } catch (e) {
      debugPrint('Thông báo đồng bộ Supabase: $e');
      supabaseSyncSucceeded = false;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uploadError != null
                ? 'Đã lưu tài liệu nhưng tải tệp lên Supabase Storage thất bại: $uploadError'
                : !supabaseSyncSucceeded
                    ? 'Đã lưu trên thiết bị nhưng chưa đồng bộ Supabase. Vào Cài đặt > Kiểm tra kết nối Supabase.'
                    : uploaded != null
                        ? 'Đã lưu tài liệu và tải tệp lên Supabase Storage + Database!'
                        : AuthService().isSignedIn
                            ? 'Đã lưu tài liệu và đồng bộ lên Supabase!'
                            : 'Đã lưu tài liệu trên thiết bị!',
          ),
          duration: Duration(seconds: uploadError != null ? 8 : 4),
          backgroundColor: uploadError != null || !supabaseSyncSucceeded
              ? Colors.deepOrange
              : null,
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
                  label: const Text('Lưu',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _subjects.map((sub) {
                return DropdownMenuItem(
                  value: sub.subjectPk,
                  child: Text('${sub.code} - ${sub.name}',
                      overflow: TextOverflow.ellipsis),
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    ? const Text('Bấm để đổi tệp khác',
                        style: TextStyle(fontSize: 12))
                    : const Text('Hỗ trợ tải lên Supabase Storage',
                        style: TextStyle(fontSize: 12)),
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
            if (_pickedFileName != null && isUserSignedIn) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                dense: true,
                secondary:
                    const Icon(Icons.cloud_upload_rounded, color: Colors.blue),
                title: const Text('Tự động tải tệp lên Supabase Storage'),
                subtitle: const Text(
                    'Lưu trữ đám mây giúp mở tệp từ bất kỳ thiết bị nào'),
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
                subtitle: const Text('Nhắc nhở bài tập và lịch thi',
                    style: TextStyle(fontSize: 12)),
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
              subtitle:
                  const Text('Hiển thị ưu tiên khi mở danh sách tài liệu'),
              value: _isPinned,
              onChanged: (val) => setState(() => _isPinned = val),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Tag',
                hintText: 'Ví dụ: Giáo trình, Lý thuyết, Chương 1',
                helperText: 'Phân tách nhiều tag bằng dấu phẩy',
                prefixIcon: const Icon(Icons.sell_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationNameController,
              decoration: InputDecoration(
                labelText: 'Tên vị trí',
                hintText: 'Ví dụ: Kệ 3, Ngăn B, Thư viện',
                prefixIcon: const Icon(Icons.place_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
                      child: TextFormField(
                        controller: _latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: 'Vĩ độ',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final coordinate = double.tryParse(text);
                          if (coordinate == null ||
                              !coordinate.isFinite ||
                              coordinate < -90 ||
                              coordinate > 90) {
                            return 'Nhập giá trị từ -90 đến 90';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: 'Kinh độ',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final coordinate = double.tryParse(text);
                          if (coordinate == null ||
                              !coordinate.isFinite ||
                              coordinate < -180 ||
                              coordinate > 180) {
                            return 'Nhập giá trị từ -180 đến 180';
                          }
                          return null;
                        },
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
            TextFormField(
              controller: _noteController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Ghi Chú & Tóm Tắt Nội Dung',
                hintText:
                    'Ghi chú các ý chính của bài giảng, yêu cầu bài tập...',
                alignLabelWithHint: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _saveDocument,
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('Đang lưu và tải lên Cloud...'),
                      ],
                    )
                  : Text(
                      isEditing ? 'Cập Nhật Tài Liệu' : 'Lưu Tài Liệu Mới',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
