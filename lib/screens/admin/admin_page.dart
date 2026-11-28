import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/services/admin_service.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';

/// Figma S04.01 "Admin Dashboard" (bagian alur kampanye): pintu ke verifikasi dan pencairan.
/// Hanya tampil di Profil jika profiles.role = 'admin'.
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<(int, int)> _future = AdminService.fetchCounts();

  Future<void> _refresh() async {
    setState(() => _future = AdminService.fetchCounts());
    await _future;
  }

  Future<void> _open(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(int, int)>(
      future: _future,
      builder: (context, snap) {
        final counts = snap.data;
        return ItsPage(
          title: 'Dashboard Admin',
          onRefresh: _refresh,
          children: [
            const ItsHeadline(
              'Panel admin ITSbisa',
              subtitle: 'Verifikasi kampanye dan proses pencairan dana.',
            ),
            if (snap.hasError)
              ErrorRetry(error: snap.error!, onRetry: _refresh),
            InfoCard(
              overline: counts == null
                  ? 'Memuat…'
                  : '${counts.$1} menunggu verifikasi',
              title: 'Verifikasi Kampanye',
              children: [
                const CardText(
                  'Periksa data dan dokumen privat sebelum kampanye aktif.',
                ),
                CardButton(
                  label: 'Lihat Pengajuan',
                  onPressed: () => _open(AppRoutes.adminCampaignQueue),
                ),
              ],
            ),
            InfoCard(
              overline: counts == null
                  ? 'Memuat…'
                  : '${counts.$2} pengajuan pencairan',
              title: 'Pencairan Dana',
              children: [
                const CardText(
                  'Periksa rekening lalu catat transfer simulasi.',
                ),
                CardButton(
                  label: 'Lihat Pencairan',
                  onPressed: () => _open(AppRoutes.adminDisbursementQueue),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Figma S04.02 "Verifikasi Kampanye": daftar pengajuan masuk.
class AdminCampaignQueuePage extends StatefulWidget {
  const AdminCampaignQueuePage({super.key});

  @override
  State<AdminCampaignQueuePage> createState() => _AdminCampaignQueuePageState();
}

class _AdminCampaignQueuePageState extends State<AdminCampaignQueuePage> {
  late Future<List<Campaign>> _future = AdminService.fetchPendingCampaigns();

  Future<void> _refresh() async {
    setState(() => _future = AdminService.fetchPendingCampaigns());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return ItsPage(
      title: 'Verifikasi Kampanye',
      onRefresh: _refresh,
      children: [
        const ItsHeadline('Pengajuan masuk'),
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
                title: 'Tidak ada pengajuan',
                titleSize: 16,
                children: [
                  CardText('Semua kampanye sudah diperiksa.', muted: true),
                ],
              );
            }
            return Column(
              children: [
                for (final c in items) ...[
                  InfoCard(
                    overline: 'Menunggu verifikasi',
                    title: c.title,
                    children: [
                      CardText(
                        joinLabel(['Bantuan Dana', c.category, c.organizer]),
                      ),
                      CardText('Target ${formatRupiah(c.targetAmount)}'),
                      CardButton(
                        label: 'Tinjau Pengajuan',
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.adminReview,
                            arguments: c,
                          );
                          if (mounted) _refresh();
                        },
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
}

/// Figma S08.03 "Admin Disbursement Queue": pengajuan pencairan yang menunggu.
class AdminDisbursementQueuePage extends StatefulWidget {
  const AdminDisbursementQueuePage({super.key});

  @override
  State<AdminDisbursementQueuePage> createState() =>
      _AdminDisbursementQueuePageState();
}

class _AdminDisbursementQueuePageState
    extends State<AdminDisbursementQueuePage> {
  late Future<List<Disbursement>> _future =
      AdminService.fetchRequestedDisbursements();

  Future<void> _refresh() async {
    setState(() => _future = AdminService.fetchRequestedDisbursements());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return ItsPage(
      title: 'Pencairan Dana',
      onRefresh: _refresh,
      children: [
        const ItsHeadline('Pengajuan pencairan'),
        FutureBuilder<List<Disbursement>>(
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
                title: 'Tidak ada pengajuan',
                titleSize: 16,
                children: [
                  CardText(
                    'Belum ada pencairan yang perlu diproses.',
                    muted: true,
                  ),
                ],
              );
            }
            return Column(
              children: [
                for (final d in items) ...[
                  InfoCard(
                    overline: 'Menunggu pemeriksaan',
                    title: d.campaignTitle ?? 'Kampanye',
                    children: [
                      CardText('Diminta ${formatRupiah(d.amount)}'),
                      CardText(
                        'Diajukan ${formatDateTime(d.requestedAt)}',
                        muted: true,
                      ),
                      CardButton(
                        label: 'Periksa Pencairan',
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.adminDisbursementReview,
                            arguments: d,
                          );
                          if (mounted) _refresh();
                        },
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
}
