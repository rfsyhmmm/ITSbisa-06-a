import 'package:flutter/material.dart';

import 'package:itsbisa/theme/app_colors.dart';

/// Label status kecil (Aktif, Menunggu Verifikasi, Berhasil, Gagal, ...).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.info,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      StatusTone.success => (AppColors.successLight, AppColors.success),
      StatusTone.warning => (AppColors.warningLight, AppColors.warning),
      StatusTone.danger => (AppColors.dangerLight, AppColors.danger),
      StatusTone.neutral => (AppColors.border, AppColors.textSecondary),
      StatusTone.info => (AppColors.primaryLight, AppColors.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

enum StatusTone { info, success, warning, danger, neutral }

/// Warna status kampanye.
StatusTone campaignTone(String status) => switch (status) {
  'active' => StatusTone.info,
  'pending_review' || 'draft' => StatusTone.warning,
  'rejected' => StatusTone.danger,
  'completed' || 'disbursed' || 'reported' => StatusTone.success,
  _ => StatusTone.neutral,
};

/// Warna status donasi.
StatusTone donationTone(String status, {bool canResume = false}) =>
    switch (status) {
      'paid' => StatusTone.success,
      'pending' => canResume ? StatusTone.warning : StatusTone.neutral,
      'failed' || 'expired' => StatusTone.danger,
      _ => StatusTone.neutral,
    };
