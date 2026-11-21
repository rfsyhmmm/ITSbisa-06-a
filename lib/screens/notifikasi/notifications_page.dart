import 'package:flutter/material.dart';

import 'package:itsbisa/widgets/placeholder_view.dart';

/// Halaman notifikasi (dibuka dari ikon lonceng di Home).
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: const PlaceholderView(
        icon: Icons.notifications_none,
        title: 'Belum ada notifikasi',
      ),
    );
  }
}
