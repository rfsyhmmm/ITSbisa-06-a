import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/services/file_pick_service.dart';
import 'package:itsbisa/services/supabase_errors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Isi laporan yang belum dipublikasikan.
class ReportDraft {
  const ReportDraft({
    required this.campaign,
    required this.description,
    required this.totalUsed,
    required this.evidence,
  });

  final Campaign campaign;
  final String description;
  final int totalUsed;
  final List<PickedFile> evidence;
}

/// Figma S08.07 "Laporan Bantuan Dana": pratinjau milik penggalang + tombol Publikasikan.
/// Setelah dipublikasikan, konten yang sama tampil di detail kampanye untuk publik.
class FundReportPreviewPage extends StatefulWidget {
  const FundReportPreviewPage({super.key, required this.draft});

  final ReportDraft draft;

  @override
  State<FundReportPreviewPage> createState() => _FundReportPreviewPageState();
}

class _FundReportPreviewPageState extends State<FundReportPreviewPage> {
  bool _publishing = false;

  Future<void> _publish() async {
    final d = widget.draft;
    setState(() => _publishing = true);
    try {
      await CampaignService.submitReport(
        campaignId: d.campaign.id,
        description: d.description,
        totalUsed: d.totalUsed,
        evidence: d.evidence,
      );
      if (!mounted) return;
      showSnack(context, 'Laporan dipublikasikan. Terima kasih!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return ItsPage(
      title: 'Laporan Bantuan Dana',
      bottom: PrimaryButton(
        label: 'Publikasikan Laporan',
        isLoading: _publishing,
        onPressed: _publish,
      ),
      children: [
        InfoCard(
          overline: 'Laporan penggunaan dana',
          title: d.campaign.title,
          children: [
            CardText(
              'Total bantuan: ${formatRupiah(d.campaign.collectedAmount)}',
            ),
            CardText('Dana digunakan: ${formatRupiah(d.totalUsed)}'),
          ],
        ),
        InfoCard(
          title: 'Ringkasan penggunaan',
          children: [CardText(d.description)],
        ),
        InfoCard(
          title: 'Bukti penggunaan',
          children: [
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: d.evidence.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    d.evidence[i].bytes,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const CardText(
              'Dokumentasi penggunaan ditampilkan pada laporan yang dipublikasikan.',
              muted: true,
            ),
          ],
        ),
        const InfoCard(
          title: 'Transparansi bantuan',
          children: [
            CardText(
              'Setelah dipublikasikan, laporan dapat dibaca melalui halaman kampanye.',
            ),
          ],
        ),
      ],
    );
  }
}
