import 'package:flutter/material.dart';

import 'package:itsbisa/screens/donasi/donasi_page.dart';
import 'package:itsbisa/screens/home/home_page.dart';
import 'package:itsbisa/screens/profil/profil_page.dart';
import 'package:itsbisa/screens/riwayat/riwayat_page.dart';

/// Halaman utama setelah login, berisi menu bawah (bottom navigation):
/// Home, Donasi, Riwayat, Profil (sesuai Figma).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onOpenDonasiTab: () => _openTab(1)),
      const DonasiPage(),
      const RiwayatPage(),
      const ProfilPage(),
    ];

    return Scaffold(
      // IndexedStack menjaga posisi scroll tiap tab saat berpindah.
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _openTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Donasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
