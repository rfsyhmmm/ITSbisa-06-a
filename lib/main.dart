import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qiapjprevekcaedrvqfk.supabase.co',
    publishableKey: 'sb_publishable_PCcsY19B8SWNajYdclRvUg_h1hKMoi9',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return MaterialApp(
      title: 'ITSBisa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF174A7E)),
      ),
      home: StreamBuilder<AuthState>(
        stream: auth.onAuthStateChange,
        builder: (context, snapshot) {
          final user = auth.currentSession?.user;

          if (user == null) return const AuthPage();

          return Scaffold(
            appBar: AppBar(title: const Text('ITSBisa')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Berhasil masuk'),
                  Text(user.email ?? ''),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await auth.signOut();
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal keluar. Coba lagi.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Keluar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _itsEmail = RegExp(
    r'^[^@\s]+@(its\.ac\.id|student\.its\.ac\.id)$',
    caseSensitive: false,
  );

  bool _isRegistering = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    final auth = Supabase.instance.client.auth;
    final email = _email.text.trim().toLowerCase();
    final password = _password.text;

    setState(() => _isLoading = true);

    try {
      if (_isRegistering) {
        final result = await auth.signUp(email: email, password: password);

        if (!mounted || result.session != null) return;
        _password.clear();
        setState(() => _isRegistering = false);
        _showMessage('Cek email ITS untuk konfirmasi, lalu masuk kembali.');
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Permintaan gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final action = _isRegistering ? 'Daftar' : 'Masuk';

    return Scaffold(
      appBar: AppBar(title: const Text('ITSBisa')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$action ke ITSBisa',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Email ITS',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_itsEmail.hasMatch((value ?? '').trim())) {
                        return 'Gunakan email @its.ac.id atau @student.its.ac.id.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Kata sandi',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Isi kata sandi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: Text(_isLoading ? 'Memproses…' : action),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() => _isRegistering = !_isRegistering);
                          },
                    child: Text(
                      _isRegistering
                          ? 'Sudah punya akun? Masuk'
                          : 'Belum punya akun? Daftar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
