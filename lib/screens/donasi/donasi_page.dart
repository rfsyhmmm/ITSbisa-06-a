import 'package:flutter/material.dart';

import 'package:itsbisa/data/dummy_campaigns.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/widgets/campaign_card.dart';

/// Tab Donasi: daftar semua kampanye aktif.
class DonasiPage extends StatelessWidget {
  const DonasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donasi')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: dummyCampaigns.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final c = dummyCampaigns[i];
          void open() => Navigator.pushNamed(
                context,
                AppRoutes.campaignDetail,
                arguments: c,
              );
          return CampaignCard(campaign: c, onTap: open, onDonate: open);
        },
      ),
    );
  }
}
