import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';

/// Figma S03.09 "Kelola Kampanye" + S07.04 "Kampanye Selesai" (owner hub).
/// Menunjukkan posisi kampanye di Proses A dan langkah berikutnya.
/// Tidak ada tombol tutup manual: kampanye ditutup otomatis (target/tenggat).
class ManageCampaignPage extends StatefulWidget {
  const ManageCampaignPage({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<ManageCampaignPage> createState() => _ManageCampaignPageState();
}

class _ManageData {
  const _ManageData(this.campaign, this.review, this.disbursement, this.report);

  final Campaign campaign;
  final CampaignReview? review;
  final Disbursement? disbursement;
  final FundReport? report;
}

class _ManageCampaignPageState extends State<ManageCampaignPage> {
  late Future<_ManageData> _future = _load();

  Future<_ManageData> _load() async {
    final id = widget.campaign.id;
    final c = await CampaignService.fetchCampaign(id) ?? widget.campaign;
    final r = await Future.wait<Object?>([
      CampaignService.fetchLatestReview(id),
      CampaignService.fetchDisbursement(id),
      CampaignService.fetchReport(id),
    ]);
    return _ManageData(
      c,
      r[0] as CampaignReview?,
      r[1] as Disbursement?,
      r[2] as FundReport?,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _go(String route, [Object? args]) async {
    await Navigator.pushNamed(context, route, arguments: args);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ManageData>(
      future: _future,
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) {
          return ItsPage(
            title: 'Kelola Kampanye',
            children: [
              if (snap.hasError)
                ErrorRetry(error: snap.error!, onRetry: _refresh)
              else
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        }
        final c = data.campaign;
        final closed = const [
          CampaignStatus.completed,
          CampaignStatus.disbursed,
          CampaignStatus.reported,
        ].contains(c.status);
        return ItsPage(
          title: closed ? 'Kampanye Selesai' : 'Kelola Kampanye',
          onRefresh: _refresh,
          children: [
            InfoCard(
              overline: joinLabel([
                'Dana',
                c.statusLabel,
                if (closed) _closeReason(c),
              ]),
              overlineColor: c.status == CampaignStatus.rejected
                  ? AppColors.danger
                  : AppColors.primary,
              title: c.title,
              children: [
                if (c.status == CampaignStatus.pendingReview ||
                    c.status == CampaignStatus.rejected)
                  CardText(
                    'Target ${formatRupiah(c.targetAmount)} · Tenggat ${formatDate(c.deadline)}',
                  )
                else ...[
                  CardText(
                    '${formatRupiah(c.collectedAmount)} dari target ${formatRupiah(c.targetAmount)}',
                  ),
                  CardText('${c.donorCount} donatur'),
                  if (c.isActive) CardText('Sisa ${c.daysLeft} hari'),
                  if (closed)
                    const CardText(
                      'Bantuan baru tidak lagi diterima.',
                      muted: true,
                    ),
                ],
              ],
            ),
            ..._stepCards(data),
            InfoCard(
              title: 'Informasi kampanye',
              children: [
                CardButton(
                  label: 'Lihat Halaman Publik',
                  onPressed: () => _go(AppRoutes.campaignDetail, c),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _closeReason(Campaign c) => c.collectedAmount >= c.targetAmount
      ? 'Target tercapai'
      : 'Tenggat berakhir';

  /// Kartu langkah berikutnya sesuai status (Proses A).
  List<Widget> _stepCards(_ManageData data) {
    final c = data.campaign;
    final d = data.disbursement;
    switch (c.status) {
      case CampaignStatus.pendingReview:
        return const [
          InfoCard(
            title: 'Menunggu verifikasi admin',
            titleColor: AppColors.navy,
            children: [
              CardText(
                'Admin memeriksa data dan dokumen Anda. Kampanye baru dapat menerima '
                'bantuan setelah disetujui.',
              ),
            ],
          ),
        ];
      case CampaignStatus.rejected:
        return [
          InfoCard(
            title: 'Pengajuan ditolak',
            titleColor: AppColors.danger,
            children: [
              CardText('Alasan: ${data.review?.reason ?? '-'}'),
              const CardText(
                'Perbaiki data lalu ajukan kampanye baru.',
                muted: true,
              ),
              CardButton(
                label: 'Ajukan Kampanye Baru',
                onPressed: () => _go(AppRoutes.createCampaign),
              ),
            ],
          ),
        ];
      case CampaignStatus.active:
        return const [
          InfoCard(
            title: 'Setelah kampanye selesai',
            children: [
              CardText(
                'Kampanye ditutup otomatis saat target tercapai atau tenggat berakhir. '
                'Setelah itu ajukan pencairan dana dan unggah laporan.',
              ),
            ],
          ),
        ];
      case CampaignStatus.completed:
        return [
          InfoCard(
            title: 'Tahap berikutnya',
            children: [
              if (d == null) ...[
                const CardText(
                  'Ajukan pencairan dana ke rekening Anda, lalu unggah laporan penggunaan dana.',
                ),
                CardButton(
                  label: 'Ajukan Pencairan',
                  onPressed: () => _go(AppRoutes.disbursement, c),
                ),
              ] else ...[
                CardText(
                  'Pencairan ${formatRupiah(d.amount)}: ${d.statusLabel}.',
                ),
                CardButton(
                  label: 'Lihat Status Pencairan',
                  onPressed: () => _go(AppRoutes.disbursement, c),
                ),
              ],
            ],
          ),
        ];
      case CampaignStatus.disbursed:
        return [
          InfoCard(
            title: 'Dana sudah dicairkan',
            children: [
              const CardText(
                'Unggah laporan penggunaan dana beserta bukti, seperti foto nota.',
              ),
              CardButton(
                label: 'Buat Laporan',
                onPressed: () => _go(AppRoutes.fundReport, c),
              ),
            ],
          ),
        ];
      case CampaignStatus.reported:
        return [
          InfoCard(
            title: 'Laporan dipublikasikan',
            children: [
              CardText(
                'Dana digunakan: ${formatRupiah(data.report?.totalUsed ?? 0)}',
              ),
              const CardText(
                'Donatur dapat membaca laporan melalui halaman kampanye.',
                muted: true,
              ),
            ],
          ),
        ];
      default:
        return const [];
    }
  }
}
