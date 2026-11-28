import 'dart:async';

import 'package:flutter/material.dart';

import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/services/donation_service.dart';
import 'package:itsbisa/services/supabase_errors.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Data yang dibawa ke halaman Pembayaran Donasi dan halaman sukses.
class PaymentArgs {
  const PaymentArgs({
    required this.donationId,
    required this.redirectUrl,
    required this.amount,
    required this.campaignTitle,
    this.openImmediately = true,
  });

  final String donationId;
  final String redirectUrl;
  final int amount;
  final String campaignTitle;

  /// true: langsung buka Midtrans (dari Riwayat "Lanjutkan Bayar").
  final bool openImmediately;
}

/// Figma S05.04 "Pembayaran Donasi" (Payment External Handoff).
/// Status donasi diubah oleh Edge Function midtrans-notification; halaman ini
/// membaca ulang status saat aplikasi kembali dibuka dan setiap 5 detik.
class PaymentStatusPage extends StatefulWidget {
  const PaymentStatusPage({super.key, required this.args});

  final PaymentArgs args;

  @override
  State<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage>
    with WidgetsBindingObserver {
  Timer? _timer;
  String _status = 'pending';
  bool _checking = false;
  bool _opened = false;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (++_ticks > 120) {
        _timer?.cancel(); // berhenti setelah 10 menit; status tetap bisa dicek dari Riwayat
        return;
      }
      if (_opened) _check();
    });
    if (widget.args.openImmediately)
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _opened) _check();
  }

  Future<void> _open() async {
    try {
      await DonationService.openPayment(widget.args.redirectUrl);
      if (mounted) setState(() => _opened = true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    }
  }

  Future<void> _check({bool manual = false}) async {
    if (_checking) return;
    _checking = true;
    try {
      final status = await DonationService.fetchStatus(widget.args.donationId);
      if (!mounted) return;
      setState(() => _status = status);
      if (status == 'paid') {
        _timer?.cancel();
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.donationSuccess,
          arguments: widget.args,
        );
      } else if (status != 'pending') {
        _timer?.cancel();
      } else if (manual) {
        showSnack(
          context,
          'Pembayaran belum terkonfirmasi. Selesaikan pembayaran di halaman Midtrans.',
        );
      }
    } catch (e) {
      if (manual && mounted) showSnack(context, friendlyError(e));
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    final failed = _status != 'pending' && _status != 'paid';

    if (failed) {
      return ItsPage(
        title: 'Pembayaran Donasi',
        bottom: PrimaryButton(
          label: 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
        children: [
          InfoCard(
            overline: 'Pembayaran tidak berhasil',
            overlineColor: AppColors.danger,
            title: a.campaignTitle,
            children: [
              CardText('Donasi ${formatRupiah(a.amount)}'),
              const CardText(
                'Transaksi dibatalkan atau kedaluwarsa. Silakan buat donasi baru.',
                muted: true,
              ),
            ],
          ),
        ],
      );
    }

    return ItsPage(
      title: 'Pembayaran Donasi',
      bottom: PrimaryButton(
        label: _opened ? 'Buka Lagi Pembayaran' : 'Buka Pembayaran',
        onPressed: _open,
      ),
      children: [
        InfoCard(
          title: 'Lanjutkan di Midtrans',
          titleColor: AppColors.navy,
          children: [
            CardText(a.campaignTitle),
            CardText('Donasi ${formatRupiah(a.amount)}'),
          ],
        ),
        const InfoCard(
          title: 'Pembayaran aman',
          children: [
            CardText(
              'Anda akan diarahkan ke halaman Midtrans Sandbox untuk memilih metode dan '
              'menyelesaikan pembayaran.',
            ),
            CardText(
              'Seluruh pembayaran pada proyek ini bersifat simulasi.',
              muted: true,
            ),
          ],
        ),
        InfoCard(
          title: 'Setelah membayar',
          children: [
            const CardText(
              'Status diperbarui setelah pembayaran dikonfirmasi sistem. '
              'Anda dapat memantaunya melalui Riwayat.',
            ),
            if (_opened)
              CardButton(
                label: 'Cek Status Pembayaran',
                onPressed: () => _check(manual: true),
              ),
          ],
        ),
      ],
    );
  }
}
