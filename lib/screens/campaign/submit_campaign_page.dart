import 'package:flutter/material.dart';

import 'package:itsbisa/widgets/placeholder_view.dart';

/// Form pengajuan kampanye (F05). Dibuka dari "Galang Dana" di Home.
class SubmitCampaignPage extends StatelessWidget {
  const SubmitCampaignPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galang Dana')),
      body: const PlaceholderView(
        icon: Icons.campaign_outlined,
        title: 'Ajukan Kampanye',
      ),
    );
  }
}
