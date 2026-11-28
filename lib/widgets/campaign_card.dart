import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/campaign_cover.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Kartu kampanye (dipakai di Home dan halaman Donasi).
/// width: isi angka untuk daftar menyamping, kosongkan untuk lebar penuh.
class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.campaign,
    this.onTap,
    this.onDonate,
    this.width,
  });

  final Campaign campaign;
  final VoidCallback? onTap;
  final VoidCallback? onDonate;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        color: AppColors.surface,
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Foto sampul dari bucket campaign-covers.
              CampaignCover(url: campaign.coverImageUrl),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            campaign.organizer,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (campaign.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: AppColors.verified,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: campaign.progress,
                        minHeight: 5,
                        backgroundColor: AppColors.border,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Donasi', style: TextStyle(fontSize: 12)),
                        Text(
                          'Sisa ${campaign.daysLeft} hari',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      formatRupiah(campaign.collectedAmount),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (onDonate != null) ...[
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: 'Donate',
                        height: 38,
                        onPressed: onDonate,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
