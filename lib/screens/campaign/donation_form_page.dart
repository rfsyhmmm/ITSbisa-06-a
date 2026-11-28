import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/screens/campaign/payment_status_page.dart';
import 'package:itsbisa/services/donation_service.dart';
import 'package:itsbisa/services/supabase_errors.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/amount_sheet.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Figma S05.01 "Donasi Dana" (F07): nominal, tampilan nama, pesan, ringkasan.
/// "Lanjutkan Pembayaran" membuat transaksi lalu pindah ke S05.04 Pembayaran Donasi.
class DonationFormPage extends StatefulWidget {
  const DonationFormPage({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<DonationFormPage> createState() => _DonationFormPageState();
}

class _DonationFormPageState extends State<DonationFormPage> {
  final _message = TextEditingController();
  int? _amount;
  bool _anonymous = false;
  bool _loading = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickAmount() async {
    final value = await AmountSheet.show(context, initial: _amount);
    if (value != null) setState(() => _amount = value);
  }

  Future<void> _submit() async {
    final amount = _amount;
    if (amount == null) {
      _pickAmount();
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final checkout = await DonationService.createDonation(
        campaignId: widget.campaign.id,
        amount: amount,
        isAnonymous: _anonymous,
        message: _message.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.paymentStatus,
        arguments: PaymentArgs(
          donationId: checkout.donationId,
          redirectUrl: checkout.redirectUrl,
          amount: amount,
          campaignTitle: widget.campaign.title,
          openImmediately: false,
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    return ItsPage(
      title: 'Donasi Dana',
      bottom: PrimaryButton(
        label: 'Lanjutkan Pembayaran',
        isLoading: _loading,
        onPressed: _submit,
      ),
      children: [
        InfoCard(
          overline: joinLabel(['Dana', c.statusLabel]),
          title: c.title,
          children: [
            Text(c.story, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        InfoCard(
          title: 'Nominal donasi',
          children: [
            const FieldLabel('Nominal'),
            InkWell(
              onTap: _pickAmount,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.expand_more),
                ),
                child: Text(
                  _amount == null ? 'Pilih nominal' : formatRupiah(_amount!),
                  style: TextStyle(
                    fontSize: 16,
                    color: _amount == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const CardText('Minimum donasi Rp5.000.', muted: true),
          ],
        ),
        InfoCard(
          title: 'Identitas & dukungan',
          children: [
            const FieldLabel('Tampilkan nama'),
            DropdownButtonFormField<bool>(
              initialValue: _anonymous,
              items: const [
                DropdownMenuItem(value: false, child: Text('Nama akun saya')),
                DropdownMenuItem(value: true, child: Text('Anonim')),
              ],
              onChanged: (v) => setState(() => _anonymous = v ?? false),
            ),
            const FieldLabel('Pesan dukungan (opsional)'),
            TextField(
              controller: _message,
              maxLines: 3,
              maxLength: 255,
              decoration: const InputDecoration(
                hintText: 'Tulis pesan untuk penerima bantuan.',
              ),
            ),
          ],
        ),
        InfoCard(
          title: 'Ringkasan',
          children: [
            CardText(
              'Total donasi: ${_amount == null ? '-' : formatRupiah(_amount!)}',
            ),
            const CardText(
              'Metode pembayaran dipilih melalui halaman Midtrans.',
              muted: true,
            ),
          ],
        ),
      ],
    );
  }
}
