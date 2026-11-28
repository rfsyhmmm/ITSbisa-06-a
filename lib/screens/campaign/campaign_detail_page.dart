import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/campaign_cover.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/widgets/primary_button.dart';
import 'package:itsbisa/widgets/status_chip.dart';

/// Detail kampanye (F04): cerita, perolehan, kabar terbaru, laporan, donatur.
/// Untuk pemilik kampanye, tampil kartu menuju Kelola Kampanye (Figma S03.09).
class CampaignDetailPage extends StatefulWidget {
  const CampaignDetailPage({super.key, required this.campaign});

  /// Data awal dari daftar. Data terbaru dimuat ulang dari Supabase.
  final Campaign campaign;

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _DetailData {
  const _DetailData({
    required this.campaign,
    required this.donors,
    required this.updates,
    this.report,
  });

  final Campaign campaign;
  final List<DonorEntry> donors;
  final List<CampaignUpdate> updates;
  final FundReport? report;
}

class _CampaignDetailPageState extends State<CampaignDetailPage> {
  late Future<_DetailData> _future = _load();

  String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  Future<_DetailData> _load() async {
    final id = widget.campaign.id;
    final campaign = await CampaignService.fetchCampaign(id) ?? widget.campaign;
    final results = await Future.wait<Object?>([
      CampaignService.fetchDonors(id),
      CampaignService.fetchUpdates(id),
      CampaignService.fetchReport(id),
    ]);
    return _DetailData(
      campaign: campaign,
      donors: results[0] as List<DonorEntry>,
      updates: results[1] as List<CampaignUpdate>,
      report: results[2] as FundReport?,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _go(String route, Campaign c) async {
    await Navigator.pushNamed(context, route, arguments: c);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DetailData>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        final c = data?.campaign ?? widget.campaign;
        return Scaffold(
          appBar: AppBar(title: const Text('Detail Kampanye')),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                CampaignCover(url: c.coverImageUrl, height: 200),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _Header(campaign: c),
                ),
                if (snap.hasError)
                  SizedBox(
                    height: 200,
                    child: ErrorRetry(error: snap.error!, onRetry: _refresh),
                  )
                else if (data == null)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (c.ownerId == _uid)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: InfoCard(
                        overline: joinLabel(['Kampanye Anda', c.statusLabel]),
                        title: 'Kelola kampanye',
                        titleSize: 16,
                        children: [
                          const CardText(
                            'Pantau status, ajukan pencairan, dan unggah laporan.',
                          ),
                          CardButton(
                            label: 'Kelola Kampanye',
                            onPressed: () => _go(AppRoutes.manageCampaign, c),
                          ),
                        ],
                      ),
                    ),
                  _Section(
                    title: 'Cerita',
                    child: Text(c.story, style: const TextStyle(height: 1.5)),
                  ),
                  if (data.report != null) _ReportSection(report: data.report!),
                  if (data.updates.isNotEmpty)
                    _UpdatesSection(updates: data.updates),
                  _DonorsSection(donors: data.donors, total: c.donorCount),
                ],
              ],
            ),
          ),
          bottomNavigationBar: c.acceptsDonation
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PrimaryButton(
                      label: 'Donasi',
                      color: AppColors.navy,
                      onPressed: () => _go(AppRoutes.donationForm, c),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusChip(label: c.category),
            const SizedBox(width: 8),
            if (!c.isActive)
              StatusChip(label: c.statusLabel, tone: campaignTone(c.status)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          c.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                c.organizer,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            if (c.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, size: 16, color: AppColors.verified),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: formatRupiah(c.collectedAmount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              TextSpan(
                text: ' terkumpul dari ${formatRupiah(c.targetAmount)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: c.progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${c.donorCount} donatur'),
            Text(
              c.isActive
                  ? 'Sisa ${c.daysLeft} hari'
                  : 'Berakhir ${formatDate(c.deadline)}',
            ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.report});

  final FundReport report;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Laporan Penggunaan Dana',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dana digunakan: ${formatRupiah(report.totalUsed)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(report.description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: report.evidenceUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    child: InteractiveViewer(
                      child: Image.network(report.evidenceUrls[i]),
                    ),
                  ),
                ),
                child: SizedBox(
                  width: 90,
                  child: CampaignCover(
                    url: report.evidenceUrls[i],
                    height: 90,
                    radius: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatesSection extends StatelessWidget {
  const _UpdatesSection({required this.updates});

  final List<CampaignUpdate> updates;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Kabar Terbaru',
      child: Column(
        children: [
          for (final u in updates)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDate(u.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    u.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(u.content),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DonorsSection extends StatelessWidget {
  const _DonorsSection({required this.donors, required this.total});

  final List<DonorEntry> donors;
  final int total;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Donatur ($total)',
      child: donors.isEmpty
          ? const Text(
              'Jadilah donatur pertama!',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : Column(
              children: [
                for (final d in donors)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(
                        Icons.favorite,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      d.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Berdonasi ${formatRupiah(d.amount)} · ${timeAgo(d.paidAt)}',
                        ),
                        if ((d.message ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '"${d.message}"',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
