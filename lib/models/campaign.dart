/// Model sederhana kampanye. Nanti diisi dari tabel `campaigns` di Supabase.
class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    required this.organizer,
    required this.category,
    required this.targetAmount,
    required this.collectedAmount,
    required this.daysLeft,
    this.isVerified = false,
    this.isUrgent = false,
  });

  final String id;
  final String title;
  final String organizer;
  final String category;
  final int targetAmount;
  final int collectedAmount;
  final int daysLeft;
  final bool isVerified;
  final bool isUrgent;

  /// Nilai 0.0 sampai 1.0 untuk progress bar.
  double get progress {
    if (targetAmount <= 0) return 0;
    return (collectedAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  }
}
