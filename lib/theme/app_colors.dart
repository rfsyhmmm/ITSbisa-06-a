import 'package:flutter/material.dart';

/// Warna diambil dari desain Figma ITSbisa.
class AppColors {
  AppColors._();

  static const primary = Color(
    0xFF0CC0D9,
  ); // BiruMuda/B300 di Figma (tombol, menu aktif)
  static const primaryLight = Color(0xFFE7F9FB); // latar halaman Canonical UI
  static const navy = Color(0xFF0B2A5B); // tombol Donasi di detail kampanye
  static const background = Color(0xFFF7FBFC);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1F2933);
  static const textSecondary = Color(0xFF8A94A6);
  static const border = Color(0xFFDDE3EA);
  static const verified = Color(0xFF2F80ED);

  // Warna status (Riwayat, status kampanye). Ditambahkan untuk alur donasi.
  static const success = Color(0xFF1E9E5A);
  static const successLight = Color(0xFFE3F6EC);
  static const warning = Color(0xFFD98A00);
  static const warningLight = Color(0xFFFFF3DC);
  static const danger = Color(0xFFE11D48); // tombol "Tolak dengan Alasan"
  static const dangerLight = Color(0xFFFDE8E8);
}
