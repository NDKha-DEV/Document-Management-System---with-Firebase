import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

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
      if (kIsWeb) {
        // Trên nền tảng Web: Sử dụng signInWithPopup chính chủ của Firebase
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await _auth!.signInWithPopup(googleProvider);
      } else {
        // Trên Android / iOS: Sử dụng GoogleSignIn package
        _googleSignIn ??= GoogleSignIn(scopes: ['email', 'profile']);
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) {
          // Người dùng hủy hộp thoại đăng nhập
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth!.signInWithCredential(credential);
      }
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
