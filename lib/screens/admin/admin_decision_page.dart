import 'package:flutter/material.dart';

import 'package:itsbisa/screens/admin/admin_review_page.dart';
import 'package:itsbisa/services/admin_service.dart';
import 'package:itsbisa/services/supabase_errors.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Figma S04.05 "Keputusan Pemeriksaan": setujui atau tolak (alasan wajib jika ditolak).
class AdminDecisionPage extends StatefulWidget {
  const AdminDecisionPage({super.key, required this.args});

  final DecisionArgs args;

  @override
  State<AdminDecisionPage> createState() => _AdminDecisionPageState();
}

class _AdminDecisionPageState extends State<AdminDecisionPage> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late bool _approve = widget.args.approve;
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AdminService.reviewCampaign(
        widget.args.campaign.id,
        approve: _approve,
        reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
      );
      if (!mounted) return;
      showSnack(
        context,
        _approve
            ? 'Kampanye disetujui dan menjadi aktif.'
            : 'Kampanye ditolak.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ItsPage(
        title: 'Keputusan Pemeriksaan',
        bottom: PrimaryButton(
          label: 'Simpan Keputusan',
          isLoading: _saving,
          onPressed: _save,
        ),
        children: [
          InfoCard(
            title: widget.args.campaign.title,
            children: const [
              CardText(
                'Pilih keputusan setelah memeriksa informasi dan dokumen kampanye.',
              ),
            ],
          ),
          InfoCard(
            title: 'Keputusan admin',
            children: [
              const FieldLabel('Keputusan'),
              DropdownButtonFormField<bool>(
                initialValue: _approve,
                items: const [
                  DropdownMenuItem(value: true, child: Text('Setujui')),
                  DropdownMenuItem(value: false, child: Text('Tolak')),
                ],
                onChanged: (v) => setState(() => _approve = v ?? true),
              ),
              const FieldLabel('Alasan pemeriksaan'),
              TextFormField(
                controller: _reason,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan alasan penolakan jika pengajuan ditolak.',
                ),
                validator: (v) => !_approve && (v == null || v.trim().isEmpty)
                    ? 'Alasan wajib diisi'
                    : null,
              ),
              const SizedBox(height: 8),
              const CardText(
                'Disetujui: kampanye menjadi Aktif. Ditolak: alasan dapat dilihat penggalang.',
                muted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
