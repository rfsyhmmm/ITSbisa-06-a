import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/services/supabase_errors.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/widgets/payout_sheet.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Figma S08.01 "Ajukan Pencairan" dan S08.02 "Status Pencairan" (F11).
/// Satu halaman: tampilan berubah sesuai ada/tidaknya pengajuan dan statusnya.
class DisbursementPage extends StatefulWidget {
  const DisbursementPage({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<DisbursementPage> createState() => _DisbursementPageState();
}

class _DisbursementPageState extends State<DisbursementPage> {
  late Future<(Campaign, PayoutInfo, Disbursement?)> _future = _load();
  bool _submitting = false;

  Future<(Campaign, PayoutInfo, Disbursement?)> _load() async {
    final id = widget.campaign.id;
    final campaign = await CampaignService.fetchCampaign(id) ?? widget.campaign;
    final payout = await CampaignService.fetchMyProfile();
    final disbursement = await CampaignService.fetchDisbursement(id);
    return (campaign, payout, disbursement);
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _editPayout(PayoutInfo info) async {
    if (await PayoutSheet.show(context, info)) _reload();
  }

  Future<void> _request() async {
    setState(() => _submitting = true);
    try {
      await CampaignService.requestDisbursement(widget.campaign.id);
      if (!mounted) return;
      showSnack(
        context,
        'Pengajuan pencairan terkirim. Admin akan memeriksanya.',
      );
      await _reload();
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Campaign, PayoutInfo, Disbursement?)>(
      future: _future,
      builder: (context, snap) {
        if (snap.data == null) {
          return ItsPage(
            title: 'Ajukan Pencairan',
            children: [
              if (snap.hasError)
                ErrorRetry(error: snap.error!, onRetry: _reload)
              else
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        }
        final (c, payout, d) = snap.data!;
        return d == null ? _requestView(c, payout) : _statusView(c, payout, d);
      },
    );
  }

  /// S08.01: belum ada pengajuan.
  Widget _requestView(Campaign c, PayoutInfo payout) {
    final canRequest = c.status == CampaignStatus.completed;
    return ItsPage(
      title: 'Ajukan Pencairan',
      onRefresh: _reload,
      bottom: canRequest
          ? PrimaryButton(
              label: 'Kirim Pengajuan Pencairan',
              isLoading: _submitting,
              onPressed: payout.isComplete ? _request : null,
            )
          : null,
      children: [
        InfoCard(
          overline: joinLabel(['Dana', c.statusLabel]),
          title: c.title,
          children: [
            CardText('Dana berhasil: ${formatRupiah(c.collectedAmount)}'),
          ],
        ),
        _payoutCard('Rekening tujuan', payout, editable: true),
        InfoCard(
          title: 'Ringkasan pengajuan',
          children: [
            CardText('Nominal pencairan: ${formatRupiah(c.collectedAmount)}'),
            const CardText(
              'Hanya pembayaran berhasil yang telah dikonfirmasi sistem diperhitungkan.',
              muted: true,
            ),
            if (!canRequest)
              const CardText(
                'Pencairan dapat diajukan setelah kampanye selesai.',
                muted: true,
              ),
          ],
        ),
      ],
    );
  }

  /// S08.02: sudah ada pengajuan (menunggu, perlu perbaikan, atau dibayar).
  Widget _statusView(Campaign c, PayoutInfo payout, Disbursement d) {
    final revision = d.status == 'needs_revision';
    final paid = d.status == 'paid';
    return ItsPage(
      title: 'Status Pencairan',
      onRefresh: _reload,
      bottom: revision
          ? PrimaryButton(
              label: 'Kirim Ulang Pengajuan',
              isLoading: _submitting,
              onPressed: payout.isComplete ? _request : null,
            )
          : null,
      children: [
        InfoCard(
          overline: d.statusLabel,
          overlineColor: revision
              ? AppColors.danger
              : (paid ? AppColors.success : AppColors.primary),
          children: [
            AmountText(formatRupiah(d.amount)),
            CardText(c.title),
            CardText('Diajukan ${formatDateTime(d.requestedAt)}'),
            if (paid) CardText('Ditransfer ${formatDateTime(d.processedAt)}'),
          ],
        ),
        if (revision)
          InfoCard(
            title: 'Catatan admin',
            children: [
              CardText(d.adminNote ?? '-'),
              CardButton(
                label: 'Perbaiki Rekening',
                onPressed: () => _editPayout(payout),
              ),
            ],
          ),
        _payoutCard('Rekening penggalang', payout, editable: false),
        const InfoCard(
          title: 'Proses pencairan',
          children: [
            CardText('Pengajuan → Pemeriksaan → Transfer simulasi'),
            CardText('Laporan penggunaan dibuat setelah dana dicairkan.'),
          ],
        ),
      ],
    );
  }

  Widget _payoutCard(String title, PayoutInfo p, {required bool editable}) {
    final number = p.accountNumber ?? '';
    final masked = number.length > 4
        ? '•••• ${number.substring(number.length - 4)}'
        : number;
    return InfoCard(
      title: title,
      children: [
        if (p.isComplete) ...[
          CardText('${p.bankName} · $masked'),
          CardText(p.accountHolder ?? ''),
        ] else
          const CardText(
            'Rekening atau e-wallet belum diisi.',
            color: AppColors.danger,
          ),
        if (editable)
          CardButton(
            label: p.isComplete ? 'Periksa Rekening' : 'Isi Rekening',
            onPressed: () => _editPayout(p),
          ),
      ],
    );
  }
}
