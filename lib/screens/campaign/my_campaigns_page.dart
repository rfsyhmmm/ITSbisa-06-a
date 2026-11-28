import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';

/// Figma S03.08 "Kampanye Saya" (F08): semua kampanye yang diajukan pengguna.
class MyCampaignsPage extends StatefulWidget {
  const MyCampaignsPage({super.key});

  @override
  State<MyCampaignsPage> createState() => _MyCampaignsPageState();
}

class _MyCampaignsPageState extends State<MyCampaignsPage> {
  late Future<List<Campaign>> _future = CampaignService.fetchMyCampaigns();

  Future<void> _refresh() async {
    setState(() => _future = CampaignService.fetchMyCampaigns());
    await _future;
  }

  Future<void> _push(String route, [Object? args]) async {
    await Navigator.pushNamed(context, route, arguments: args);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ItsPage(
      title: 'Kampanye Saya',
      onRefresh: _refresh,
      children: [
        const ItsHeadline(
          'Pantau bantuan yang Anda galang',
          subtitle: 'Pengajuan dan perkembangan kampanye dalam satu tempat.',
        ),
        CardButton(
          label: 'Ajukan Kampanye Baru',
          onPressed: () => _push(AppRoutes.createCampaign),
        ),
        FutureBuilder<List<Campaign>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError)
              return ErrorRetry(error: snap.error!, onRetry: _refresh);
            final items = snap.data!;
            if (items.isEmpty) {
              return const InfoCard(
                title: 'Belum ada kampanye',
                titleSize: 16,
                children: [
                  CardText(
                    'Kampanye yang Anda ajukan akan tampil di sini.',
                    muted: true,
                  ),
                ],
              );
            }
            return Column(
              children: [
                for (final c in items) ...[
                  InfoCard(
                    overline: c.statusLabel,
                    overlineColor: c.status == CampaignStatus.rejected
                        ? AppColors.danger
                        : AppColors.primary,
                    title: c.title,
                    children: [
                      CardText(joinLabel(['Bantuan Dana', c.category])),
                      ..._summary(c),
                      CardButton(
                        label: c.status == CampaignStatus.pendingReview
                            ? 'Lihat Pengajuan'
                            : 'Kelola Kampanye',
                        onPressed: () => _push(AppRoutes.manageCampaign, c),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _summary(Campaign c) => switch (c.status) {
    CampaignStatus.pendingReview => const [
      CardText('Pengajuan Anda sedang diperiksa admin.', muted: true),
    ],
    CampaignStatus.rejected => const [
      CardText(
        'Pengajuan ditolak. Lihat alasan di halaman kelola.',
        muted: true,
      ),
    ],
    _ => [
      CardText(
        '${formatRupiah(c.collectedAmount)} dari target ${formatRupiah(c.targetAmount)}',
      ),
      if (c.isActive) CardText('Sisa ${c.daysLeft} hari'),
    ],
  };
}
