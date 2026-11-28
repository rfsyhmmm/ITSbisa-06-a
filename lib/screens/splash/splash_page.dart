import 'package:flutter/material.dart';

import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/widgets/primary_button.dart';
import 'package:itsbisa/widgets/wave_background.dart';

/// Halaman pembuka sesuai Figma: logo, tombol "Mulai donasi", gelombang bawah.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: WaveBackground(atBottom: true),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  Image.asset('assets/images/logo_itsbisa.png', width: 260),
                  const Spacer(flex: 4),
                  PrimaryButton(
                    label: 'Mulai donasi',
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.authGate,
                    ),
                  ),
                  const Spacer(flex: 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
