import 'package:flutter/material.dart';

import 'package:itsbisa/models/donation.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/screens/campaign/payment_status_page.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Figma 101:5873 "Terima kasih atas kebaikanmu" (tampil setelah donasi berstatus paid).
class DonationSuccessPage extends StatelessWidget {
  const DonationSuccessPage({super.key, required this.args});

  final PaymentArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.favorite, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Terima kasih atas kebaikanmu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dukungan dan doa baikmu sangat berarti bagi kami, semoga kamu selalu sehat dan beruntung',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.donationDetail,
                    arguments: DonationRef(args.donationId),
                  ),
                  child: const Text(
                    'Lihat donasimu',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Kembali ke beranda',
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
