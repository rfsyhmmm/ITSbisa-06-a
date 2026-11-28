import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:itsbisa/screens/auth/auth_page.dart';
import 'package:itsbisa/screens/main_shell.dart';

/// true hanya kalau aplikasi dijalankan dengan --dart-define=SKIP_LOGIN=true.
/// Dipakai untuk menguji tampilan tanpa akun. Default-nya false.
const _skipLogin = bool.fromEnvironment('SKIP_LOGIN');

/// Penentu halaman awal: belum login -> AuthPage, sudah login -> MainShell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (_skipLogin) return const MainShell();

    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = auth.currentSession?.user;
        if (user == null) return const AuthPage();
        return const MainShell();
      },
    );
  }
}
