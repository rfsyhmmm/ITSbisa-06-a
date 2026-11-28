import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/services/admin_service.dart';
import 'package:itsbisa/services/file_pick_service.dart';
import 'package:itsbisa/services/supabase_errors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Figma S08.04 "Pemeriksaan Pencairan" (+ S08.05 catat transfer digabung) (F11).
class AdminDisbursementReviewPage extends StatefulWidget {
  const AdminDisbursementReviewPage({super.key, required this.disbursement});

  final Disbursement disbursement;

  @override
  State<AdminDisbursementReviewPage> createState() =>
      _AdminDisbursementReviewPageState();
}

class _AdminDisbursementReviewPageState
    extends State<AdminDisbursementReviewPage> {
  final _note = TextEditingController();
  PickedFile? _proof;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    try {
      final file = await FilePickService.pickDocument();
      if (file != null && mounted) setState(() => _proof = file);
    } catch (e) {
      if (mounted)
        showSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      showSnack(context, done);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _requestRevision() {
    final note = _note.text.trim();
    if (note.isEmpty) {
      showSnack(context, 'Isi catatan untuk penggalang terlebih dahulu');
      return;
    }
    _run(
      () => AdminService.requestRevision(widget.disbursement, note),
      'Permintaan perbaikan dikirim.',
    );
  }

  void _confirm() {
    final proof = _proof;
    if (proof == null) {
      showSnack(context, 'Unggah bukti transfer terlebih dahulu');
      return;
    }
    final note = _note.text.trim();
    _run(
      () => AdminService.approveDisbursement(
        widget.disbursement,
        proof,
        note: note.isEmpty ? null : note,
      ),
      'Dana ditandai sudah dicairkan.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.disbursement;
    return ItsPage(
      title: 'Pemeriksaan Pencairan',
      bottom: PrimaryButton(
        label: 'Konfirmasi Dana Dicairkan',
        isLoading: _busy,
        onPressed: _confirm,
      ),
      children: [
        InfoCard(
          title: d.campaignTitle ?? 'Kampanye',
          children: [
            if (d.campaignCollected != null)
              CardText('Dana berhasil: ${formatRupiah(d.campaignCollected!)}'),
            CardText('Diminta: ${formatRupiah(d.amount)}'),
            const CardText('Kampanye selesai'),
          ],
        ),
        InfoCard(
          title: 'Rekening privat',
          children: [
            CardText('${d.bankName} · ${d.accountNumber}'),
            CardText('Nama: ${d.accountHolder}'),
          ],
        ),
        InfoCard(
          title: 'Catatan pemeriksaan',
          children: [
            const FieldLabel('Catatan untuk penggalang'),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Isi jika rekening atau data perlu diperbaiki.',
              ),
            ),
            CardButton(
              label: 'Minta Perbaikan',
              onPressed: _busy ? null : _requestRevision,
            ),
          ],
        ),
        InfoCard(
          title: 'Catat transfer simulasi',
          children: [
            UploadTile(
              title: 'Bukti transfer',
              caption: 'Bukti pencairan simulasi oleh admin (JPG, PNG, PDF).',
              onTap: _pickProof,
              files: [
                if (_proof != null)
                  (
                    name: _proof!.name,
                    onRemove: () => setState(() => _proof = null),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const CardText(
              'Pencatatan transfer mengubah status pencairan menjadi selesai.',
              muted: true,
            ),
          ],
        ),
      ],
    );
  }
}
