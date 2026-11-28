/// Pembantu membaca nilai dari JSON Supabase.
/// Kolom numeric bisa datang sebagai int, double, atau String.
int asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.round();
  return num.tryParse(value.toString())?.round() ?? 0;
}

DateTime? asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

/// Embed PostgREST kadang berupa objek, kadang list berisi satu objek.
Map<String, dynamic>? asSingle(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is List &&
      value.isNotEmpty &&
      value.first is Map<String, dynamic>) {
    return value.first as Map<String, dynamic>;
  }
  return null;
}
