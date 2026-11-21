import 'package:flutter/material.dart';

import 'package:itsbisa/widgets/placeholder_view.dart';

/// Tab Riwayat: riwayat donasi dan kampanye milik pengguna (F08).
class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: const PlaceholderView(
        icon: Icons.receipt_long,
        title: 'Riwayat Donasi dan Kampanye',
      ),
    );
  }
}
