import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Kerangka detail kampanye (F04). Isi lengkap (berita, donatur, ucapan)
/// ditambahkan sesuai Figma.
class CampaignDetailPage extends StatelessWidget {
  const CampaignDetailPage({super.key, required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(campaign.title, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.volunteer_activism,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            campaign.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            campaign.category,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: formatRupiah(campaign.collectedAmount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' dari ${formatRupiah(campaign.targetAmount)}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: campaign.progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Sisa ${campaign.daysLeft} hari'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: 'Donasi',
            color: AppColors.navy,
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.donationForm,
              arguments: campaign,
            ),
          ),
        ),
      ),
    );
  }
}
