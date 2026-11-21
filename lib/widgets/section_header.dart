import 'package:flutter/material.dart';

import 'package:itsbisa/theme/app_colors.dart';

/// Judul bagian, contoh: "Kampanye Aktif" + tautan "Lihat semua".
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'Lihat semua',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
