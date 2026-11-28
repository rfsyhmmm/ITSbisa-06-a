import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/services/campaign_service.dart';
import 'package:itsbisa/theme/app_colors.dart';

/// Tab Profil. Tombol Keluar dipindah dari halaman "Berhasil masuk" lama.
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal keluar. Coba lagi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(email, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Ubah profil dan rekening'),
            subtitle: const Text('Segera hadir'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('Ajukan kampanye'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.createCampaign),
          ),
          // Panel admin hanya untuk akun dengan profiles.role = 'admin'.
          FutureBuilder<PayoutInfo>(
            future: CampaignService.fetchMyProfile(),
            builder: (context, snap) {
              if (snap.data?.isAdmin != true) return const SizedBox.shrink();
              return ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Panel Admin'),
                subtitle: const Text('Verifikasi kampanye dan pencairan dana'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.admin),
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
