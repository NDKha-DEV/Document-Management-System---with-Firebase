import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../database/study_database.dart';
import '../../database/default_data.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/supabase_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isSyncing = false;

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'study_materials.sqlite'));

      if (!await dbFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chưa có tệp cơ sở dữ liệu để xuất.')),
          );
        }
        return;
      }

      await Share.shareXFiles(
        [XFile(dbFile.path)],
        subject: 'Sao lưu CSDL Tài Liệu Học Tập (SQLite)',
        text: 'Tệp sao lưu CSDL ứng dụng Study Materials.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi sao lưu CSDL: $e')),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final cred = await AuthService().signInWithGoogle();
      if (cred != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Đăng nhập thành công: ${cred.user?.displayName ?? cred.user?.email}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Lỗi đăng nhập Google: $e'),
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng xuất khỏi tài khoản Google.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
        );
      }
    }
  }

  Future<void> _handleCloudSync(StudyDatabase db) async {
    setState(() => _isSyncing = true);
    try {
      final result = await CloudSyncService().syncAll(db);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: result.success ? Colors.green : Colors.orange,
            content: Text(result.message),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<StudyDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài Đặt & Đồng Bộ Cloud',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mục 1: Đăng nhập Google & Đồng bộ Đám mây (Firebase)
          _buildCloudAuthCard(db),
          const SizedBox(height: 14),

          // Mục 1.1: Trạng thái & Cấu hình Supabase Cloud (Chia sẻ & RLS)
          _buildSupabaseConfigCard(),
          const SizedBox(height: 20),

          // Mục 2: Thống kê tổng quan học tập
          StreamBuilder<List<SubjectWithStats>>(
            stream: db.subjectsDao.watchSubjectsWithStats(),
            builder: (context, snapshot) {
              final subjects = snapshot.data ?? [];
              final totalSubs = subjects.length;
              final totalDocs =
                  subjects.fold<int>(0, (sum, item) => sum + item.totalDocuments);
              final completedDocs = subjects.fold<int>(
                  0, (sum, item) => sum + item.completedDocuments);
              final completionRate = totalDocs == 0
                  ? 0
                  : ((completedDocs / totalDocs) * 100).toInt();

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng Quan Học Tập',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Môn Học', '$totalSubs', Colors.blue),
                          _buildStatItem('Tài Liệu', '$totalDocs', Colors.amber),
                          _buildStatItem(
                              'Đã Xong', '$completedDocs ($completionRate%)', Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Mục 3: Sao lưu & Phục hồi CSDL Cục bộ (Local-First)
          const Text(
            'Sao Lưu & Quản Lý Dữ Liệu (Local-First)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_rounded, color: Colors.blue),
                  title: const Text('Xuất Tệp Sao Lưu SQLite (.sqlite)'),
                  subtitle: const Text(
                      'Lưu trữ hoặc gửi file CSDL để khôi phục sang máy khác'),
                  trailing: const Icon(Icons.share_outlined),
                  onTap: () => _exportDatabase(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.restore_page_rounded, color: Colors.orange),
                  title: const Text('Nạp Dữ Liệu Mẫu Khởi Đầu'),
                  subtitle: const Text(
                      'Khởi tạo lại các môn học và tài liệu mẫu nếu CSDL trống'),
                  onTap: () async {
                    await populateDefaultStudyData(db);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Đã kiểm tra và nạp dữ liệu mẫu!')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Mục 4: Thông tin kiến trúc kỹ thuật
          const Text(
            'Kiến Trúc Kỹ Thuật (Áp Dụng Từ Cashew & Cloud)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Study Materials Management App',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ứng dụng được thiết kế và triển khai áp dụng chuẩn mực các nguyên lý kiến trúc của ứng dụng Cashew kết hợp hạ tầng đám mây Firebase:',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  _buildArchitectureBullet(
                    'Local-First & Privacy:',
                    'Dữ liệu lưu 100% trong SQLite cục bộ, chạy offline trơn tru, không phụ thuộc server.',
                  ),
                  _buildArchitectureBullet(
                    'MultiExecutor (Isolate):',
                    'Đọc ở main thread, ghi đĩa nặng ở Background Isolate giúp UI đạt 120 FPS không giật lag.',
                  ),
                  _buildArchitectureBullet(
                    'Cloud Authentication:',
                    'Xác thực bằng Google Sign-In qua Firebase Auth an toàn với OAuth 2.0.',
                  ),
                  _buildArchitectureBullet(
                    'Cloud File Storage:',
                    'Lưu trữ file tài liệu đính kèm trên Firebase Storage bảo mật với Security Rules.',
                  ),
                  _buildArchitectureBullet(
                    'Reactive Pipeline:',
                    'Drift Stream (.watch()) kết hợp Provider tự động làm mới giao diện khi CSDL thay đổi.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudAuthCard(StudyDatabase db) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          // Chưa đăng nhập Google
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.blue.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: Colors.blue, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đồng Bộ Đám Mây (Firebase)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Đăng nhập Google để sao lưu & lưu tệp',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Đăng nhập tài khoản Google để kích hoạt tính năng sao lưu hai chiều và lưu trữ tệp đính kèm trên Google Cloud Storage.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onPressed: _handleGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 28),
                      label: const Text(
                        'Đăng nhập bằng tài khoản Google',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Đã đăng nhập Google
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.green.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                      backgroundColor: Colors.blue.shade100,
                      child: user.photoURL == null
                          ? Text(
                              user.displayName?.isNotEmpty == true
                                  ? user.displayName![0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user.displayName ?? 'Sinh viên',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                            ],
                          ),
                          Text(
                            user.email ?? '',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSyncing ? null : () => _handleCloudSync(db),
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded),
                        label: Text(_isSyncing ? 'Đang đồng bộ...' : 'Đồng Bộ Ngay'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.outlined(
                      tooltip: 'Đăng xuất',
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _handleSignOut,
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupabaseConfigCard() {
    final isConfigured = SupabaseConfig.isConfigured;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConfigured ? Colors.deepPurple.shade200 : Colors.amber.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.hub_rounded, color: Colors.deepPurple, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Supabase Cloud (RLS & Chia Sẻ)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isConfigured ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isConfigured ? 'Đã kết nối' : 'Chờ cấu hình',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isConfigured ? Colors.green.shade700 : Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isConfigured
                            ? 'URL: ${SupabaseConfig.supabaseUrl}'
                            : 'Nhập Project URL & Anon Key để kích hoạt chia sẻ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                label: Text(isConfigured ? 'Xem / Cập nhật cấu hình Supabase' : 'Cấu hình Supabase Cloud ngay'),
                onPressed: _showSupabaseConfigDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupabaseConfigDialog() {
    final urlController = TextEditingController(
      text: SupabaseConfig.supabaseUrl == 'https://xyzcompany.supabase.co' ? '' : SupabaseConfig.supabaseUrl,
    );
    final keyController = TextEditingController(
      text: SupabaseConfig.supabaseAnonKey.startsWith('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...') ? '' : SupabaseConfig.supabaseAnonKey,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Cấu Hình Supabase'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lấy từ Supabase Console > Project Settings > API:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Project URL',
                  hintText: 'https://xxx.supabase.co',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'anon public key',
                  hintText: 'eyJhbGciOi...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final url = urlController.text.trim();
              final key = keyController.text.trim();
              if (url.isEmpty || key.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập đủ URL và anon key')),
                );
                return;
              }
              Navigator.pop(ctx);
              final ok = await SupabaseService().updateConfiguration(url, key);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: ok ? Colors.green : Colors.red,
                    content: Text(ok
                        ? 'Đã lưu cấu hình Supabase thành công!'
                        : 'Khởi tạo Supabase thất bại, vui lòng kiểm tra URL/Key.'),
                  ),
                );
              }
            },
            child: const Text('Lưu & Kết Nối'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildArchitectureBullet(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
