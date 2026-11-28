import 'package:supabase_flutter/supabase_flutter.dart';

/// Mengubah error Supabase menjadi pesan yang bisa ditampilkan ke pengguna.
/// Pesan `raise exception` dari fungsi SQL sudah berbahasa Indonesia,
/// jadi cukup diteruskan.
String friendlyError(Object error) {
  if (error is PostgrestException) return error.message;
  if (error is StorageException)
    return 'Gagal mengunggah berkas: ${error.message}';
  if (error is AuthException) return error.message;
  if (error is FunctionException) {
    final details = error.details;
    if (details is Map && details['error'] is String)
      return details['error'] as String;
    return 'Layanan pembayaran sedang bermasalah (${error.status}).';
  }
  if (error is ItsbisaException) return error.message;
  return 'Terjadi kesalahan. Periksa koneksi lalu coba lagi.';
}

/// Error buatan aplikasi sendiri (validasi sebelum memanggil server).
class ItsbisaException implements Exception {
  const ItsbisaException(this.message);
  final String message;

  @override
  String toString() => message;
}
