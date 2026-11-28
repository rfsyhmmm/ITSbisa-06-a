import 'package:itsbisa/utils/parse.dart';

/// Status kampanye sesuai kolom `campaigns.status` di database.
class CampaignStatus {
  CampaignStatus._();

  static const draft = 'draft';
  static const pendingReview = 'pending_review';
  static const rejected = 'rejected';
  static const active = 'active';
  static const completed = 'completed';
  static const disbursed = 'disbursed';
  static const reported = 'reported';

  static String label(String status) => switch (status) {
    draft => 'Draf',
    pendingReview => 'Menunggu Verifikasi',
    rejected => 'Ditolak',
    active => 'Aktif',
    completed => 'Selesai',
    disbursed => 'Dana Dicairkan',
    reported => 'Dilaporkan',
    _ => status,
  };
}

/// Kampanye. Diisi dari RPC `get_campaigns` (lihat CampaignService).
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
    this.ownerId = '',
    this.categoryId = '',
    this.story = '',
    this.coverImageUrl,
    this.deadline,
    this.status = CampaignStatus.active,
    this.createdAt,
    this.donorCount = 0,
  });

  final String id;
  final String title;
  final String organizer; // nama penggalang (profiles.full_name)
  final String category; // nama kategori
  final int targetAmount;
  final int collectedAmount;
  final int daysLeft;
  final bool isVerified; // sudah disetujui admin
  final bool isUrgent;

  final String ownerId;
  final String categoryId;
  final String story;
  final String? coverImageUrl;
  final DateTime? deadline;
  final String status;
  final DateTime? createdAt;
  final int donorCount;

  factory Campaign.fromMap(Map<String, dynamic> m) {
    final deadline = asDate(m['deadline']);
    final status = (m['status'] ?? CampaignStatus.active) as String;
    return Campaign(
      id: m['id'] as String,
      title: (m['title'] ?? '') as String,
      organizer: (m['owner_name'] ?? 'Penggalang ITS') as String,
      category: (m['category_name'] ?? '') as String,
      targetAmount: asInt(m['target_amount']),
      collectedAmount: asInt(m['collected_amount']),
      daysLeft: _daysLeft(deadline),
      isVerified: const [
        CampaignStatus.active,
        CampaignStatus.completed,
        CampaignStatus.disbursed,
        CampaignStatus.reported,
      ].contains(status),
      isUrgent: (m['is_urgent'] ?? false) as bool,
      ownerId: (m['owner_id'] ?? '') as String,
      categoryId: (m['category_id'] ?? '') as String,
      story: (m['story'] ?? '') as String,
      coverImageUrl: m['cover_image_url'] as String?,
      deadline: deadline,
      status: status,
      createdAt: asDate(m['created_at']),
      donorCount: asInt(m['donor_count']),
    );
  }

  static int _daysLeft(DateTime? deadline) {
    if (deadline == null) return 0;
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 0;
    return (diff.inHours / 24).ceil();
  }

  /// Nilai 0.0 sampai 1.0 untuk progress bar.
  double get progress {
    if (targetAmount <= 0) return 0;
    return (collectedAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  }

  bool get isActive => status == CampaignStatus.active;

  /// Kampanye menerima donasi hanya saat aktif dan tenggat belum lewat.
  bool get acceptsDonation =>
      isActive && (deadline == null || deadline!.isAfter(DateTime.now()));

  String get statusLabel => CampaignStatus.label(status);
}
