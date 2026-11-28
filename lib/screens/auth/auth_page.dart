import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/widgets/app_text_field.dart';
import 'package:itsbisa/widgets/primary_button.dart';
import 'package:itsbisa/widgets/wave_background.dart';

/// Halaman Login dan Register (satu halaman, bisa berganti mode).
/// Logika Supabase (_submit, validasi email ITS) dari Rafsyah, tidak diubah.
/// Tampilan disesuaikan dengan Figma.
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

  void _toggleMode() {
    _formKey.currentState?.reset();
    setState(() => _isRegistering = !_isRegistering);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: WaveBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isRegistering ? 'Selamat Datang!' : 'LOGIN',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Email ITS',
              hint: 'Your email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              validator: (value) {
                if (!_itsEmail.hasMatch((value ?? '').trim())) {
                  return 'Gunakan email @its.ac.id atau @student.its.ac.id.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              hint: 'Your password',
              controller: _password,
              isPassword: true,
              enabled: !_isLoading,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Isi kata sandi.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isRegistering ? 'Create Account' : 'Login Account',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isRegistering
                      ? 'Already have an account?'
                      : "Don't have an account?",
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _toggleMode,
                  child: Text(
                    _isRegistering ? 'Login' : 'Register',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
