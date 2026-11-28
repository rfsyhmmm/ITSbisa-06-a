import 'package:flutter/material.dart';

import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/widgets/primary_button.dart';

/// Komponen tampilan Figma "Canonical UI" (S02–S08):
/// latar biru muda, kartu putih bersudut 16, label kecil biru (overline),
/// judul halaman navy rata kiri, tombol utama biru penuh di bawah.

/// Kerangka halaman: AppBar putih + judul navy rata kiri, isi dalam ListView
/// berlatar biru muda, dan area tombol putih di bawah (opsional).
class ItsPage extends StatelessWidget {
  const ItsPage({
    super.key,
    required this.title,
    required this.children,
    this.bottom,
    this.onRefresh,
    this.actions,
  });

  final String title;
  final List<Widget> children;
  final Widget? bottom; // biasanya PrimaryButton
  final Future<void> Function()? onRefresh;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    Widget body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: _withGaps(children),
    );
    if (onRefresh != null)
      body = RefreshIndicator(onRefresh: onRefresh!, child: body);

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: Navigator.canPop(context) ? 0 : 16,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: bottom == null
          ? null
          : Container(
              color: AppColors.surface,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: bottom,
                ),
              ),
            ),
    );
  }

  static List<Widget> _withGaps(List<Widget> items) {
    final out = <Widget>[];
    for (final w in items) {
      if (out.isNotEmpty) out.add(const SizedBox(height: 16));
      out.add(w);
    }
    return out;
  }
}

/// Judul besar di atas isi halaman, contoh "Mulai berbagi harapan".
class ItsHeadline extends StatelessWidget {
  const ItsHeadline(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ],
    );
  }
}

/// Kartu putih. [overline] = label kecil biru (contoh "DANA · AKTIF").
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    this.overline,
    this.overlineColor = AppColors.primary,
    this.title,
    this.titleColor = AppColors.textPrimary,
    this.titleSize = 18,
    this.children = const [],
    this.onTap,
  });

  final String? overline;
  final Color overlineColor;
  final String? title;
  final Color titleColor;
  final double titleSize;
  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overline != null) ...[
            Text(
              overline!.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: overlineColor,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            if (children.isNotEmpty) const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: onTap == null
          ? SizedBox(width: double.infinity, child: content)
          : InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: SizedBox(width: double.infinity, child: content),
            ),
    );
  }
}

/// Teks isi kartu (14, gelap). [muted] = teks keterangan kecil abu-abu.
class CardText extends StatelessWidget {
  const CardText(
    this.text, {
    super.key,
    this.muted = false,
    this.bold = false,
    this.color,
  });

  final String text;
  final bool muted;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: muted ? 12 : 14,
          height: 1.45,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color:
              color ??
              (muted ? AppColors.textSecondary : AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Nominal besar navy, contoh "Rp50.000" di Detail Donasi.
class AmountText extends StatelessWidget {
  const AmountText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
    ),
  );
}

/// Tombol di dalam kartu (sedikit lebih pendek dari tombol utama).
class CardButton extends StatelessWidget {
  const CardButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: PrimaryButton(
      label: label,
      onPressed: onPressed,
      color: color,
      height: 44,
      isLoading: isLoading,
    ),
  );
}

/// Kotak biru muda "+ Unggah dokumen" untuk memilih berkas.
class UploadTile extends StatelessWidget {
  const UploadTile({
    super.key,
    required this.title,
    required this.caption,
    required this.onTap,
    this.files = const [],
  });

  final String title;
  final String caption;
  final VoidCallback onTap;

  /// Nama berkas yang sudah dipilih + aksi hapus.
  final List<({String name, VoidCallback onRemove})> files;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+ $title',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final f in files)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(
                  f.name.toLowerCase().endsWith('.pdf')
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: f.onRemove,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Label kolom form (di atas input), seperti "Judul kampanye".
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    ),
  );
}

/// Label status ringkas untuk overline kartu, contoh "DANA · MENUNGGU PEMBAYARAN".
String joinLabel(List<String?> parts) =>
    parts.whereType<String>().where((p) => p.isNotEmpty).join(' · ');
