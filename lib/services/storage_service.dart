import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:itsbisa/services/file_pick_service.dart';

/// Nama bucket Storage (dibuat oleh 002_alur_kampanye_donasi.sql).
class Buckets {
  Buckets._();

  static const covers = 'campaign-covers'; // publik
  static const documents = 'campaign-documents'; // privat
  static const reportEvidence = 'report-evidence'; // publik
  static const transferProofs = 'transfer-proofs'; // privat
}

class StorageService {
  StorageService._();

  static SupabaseStorageClient get _storage => Supabase.instance.client.storage;

  /// Mengunggah berkas dan mengembalikan path di dalam bucket.
  /// [folder] contoh: '<uid>/<campaignId>'. Nama file dibuat unik.
  static Future<String> upload(
    String bucket,
    String folder,
    PickedFile file,
  ) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safeExt = file.extension.isEmpty ? 'bin' : file.extension;
    final path = '$folder/$stamp.$safeExt';
    await _storage
        .from(bucket)
        .uploadBinary(
          path,
          file.bytes,
          fileOptions: FileOptions(
            contentType: file.contentType,
            upsert: false,
          ),
        );
    return path;
  }

  static String publicUrl(String bucket, String path) =>
      _storage.from(bucket).getPublicUrl(path);

  /// URL sementara untuk berkas di bucket privat (dokumen, bukti transfer).
  static Future<String> signedUrl(
    String bucket,
    String path, {
    int seconds = 3600,
  }) => _storage.from(bucket).createSignedUrl(path, seconds);

  static Future<void> remove(String bucket, List<String> paths) async {
    if (paths.isEmpty) return;
    await _storage.from(bucket).remove(paths);
  }
}
