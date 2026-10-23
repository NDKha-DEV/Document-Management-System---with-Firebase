import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'supabase_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;
  String? _lastSyncedUid;

  bool get isInitialized => _isInitialized;

  void initialize() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
        if (!kIsWeb) {
          _googleSignIn = GoogleSignIn(
            scopes: ['email', 'profile'],
          );
        }
        _isInitialized = true;
        // Mỗi khi có phiên đăng nhập (kể cả khi tải lại trang), đồng bộ hồ sơ sang Supabase
        _auth!.authStateChanges().listen((user) {
          if (user != null && user.uid != _lastSyncedUid) {
            _lastSyncedUid = user.uid;
            SupabaseService().syncUserProfile(user);
          } else if (user == null) {
            _lastSyncedUid = null;
          }
        });
      }
    } catch (e) {
      debugPrint('AuthService initialize warning: $e');
      _isInitialized = false;
    }
  }

  Stream<User?> get authStateChanges {
    if (_auth == null) return Stream.value(null);
    return _auth!.authStateChanges();
  }

  User? get currentUser {
    if (_auth == null) return null;
    return _auth!.currentUser;
  }

  bool get isSignedIn => currentUser != null;

  Future<UserCredential?> signInWithGoogle() async {
    if (_auth == null) {
      initialize();
      if (_auth == null) {
        throw Exception('Firebase chưa được khởi tạo. Vui lòng kiểm tra cấu hình Firebase.');
      }
    }

    try {
      UserCredential? credential;
      if (kIsWeb) {
        // Trên nền tảng Web: Sử dụng signInWithPopup chính chủ của Firebase
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        // Luôn cho chọn tài khoản => dễ chuyển giữa nhiều tài khoản khi kiểm thử
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        credential = await _auth!.signInWithPopup(googleProvider);
      } else {
        // Trên Android / iOS: Sử dụng GoogleSignIn package
        _googleSignIn ??= GoogleSignIn(scopes: ['email', 'profile']);
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          // Người dùng hủy hộp thoại đăng nhập
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential oauthCred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        credential = await _auth!.signInWithCredential(oauthCred);
      }

      // Tự động đồng bộ hồ sơ người dùng sang bảng profiles trên Supabase
      if (credential.user != null) {
        _lastSyncedUid = credential.user!.uid;
        await SupabaseService().syncUserProfile(credential.user!);
      }

      return credential;
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      if (_auth != null) {
        await _auth!.signOut();
      }
    } catch (e) {
      debugPrint('Lỗi khi đăng xuất: $e');
      rethrow;
    }
  }
}
