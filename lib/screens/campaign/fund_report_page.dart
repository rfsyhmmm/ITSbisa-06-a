import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/screens/campaign/fund_report_preview_page.dart';
import 'package:itsbisa/services/file_pick_service.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Figma S08.06 "Laporan Penggunaan Dana" (F12): isi pertanggungjawaban + bukti.
/// "Tinjau Laporan" membuka S08.07 untuk dipublikasikan.
class FundReportPage extends StatefulWidget {
  const FundReportPage({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<FundReportPage> createState() => _FundReportPageState();
}

class _FundReportPageState extends State<FundReportPage> {
  static const _maxEvidence = 6;

  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  late final _total = TextEditingController(
    text: formatThousands(widget.campaign.collectedAmount),
  );
  final List<PickedFile> _evidence = [];

  @override
  void dispose() {
    _description.dispose();
    _total.dispose();
    super.dispose();
  }

  Future<void> _addEvidence() async {
    if (_evidence.length >= _maxEvidence) {
      showSnack(context, 'Maksimal $_maxEvidence bukti');
      return;
    }
    try {
      final file = await FilePickService.pickImage();
      if (file != null && mounted) setState(() => _evidence.add(file));
    } catch (e) {
      if (mounted)
        showSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _review() async {
    if (!_formKey.currentState!.validate()) return;
    if (_evidence.isEmpty) {
      showSnack(context, 'Lampirkan minimal satu bukti penggunaan');
      return;
    }
    final published = await Navigator.pushNamed(
      context,
      AppRoutes.fundReportPreview,
      arguments: ReportDraft(
        campaign: widget.campaign,
        description: _description.text.trim(),
        totalUsed: parseRupiah(_total.text),
        evidence: List.of(_evidence),
      ),
    );
    if (published == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    return Form(
      key: _formKey,
      child: ItsPage(
        title: 'Laporan Penggunaan Dana',
        bottom: PrimaryButton(label: 'Tinjau Laporan', onPressed: _review),
        children: [
          InfoCard(
            overline: 'Dana dicairkan',
            title: c.title,
            children: [
              CardText('Dana dicairkan: ${formatRupiah(c.collectedAmount)}'),
            ],
          ),
          InfoCard(
            title: 'Pertanggungjawaban',
            children: [
              const FieldLabel('Penggunaan dana'),
              TextFormField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan penggunaan bantuan dan manfaatnya bagi penerima.',
                ),
                validator: (v) => (v == null || v.trim().length < 20)
                    ? 'Minimal 20 karakter'
                    : null,
              ),
              const FieldLabel('Total dana yang digunakan'),
              TextFormField(
                controller: _total,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: const InputDecoration(prefixText: 'Rp '),
                validator: (v) =>
                    parseRupiah(v ?? '') <= 0 ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              UploadTile(
                title: 'Bukti penggunaan',
                caption:
                    'Lampirkan foto nota atau bukti penggunaan bantuan (maks. $_maxEvidence).',
                onTap: _addEvidence,
                files: [
                  for (var i = 0; i < _evidence.length; i++)
                    (
                      name: _evidence[i].name,
                      onRemove: () => setState(() => _evidence.removeAt(i)),
                    ),
                ],
              ),
            ],
          ),
          const InfoCard(
            title: 'Sebelum publikasi',
            children: [
              CardText(
                'Pastikan bukti tidak membuka informasi rekening atau data pribadi yang tidak diperlukan.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
