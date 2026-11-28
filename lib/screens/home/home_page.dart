import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/campaign_card.dart';
import 'package:itsbisa/widgets/section_header.dart';

/// Home sesuai Figma. Data kampanye dari Supabase (RPC get_campaigns).
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onOpenDonasiTab, this.onSearch});

  /// Dipanggil untuk pindah ke tab Donasi (dari "Lihat semua").
  final VoidCallback onOpenDonasiTab;

  /// Dipanggil saat pengguna mencari dari kolom pencarian Home.
  final void Function(String query)? onSearch;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<(List<Campaign>, List<Campaign>)> _future = _load();

  Future<(List<Campaign>, List<Campaign>)> _load() async {
    final results = await Future.wait([
      CampaignService.fetchCampaigns(urgentOnly: true, limit: 10),
      CampaignService.fetchCampaigns(limit: 10),
    ]);
    return (results[0], results[1]);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _openDetail(Campaign campaign) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.campaignDetail,
      arguments: campaign,
    );
    if (mounted) _refresh(); // perolehan bisa berubah setelah berdonasi
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final name = email.split('@').first;
    final onOpenDonasiTab = widget.onOpenDonasiTab;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<(List<Campaign>, List<Campaign>)>(
          future: _future,
          builder: (context, snap) {
            final urgent = snap.data?.$1 ?? const <Campaign>[];
            final active = snap.data?.$2 ?? const <Campaign>[];
            final loading = snap.connectionState != ConnectionState.done;
            return ListView(
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
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.notifications,
                        ),
                      ),
                    ],
                  ),
                ),

                // Kolom pencarian: hasil ditampilkan di tab Donasi.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: TextField(
                    textInputAction: TextInputAction.search,
                    onSubmitted: (q) => widget.onSearch?.call(q),
                    decoration: const InputDecoration(
                      hintText: 'Mulai memberi bantuan...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),

                if (snap.hasError)
                  SizedBox(
                    height: 240,
                    child: ErrorRetry(error: snap.error!, onRetry: _refresh),
                  ),

                const SectionHeader(title: 'Kampanye Mendesak'),
                _HorizontalCampaigns(
                  campaigns: urgent,
                  loading: loading,
                  emptyText: 'Belum ada kampanye mendesak.',
                  onTap: _openDetail,
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
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.createCampaign,
                          );
                          if (mounted) _refresh();
                        },
                      ),
                      _QuickAction(
                        icon: Icons.handshake,
                        label: 'Kampanye',
                        onTap: onOpenDonasiTab,
                      ),
                    ],
                  ),
                ),

                SectionHeader(
                  title: 'Kampanye Aktif',
                  onSeeAll: onOpenDonasiTab,
                ),
                _HorizontalCampaigns(
                  campaigns: active,
                  loading: loading,
                  emptyText: 'Belum ada kampanye aktif.',
                  onTap: _openDetail,
                  showDonate: true,
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HorizontalCampaigns extends StatelessWidget {
  const _HorizontalCampaigns({
    required this.campaigns,
    required this.onTap,
    this.showDonate = false,
    this.loading = false,
    this.emptyText = '',
  });

  final List<Campaign> campaigns;
  final void Function(Campaign) onTap;
  final bool showDonate;
  final bool loading;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final height = showDonate ? 310.0 : 260.0;
    if (loading && campaigns.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (campaigns.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            emptyText,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
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
