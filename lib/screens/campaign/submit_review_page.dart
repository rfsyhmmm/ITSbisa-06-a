import 'package:flutter/material.dart';

import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/services/supabase_errors.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Argumen halaman Tinjau Pengajuan.
class SubmitReviewArgs {
  const SubmitReviewArgs({
    required this.draft,
    required this.categoryName,
    required this.organizer,
  });

  final CampaignDraft draft;
  final String categoryName;
  final String organizer;
}

/// Figma S03.06 "Tinjau Pengajuan": ringkasan sebelum dikirim ke admin.
class SubmitReviewPage extends StatefulWidget {
  const SubmitReviewPage({super.key, required this.args});

  final SubmitReviewArgs args;

  @override
  State<SubmitReviewPage> createState() => _SubmitReviewPageState();
}

class _SubmitReviewPageState extends State<SubmitReviewPage> {
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await CampaignService.submitCampaign(widget.args.draft);
      if (!mounted) return;
      showSnack(context, 'Pengajuan terkirim. Menunggu verifikasi admin.');
      // Kembali ke beranda, lalu buka Kampanye Saya.
      final nav = Navigator.of(context);
      nav.popUntil((route) => route.isFirst);
      nav.pushNamed(AppRoutes.myCampaigns);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    final d = a.draft;
    final docs = d.documents.length;
    return ItsPage(
      title: 'Tinjau Pengajuan',
      bottom: PrimaryButton(
        label: 'Kirim Pengajuan',
        isLoading: _sending,
        onPressed: _send,
      ),
      children: [
        const ItsHeadline('Pastikan data sudah sesuai'),
        InfoCard(
          title: d.title,
          titleColor: AppColors.navy,
          titleSize: 20,
          children: [
            CardText(
              joinLabel(['Bantuan Dana', a.categoryName]),
              color: AppColors.primary,
            ),
            const SizedBox(height: 6),
            CardText('Penggalang: ${a.organizer.isEmpty ? '-' : a.organizer}'),
            CardText(
              'Penerima: ${d.recipientName}${d.isSelf ? ' (diri sendiri)' : ' (${d.recipientType})'}',
            ),
            CardText('Tenggat: ${formatDate(d.deadline)}'),
          ],
        ),
        InfoCard(
          title: 'Target kebutuhan',
          children: [CardText('Dana ${formatRupiah(d.targetAmount)}')],
        ),
        InfoCard(
          title: 'Dokumen terlampir',
          children: [
            CardText('Dokumen pendukung ($docs berkas)'),
            if (!d.isSelf) const CardText('Surat persetujuan penerima'),
            if (d.cover != null) const CardText('Foto sampul'),
            const CardText(
              'Dokumen dan data rekening bersifat privat.',
              muted: true,
            ),
            CardButton(
              label: 'Ubah Informasi',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const InfoCard(
          title: 'Menunggu verifikasi admin',
          titleColor: AppColors.navy,
          children: [
            CardText(
              'Setelah dikirim, admin memeriksa data dan dokumen Anda. '
              'Kampanye baru dapat menerima bantuan setelah disetujui.',
            ),
            CardText(
              'Dengan mengirim pengajuan, Anda menyatakan informasi yang diberikan sesuai '
              'dengan keadaan penerima.',
              muted: true,
            ),
          ],
        ),
      ],
    );
  }
}
