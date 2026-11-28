import 'package:flutter/material.dart';

import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/theme/app_colors.dart';
import 'package:itsbisa/widgets/its_ui.dart';

/// Figma S03.01 "Ajukan Kampanye": pilih jenis bantuan.
/// Bantuan Barang belum tersedia karena tabelnya belum ada di database.
class CreateCampaignTypePage extends StatelessWidget {
  const CreateCampaignTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ItsPage(
      title: 'Ajukan Kampanye',
      children: [
        const ItsHeadline(
          'Mulai berbagi harapan',
          subtitle: 'Pilih jenis bantuan yang dibutuhkan penerima.',
        ),
        InfoCard(
          title: 'Bantuan Dana',
          titleColor: AppColors.navy,
          titleSize: 20,
          children: [
            const _TypeIcon(Icons.volunteer_activism),
            const CardText(
              'Galang dukungan dana untuk UKT, biaya hidup, kesehatan, dan kebutuhan lainnya.',
            ),
            CardButton(
              label: 'Pilih Bantuan Dana',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.submitCampaign),
            ),
          ],
        ),
        const InfoCard(
          title: 'Bantuan Barang',
          titleColor: AppColors.navy,
          titleSize: 20,
          children: [
            _TypeIcon(Icons.inventory_2_outlined),
            CardText(
              'Catat barang yang dibutuhkan beserta jumlah dan satuannya.',
            ),
            CardText('Segera hadir.', muted: true),
            CardButton(label: 'Pilih Bantuan Barang', onPressed: null),
          ],
        ),
        const InfoCard(
          title: 'Sebelum mengajukan',
          titleSize: 16,
          children: [
            CardText(
              'Gunakan email ITS yang terverifikasi dan lengkapi rekening pencairan.',
              muted: true,
            ),
            CardText(
              'Setiap pengajuan akan diperiksa admin sebelum kampanye menerima bantuan.',
              muted: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primaryLight,
      child: Icon(icon, size: 20, color: AppColors.navy),
    ),
  );
}
