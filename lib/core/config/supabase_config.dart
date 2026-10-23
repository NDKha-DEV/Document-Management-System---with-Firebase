import 'package:shared_preferences/shared_preferences.dart';

class SupabaseConfig {
  /// Project URL & Publishable key (an toàn để nhúng vào client — mọi truy cập
  /// dữ liệu đều do Row Level Security kiểm soát). Có thể ghi đè bằng
  /// --dart-define hoặc trong màn hình Cài đặt.
  static const String defaultUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jtffhgrmcanfibeijdqn.supabase.co',
  );

  static const String defaultAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_iohX_EtJ0OSmywVflkuRXw_fafOADEd',
  );

  static String _activeUrl = defaultUrl;
  static String _activeAnonKey = defaultAnonKey;

  static String get supabaseUrl => _activeUrl;
  static String get supabaseAnonKey => _activeAnonKey;

  static Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('supabase_url');
      final savedKey = prefs.getString('supabase_anon_key');
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _activeUrl = savedUrl.trim();
      }
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        _activeAnonKey = savedKey.trim();
      }
    } catch (_) {}
  }

  static Future<void> updateConfig(String url, String key) async {
    _activeUrl = url.trim();
    _activeAnonKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('supabase_url', _activeUrl);
      await prefs.setString('supabase_anon_key', _activeAnonKey);
    } catch (_) {}
  }

  static bool get isConfigured =>
      _activeUrl.startsWith('https://') && _activeAnonKey.isNotEmpty;
}
