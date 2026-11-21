import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/widgets/placeholder_view.dart';

/// Form donasi: nominal, anonim, pesan, lalu Midtrans (F07).
class DonationFormPage extends StatelessWidget {
  const DonationFormPage({super.key, required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donasi')),
      body: PlaceholderView(
        icon: Icons.payments_outlined,
        title: 'Donasi untuk ${campaign.title}',
        message: 'Form nominal dan pembayaran Midtrans sedang dikerjakan.',
      ),
    );
  }
}
