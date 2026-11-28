import 'package:itsbisa/utils/parse.dart';

/// Donasi milik pengguna, untuk Riwayat (tabel `donations` + `payment_transactions`).
class Donation {
  const Donation({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.amount,
    required this.status,
    this.isAnonymous = false,
    this.message,
    this.paidAt,
    this.createdAt,
    this.orderId,
    this.paymentType,
    this.paymentStatus,
    this.redirectUrl,
    this.expiryTime,
    this.campaignCoverUrl,
  });

  final String id;
  final String campaignId;
  final String campaignTitle;
  final int amount;
  final String status; // pending, paid, failed, expired, refunded
  final bool isAnonymous;
  final String? message;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final String? orderId;
  final String? paymentType;
  final String? paymentStatus;
  final String? redirectUrl;
  final DateTime? expiryTime;
  final String? campaignCoverUrl;

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';

  /// Pembayaran tertunda bisa dilanjutkan selama belum kedaluwarsa (F08).
  bool get canResumePayment =>
      isPending &&
      (redirectUrl ?? '').isNotEmpty &&
      (expiryTime == null || expiryTime!.isAfter(DateTime.now()));

  String get statusLabel => switch (status) {
    'pending' => canResumePayment ? 'Menunggu pembayaran' : 'Kedaluwarsa',
    'paid' => 'Berhasil',
    'failed' => 'Gagal',
    'expired' => 'Kedaluwarsa',
    'refunded' => 'Dikembalikan',
    _ => status,
  };

  factory Donation.fromMap(Map<String, dynamic> m) {
    final campaign = asSingle(m['campaigns']);
    final payment = asSingle(m['payment_transactions']);
    return Donation(
      id: m['id'] as String,
      campaignId: m['campaign_id'] as String,
      campaignTitle: (campaign?['title'] ?? 'Kampanye') as String,
      campaignCoverUrl: campaign?['cover_image_url'] as String?,
      amount: asInt(m['amount']),
      status: m['status'] as String,
      isAnonymous: (m['is_anonymous'] ?? false) as bool,
      message: m['message'] as String?,
      paidAt: asDate(m['paid_at']),
      createdAt: asDate(m['created_at']),
      orderId: payment?['order_id'] as String?,
      paymentType: payment?['payment_type'] as String?,
      paymentStatus: payment?['status'] as String?,
      redirectUrl: payment?['redirect_url'] as String?,
      expiryTime: asDate(payment?['expiry_time']),
    );
  }
}

/// Hasil Edge Function create-donation.
class DonationCheckout {
  const DonationCheckout({
    required this.donationId,
    required this.orderId,
    required this.redirectUrl,
  });

  final String donationId;
  final String orderId;
  final String redirectUrl;
}

/// Argumen rute Detail Donasi (cukup id donasi).
class DonationRef {
  const DonationRef(this.id);
  final String id;
}
