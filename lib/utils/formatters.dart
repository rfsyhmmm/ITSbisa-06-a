import 'package:flutter/services.dart';

/// Mengubah 200000 menjadi "Rp200.000".
String formatRupiah(int value) => 'Rp${formatThousands(value)}';

/// Mengubah 200000 menjadi "200.000".
String formatThousands(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}

/// "200.000" -> 200000.
int parseRupiah(String text) =>
    int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// 28 Nov 2026
String formatDate(DateTime? d) {
  if (d == null) return '-';
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// 28 Nov 2026, 17.05
String formatDateTime(DateTime? d) {
  if (d == null) return '-';
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${formatDate(d)}, $hh.$mm';
}

/// "3 jam lalu", "2 hari lalu".
String timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
  if (diff.inDays < 1) return '${diff.inHours} jam lalu';
  if (diff.inDays < 30) return '${diff.inDays} hari lalu';
  return formatDate(d);
}

/// Pemisah ribuan saat mengetik nominal: 15000 -> 15.000.
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final value =
        int.tryParse(digits.length > 12 ? digits.substring(0, 12) : digits) ??
        0;
    final text = formatThousands(value);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
