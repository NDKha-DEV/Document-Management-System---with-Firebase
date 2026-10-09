import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'database/study_database.dart';
import 'database/default_data.dart';
import 'core/services/auth_service.dart';
import 'navigation/main_navigation_framework.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase với cấu hình đa nền tảng
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AuthService().initialize();
  } catch (e) {
    debugPrint('Thông báo khởi tạo Firebase: $e');
  }

  // Khởi tạo CSDL SQLite với MultiExecutor đa luồng
  final database = await constructDb('study_materials');

  // Nạp dữ liệu mẫu khởi đầu nếu cơ sở dữ liệu trống
  await populateDefaultStudyData(database);

  runApp(StudyApp(database: database));
}

class StudyApp extends StatelessWidget {
  final StudyDatabase database;

  const StudyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return Provider<StudyDatabase>.value(
      value: database,
      child: MaterialApp(
        title: 'Quản Lý Tài Liệu Học Tập',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF3B82F6),
          brightness: Brightness.light,
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
        ),
        themeMode: ThemeMode.system,
        home: const MainNavigationFramework(),
      ),
    );
  }
}
