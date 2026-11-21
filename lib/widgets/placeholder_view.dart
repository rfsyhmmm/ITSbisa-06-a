import 'package:flutter/material.dart';

import 'package:itsbisa/theme/app_colors.dart';

/// Isi sementara untuk halaman yang belum dikerjakan.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({
    super.key,
    required this.icon,
    required this.title,
    this.message = 'Halaman ini sedang dikerjakan.',
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
