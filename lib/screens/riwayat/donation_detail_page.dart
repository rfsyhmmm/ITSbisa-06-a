import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/models/donation.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/screens/campaign/payment_status_page.dart';
import 'package:itsbisa/screens/riwayat/riwayat_page.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/services/donation_service.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Figma S05.07 "Detail Donasi Dana" (F08 + UC Melanjutkan Pembayaran Tertunda).
class DonationDetailPage extends StatefulWidget {
  const DonationDetailPage({super.key, required this.donationId});

  final String donationId;

  @override
  State<DonationDetailPage> createState() => _DonationDetailPageState();
}

class _DonationDetailPageState extends State<DonationDetailPage> {
  late Future<Donation> _future = DonationService.fetchDonation(
    widget.donationId,
  );

  Future<void> _refresh() async {
    setState(() => _future = DonationService.fetchDonation(widget.donationId));
    await _future;
  }

  Future<void> _resume(Donation d) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.paymentStatus,
      arguments: PaymentArgs(
        donationId: d.id,
        redirectUrl: d.redirectUrl!,
        amount: d.amount,
        campaignTitle: d.campaignTitle,
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _openCampaign(Donation d) async {
    final Campaign? c = await CampaignService.fetchCampaign(d.campaignId);
    if (!mounted) return;
    if (c == null) {
      showSnack(context, 'Kampanye tidak dapat dibuka.');
      return;
    }
    Navigator.pushNamed(context, AppRoutes.campaignDetail, arguments: c);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Donation>(
      future: _future,
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) {
          return ItsPage(
            title: 'Detail Donasi Dana',
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
        final name = d.isAnonymous ? 'Anonim' : 'Nama akun Anda';
        return ItsPage(
          title: 'Detail Donasi Dana',
          onRefresh: _refresh,
          bottom: d.canResumePayment
              ? PrimaryButton(
                  label: 'Lanjutkan Bayar',
                  onPressed: () => _resume(d),
                )
              : null,
          children: [
            InfoCard(
              overline: d.statusLabel,
              overlineColor: d.isPaid
                  ? AppColors.success
                  : (d.isPending ? AppColors.primary : AppColors.danger),
              children: [
                AmountText(formatRupiah(d.amount)),
                CardText(d.campaignTitle),
                CardText('Ref ${shortRef(d.orderId ?? d.id)}'),
                CardText(formatDate(d.paidAt ?? d.createdAt)),
              ],
            ),
            InfoCard(
              title: 'Rincian',
              children: [
                CardText('Donatur: $name'),
                CardText(
                  'Pesan: ${(d.message ?? '').isEmpty ? '-' : d.message}',
                ),
                if (d.paymentType != null)
                  CardText('Metode: ${d.paymentType!.replaceAll('_', ' ')}'),
              ],
            ),
            if (d.canResumePayment)
              InfoCard(
                title: 'Lanjutkan pembayaran',
                children: [
                  CardText(
                    'Pembayaran dapat dilanjutkan selama transaksi masih berlaku '
                    '(sampai ${formatDateTime(d.expiryTime)}).',
                  ),
                  const CardText(
                    'Nominal belum dihitung sebagai perolehan kampanye sebelum pembayaran berhasil dikonfirmasi.',
                    muted: true,
                  ),
                ],
              ),
            InfoCard(
              title: 'Kampanye terkait',
              children: [
                CardButton(
                  label: 'Lihat Kampanye',
                  onPressed: () => _openCampaign(d),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
