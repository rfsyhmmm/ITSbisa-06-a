import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/services/supabase_errors.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/widgets/app_text_field.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Kartu ringkas rekening pencairan + tombol ubah.
/// Rekening wajib lengkap sebelum mengajukan kampanye dan pencairan (F02).
class PayoutCard extends StatelessWidget {
  const PayoutCard({super.key, required this.info, this.onEdit});

  final PayoutInfo? info;
  final VoidCallback? onEdit; // null = hanya tampil, tanpa tombol ubah

  @override
  Widget build(BuildContext context) {
    final i = info;
    final complete = i?.isComplete ?? false;
    final number = i?.accountNumber ?? '';
    final masked = number.length > 4
        ? '•••• ${number.substring(number.length - 4)}'
        : number;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: complete ? AppColors.surface : AppColors.warningLight,
        border: Border.all(
          color: complete ? AppColors.border : AppColors.warning,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.account_balance : Icons.warning_amber,
            color: complete ? AppColors.navy : AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: complete
                ? Text('${i!.bankName} $masked\na.n. ${i.accountHolder}')
                : const Text('Rekening atau e-wallet belum diisi'),
          ),
          if (onEdit != null)
            TextButton(
              onPressed: onEdit,
              child: Text(complete ? 'Ubah' : 'Isi'),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet untuk mengisi nama dan rekening pencairan.
/// Mengembalikan true jika berhasil disimpan.
class PayoutSheet extends StatefulWidget {
  const PayoutSheet({super.key, this.initial});

  final PayoutInfo? initial;

  static Future<bool> show(BuildContext context, PayoutInfo? initial) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PayoutSheet(initial: initial),
    );
    return saved ?? false;
  }

  @override
  State<PayoutSheet> createState() => _PayoutSheetState();
}

class _PayoutSheetState extends State<PayoutSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.fullName);
  late final _bank = TextEditingController(text: widget.initial?.bankName);
  late final _number = TextEditingController(
    text: widget.initial?.accountNumber,
  );
  late final _holder = TextEditingController(
    text: widget.initial?.accountHolder,
  );
  late String _method = widget.initial?.payoutMethod ?? 'bank';
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _bank, _number, _holder]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await CampaignService.updatePayout(
        fullName: _name.text,
        payoutMethod: _method,
        bankName: _bank.text,
        accountNumber: _number.text,
        accountHolder: _holder.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBank = _method == 'bank';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rekening Pencairan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nama lengkap',
                controller: _name,
                validator: _required,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'bank', label: Text('Bank')),
                  ButtonSegment(value: 'ewallet', label: Text('E-wallet')),
                ],
                selected: {_method},
                onSelectionChanged: (s) => setState(() => _method = s.first),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: isBank ? 'Nama bank' : 'Penyedia e-wallet',
                hint: isBank ? 'Contoh: BNI' : 'Contoh: GoPay',
                controller: _bank,
                validator: _required,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: isBank ? 'Nomor rekening' : 'Nomor e-wallet',
                controller: _number,
                keyboardType: TextInputType.number,
                validator: _required,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Atas nama',
                controller: _holder,
                validator: _required,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Simpan',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
