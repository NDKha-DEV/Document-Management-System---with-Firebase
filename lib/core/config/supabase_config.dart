import 'package:shared_preferences/shared_preferences.dart';

class SupabaseConfig {
  /// Giá trị mặc định khi chưa cấu hình qua SharedPreferences
  static const String defaultUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );

  static const String defaultAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
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
      _activeUrl.isNotEmpty &&
      _activeAnonKey.isNotEmpty &&
      _activeUrl != 'https://xyzcompany.supabase.co' &&
      _activeAnonKey != 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
