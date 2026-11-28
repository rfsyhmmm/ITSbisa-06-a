import 'package:flutter/material.dart';

import 'package:itsbisa/models/donation.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/services/donation_service.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/utils/formatters.dart';

/// Tab Riwayat = Figma S05.06 "Riwayat" (F08): aktivitas donasi + pintu ke Kampanye Saya.
class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  late Future<List<Donation>> _future = DonationService.fetchMyDonations();

  Future<void> _refresh() async {
    setState(() => _future = DonationService.fetchMyDonations());
    await _future;
  }

  Future<void> _push(String route, [Object? args]) async {
    await Navigator.pushNamed(context, route, arguments: args);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ItsPage(
      title: 'Riwayat',
      onRefresh: _refresh,
      children: [
        const InfoCard(
          title: 'Aktivitas Anda',
          children: [CardText('Donasi Dana · Kampanye Saya')],
        ),
        FutureBuilder<List<Donation>>(
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
                title: 'Belum ada donasi',
                titleSize: 16,
                children: [
                  CardText(
                    'Donasi yang Anda lakukan akan tampil di sini.',
                    muted: true,
                  ),
                ],
              );
            }
            return Column(
              children: [
                for (final d in items) ...[
                  InfoCard(
                    overline: joinLabel(['Dana', d.statusLabel]),
                    title: d.campaignTitle,
                    children: [
                      CardText(
                        '${formatRupiah(d.amount)} · Ref ${shortRef(d.orderId ?? d.id)}',
                      ),
                      CardButton(
                        label: 'Lihat Detail Donasi',
                        onPressed: () =>
                            _push(AppRoutes.donationDetail, DonationRef(d.id)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
        InfoCard(
          title: 'Kampanye Saya',
          children: [
            CardButton(
              label: 'Lihat Kampanye Saya',
              onPressed: () => _push(AppRoutes.myCampaigns),
            ),
          ],
        ),
      ],
    );
  }
}

/// "ITSB-8873e74f-78ad-..." -> "ITSB-8873E74F" (referensi singkat yang mudah dibaca).
String shortRef(String orderId) {
  final parts = orderId.split('-');
  if (parts.length >= 2 && parts.first == 'ITSB')
    return 'ITSB-${parts[1].toUpperCase()}';
  return orderId.length > 13
      ? orderId.substring(0, 13).toUpperCase()
      : orderId.toUpperCase();
}
