import 'package:flutter/material.dart';

import 'package:itsbisa/services/donation_service.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Bottom sheet "Tambahkan donasi" (Figma 101:6006): pilihan nominal + nominal lain.
/// Mengembalikan nominal terpilih, atau null jika ditutup.
class AmountSheet extends StatefulWidget {
  const AmountSheet({super.key, this.initial});

  final int? initial;

  static const presets = [15000, 25000, 50000, 100000];

  static Future<int?> show(BuildContext context, {int? initial}) =>
      showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => AmountSheet(initial: initial),
      );

  @override
  State<AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<AmountSheet> {
  late int? _preset = AmountSheet.presets.contains(widget.initial)
      ? widget.initial
      : null;
  late final _other = TextEditingController(
    text:
        widget.initial != null && !AmountSheet.presets.contains(widget.initial)
        ? formatThousands(widget.initial!)
        : '',
  );

  int get _value => _preset ?? parseRupiah(_other.text);
  bool get _valid => _value >= DonationService.minAmount && _value <= 100000000;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Tambahkan donasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Pilih nominal Anda',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            for (final p in AmountSheet.presets)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() {
                    _preset = p;
                    _other.clear();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _preset == p
                          ? AppColors.primaryLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _preset == p
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatRupiah(p),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Icon(
                          _preset == p
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: _preset == p
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Nominal lain',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _other,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              textAlign: TextAlign.right,
              onChanged: (_) => setState(() => _preset = null),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Donasi minimum adalah Rp5.000',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Pilih Nominal',
              onPressed: _valid ? () => Navigator.pop(context, _value) : null,
            ),
          ],
        ),
      ),
    );
  }
}
