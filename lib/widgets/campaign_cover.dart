import 'package:flutter/material.dart';

import 'package:itsbisa/theme/app_colors.dart';

/// Foto sampul kampanye. Jika belum ada foto, tampil kotak biru muda + ikon.
class CampaignCover extends StatelessWidget {
  const CampaignCover({
    super.key,
    required this.url,
    this.height = 100,
    this.radius = 0,
  });

  final String? url;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      color: AppColors.primaryLight,
      child: Icon(
        Icons.volunteer_activism,
        size: height * 0.4,
        color: AppColors.primary,
      ),
    );
    final image = (url == null || url!.isEmpty)
        ? placeholder
        : Image.network(
            url!,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Container(height: height, color: AppColors.primaryLight),
          );
    if (radius == 0) return image;
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}
