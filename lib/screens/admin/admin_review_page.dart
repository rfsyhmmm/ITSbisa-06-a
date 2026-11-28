import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/services/admin_service.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/utils/formatters.dart';
import 'package:itsbisa/widgets/async_states.dart';
import 'package:itsbisa/widgets/its_ui.dart';

/// Figma S04.03 "Tinjau Kampanye" + S04.04 pratinjau dokumen privat (F06).
class AdminReviewPage extends StatefulWidget {
  const AdminReviewPage({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends State<AdminReviewPage> {
  late Future<(Beneficiary?, List<CampaignDocument>)> _future = _load();

  Future<(Beneficiary?, List<CampaignDocument>)> _load() => (
    AdminService.fetchBeneficiary(widget.campaign.id),
    AdminService.fetchDocuments(widget.campaign.id),
  ).wait;

  Future<void> _decide(bool approve) async {
    final done = await Navigator.pushNamed(
      context,
      AppRoutes.adminDecision,
      arguments: DecisionArgs(campaign: widget.campaign, approve: approve),
    );
    if (done == true && mounted) Navigator.pop(context, true);
  }

  void _showDocuments(List<CampaignDocument> docs) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Dokumen privat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            for (final d in docs)
              ListTile(
                leading: Icon(
                  d.fileName.toLowerCase().endsWith('.pdf')
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  d.type == 'consent'
                      ? 'Surat persetujuan penerima'
                      : 'Dokumen pendukung',
                ),
                subtitle: Text(
                  d.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.open_in_new),
                // Signed URL berlaku 1 jam; dibuka di browser/viewer perangkat.
                onTap: () => launchUrl(
                  Uri.parse(d.url),
                  mode: LaunchMode.externalApplication,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    return FutureBuilder<(Beneficiary?, List<CampaignDocument>)>(
      future: _future,
      builder: (context, snap) {
        final b = snap.data?.$1;
        final docs = snap.data?.$2 ?? const <CampaignDocument>[];
        return ItsPage(
          title: 'Tinjau Kampanye',
          children: [
            InfoCard(
              overline: joinLabel(['Dana', 'Menunggu verifikasi']),
              title: c.title,
              children: [
                CardText('Penggalang: ${c.organizer}'),
                if (b != null)
                  CardText(
                    'Penerima: ${b.recipientName} (${b.isSelf ? 'diri sendiri' : b.recipientType})',
                  ),
                if ((b?.identityNumber ?? '').isNotEmpty)
                  CardText('Identitas: ${b!.identityNumber}'),
                if ((b?.contactPhone ?? '').isNotEmpty)
                  CardText('HP: ${b!.contactPhone}'),
                CardText('Tenggat: ${formatDate(c.deadline)}'),
              ],
            ),
            InfoCard(
              title: 'Rincian kebutuhan',
              children: [
                CardText(
                  'Kategori ${c.category} · Target ${formatRupiah(c.targetAmount)}',
                ),
                const SizedBox(height: 6),
                CardText(c.story),
              ],
            ),
            InfoCard(
              title: 'Dokumen privat',
              children: [
                if (snap.hasError)
                  ErrorRetry(
                    error: snap.error!,
                    onRetry: () => setState(() => _future = _load()),
                  )
                else if (snap.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else ...[
                  for (final d in docs)
                    CardText(
                      d.type == 'consent'
                          ? 'Surat persetujuan penerima'
                          : 'Dokumen pendukung',
                    ),
                  if (docs.isEmpty)
                    const CardText('Tidak ada dokumen.', muted: true),
                  CardButton(
                    label: 'Lihat Dokumen',
                    onPressed: docs.isEmpty ? null : () => _showDocuments(docs),
                  ),
                ],
              ],
            ),
            InfoCard(
              title: 'Hasil pemeriksaan',
              children: [
                CardButton(
                  label: 'Setujui Kampanye',
                  onPressed: () => _decide(true),
                ),
                CardButton(
                  label: 'Tolak dengan Alasan',
                  color: AppColors.danger,
                  onPressed: () => _decide(false),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Argumen halaman Keputusan Pemeriksaan.
class DecisionArgs {
  const DecisionArgs({required this.campaign, required this.approve});

  final Campaign campaign;
  final bool approve;
}
