import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Avatar tài khoản Google trên AppBar: đăng nhập / chuyển tài khoản / đăng xuất.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  Future<void> _signIn(BuildContext context) async {
    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng nhập Google: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      initialData: AuthService().currentUser,
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          return IconButton(
            tooltip: 'Đăng nhập Google',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _signIn(context),
          );
        }
        final name = user.displayName ?? user.email ?? 'U';
        return PopupMenuButton<String>(
          tooltip: user.email ?? 'Tài khoản',
          offset: const Offset(0, 48),
          onSelected: (v) async {
            if (v == 'switch') {
              // Popup Google luôn hỏi chọn tài khoản; đăng nhập mới thay phiên hiện tại
              await _signIn(context);
            } else if (v == 'logout') {
              await AuthService().signOut();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user.email ?? ''),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'switch',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.switch_account_rounded),
                title: Text('Đổi tài khoản Google'),
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: Text('Đăng xuất'),
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: CircleAvatar(
              radius: 16,
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null
                  ? Text(name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 13))
                  : null,
            ),
          ),
        );
      },
    );
  }
}
