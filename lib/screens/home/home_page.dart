import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:itsbisa/data/dummy_campaigns.dart';
import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/widgets/campaign_card.dart';
import 'package:itsbisa/widgets/section_header.dart';

/// Kerangka Home sesuai Figma. Detail tampilan dirapikan oleh Lafrel.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onOpenDonasiTab});

  /// Dipanggil untuk pindah ke tab Donasi (dari "Lihat semua").
  final VoidCallback onOpenDonasiTab;

  void _openDetail(BuildContext context, Campaign campaign) {
    Navigator.pushNamed(
      context,
      AppRoutes.campaignDetail,
      arguments: campaign,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final name = email.split('@').first;
    final urgent = dummyCampaigns.where((c) => c.isUrgent).toList();

    return SafeArea(
      child: ListView(
        children: [
          // Header: logo, sapaan, notifikasi
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                Image.asset('assets/images/logo_itsbisa.png', height: 36),
                const Spacer(),
                Flexible(
                  child: Text(
                    'Halo, $name',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.navy),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  color: AppColors.navy,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.notifications),
                ),
              ],
            ),
          ),

          // Kolom pencarian (fungsi cari dikerjakan menyusul)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Mulai memberi bantuan...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          const SectionHeader(title: 'Kampanye Mendesak'),
          _HorizontalCampaigns(
            campaigns: urgent,
            onTap: (c) => _openDetail(context, c),
          ),

          SectionHeader(
            title: 'Bersama pasti bisa!',
            onSeeAll: onOpenDonasiTab,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickAction(
                  icon: Icons.volunteer_activism,
                  label: 'Donasi',
                  onTap: onOpenDonasiTab,
                ),
                _QuickAction(
                  icon: Icons.favorite,
                  label: 'Galang Dana',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.submitCampaign),
                ),
                _QuickAction(
                  icon: Icons.handshake,
                  label: 'Kampanye',
                  onTap: onOpenDonasiTab,
                ),
              ],
            ),
          ),

          SectionHeader(title: 'Kampanye Aktif', onSeeAll: onOpenDonasiTab),
          _HorizontalCampaigns(
            campaigns: dummyCampaigns,
            onTap: (c) => _openDetail(context, c),
            showDonate: true,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HorizontalCampaigns extends StatelessWidget {
  const _HorizontalCampaigns({
    required this.campaigns,
    required this.onTap,
    this.showDonate = false,
  });

  final List<Campaign> campaigns;
  final void Function(Campaign) onTap;
  final bool showDonate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: showDonate ? 310 : 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: campaigns.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = campaigns[i];
          return CampaignCard(
            campaign: c,
            width: 190,
            onTap: () => onTap(c),
            onDonate: showDonate ? () => onTap(c) : null,
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryLight,
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}
