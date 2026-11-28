import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Berkas yang sudah dipilih dan siap diunggah.
class PickedFile {
  const PickedFile({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  bool get isImage => contentType.startsWith('image/');
}

/// Satu-satunya tempat yang memanggil package file_picker.
/// Jika versi file_picker berbeda dan API-nya berubah, cukup ubah file ini.
class FilePickService {
  FilePickService._();

  static const imageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const documentExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
  static const maxBytes = 5 * 1024 * 1024; // 5 MB, sama dengan batas bucket

  /// Pilih gambar (sampul kampanye, bukti laporan).
  static Future<PickedFile?> pickImage() => _pick(imageExtensions);

  /// Pilih dokumen pendukung (gambar atau PDF).
  static Future<PickedFile?> pickDocument() =>
      _pick(documentExtensions, maxSize: 10 * 1024 * 1024);

  static Future<PickedFile?> _pick(
    List<String> extensions, {
    int maxSize = maxBytes,
  }) async {
    // file_picker v13: FilePicker.pickFile(). Untuk v8-v12 ganti dengan:
    //   final result = await FilePicker.platform.pickFiles(type: FileType.custom,
    //       allowedExtensions: extensions, withData: true);
    //   final file = result?.files.single;  final bytes = file?.bytes;
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.length > maxSize) {
      throw Exception('Ukuran berkas maksimal ${maxSize ~/ (1024 * 1024)} MB');
    }
    return PickedFile(
      name: file.name,
      bytes: bytes,
      contentType: _mimeOf(file.name),
    );
  }

  static String _mimeOf(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
