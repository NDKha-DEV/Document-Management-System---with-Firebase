class SupabaseConfig {
  /// Điền thông tin Project URL và anon key từ Supabase Console:
  /// Project Settings -> API
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co', // Thay bằng URL dự án của bạn
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...', // Thay bằng anon key của bạn
  );

  static bool get isConfigured =>
      supabaseUrl != 'https://xyzcompany.supabase.co' &&
      supabaseAnonKey != 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}
