import 'package:itsbisa/utils/parse.dart';

/// Kategori bantuan (tabel `categories`).
class CampaignCategory {
  const CampaignCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory CampaignCategory.fromMap(Map<String, dynamic> m) => CampaignCategory(
    id: m['id'] as String,
    name: m['name'] as String,
    slug: (m['slug'] ?? '') as String,
  );
}

/// Satu baris daftar donatur (RPC `list_campaign_donors`).
class DonorEntry {
  const DonorEntry({
    required this.name,
    required this.amount,
    this.message,
    this.paidAt,
  });

  final String name;
  final int amount;
  final String? message;
  final DateTime? paidAt;

  factory DonorEntry.fromMap(Map<String, dynamic> m) => DonorEntry(
    name: (m['donor_name'] ?? 'Donatur') as String,
    amount: asInt(m['amount']),
    message: m['message'] as String?,
    paidAt: asDate(m['paid_at']),
  );
}

/// Kabar terbaru kampanye (tabel `campaign_updates`).
class CampaignUpdate {
  const CampaignUpdate({
    required this.title,
    required this.content,
    this.imageUrl,
    this.createdAt,
  });

  final String title;
  final String content;
  final String? imageUrl;
  final DateTime? createdAt;

  factory CampaignUpdate.fromMap(Map<String, dynamic> m) => CampaignUpdate(
    title: m['title'] as String,
    content: m['content'] as String,
    imageUrl: m['image_url'] as String?,
    createdAt: asDate(m['created_at']),
  );
}

/// Laporan penggunaan dana (tabel `fund_usage_reports` + `report_evidence`).
class FundReport {
  const FundReport({
    required this.description,
    required this.totalUsed,
    required this.evidenceUrls,
    this.createdAt,
  });

  final String description;
  final int totalUsed;
  final List<String> evidenceUrls;
  final DateTime? createdAt;
}

/// Status pencairan (tabel `disbursements`).
class Disbursement {
  const Disbursement({
    required this.id,
    required this.campaignId,
    required this.amount,
    required this.status,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.adminNote,
    this.transferProofPath,
    this.requestedAt,
    this.processedAt,
    this.campaignTitle,
    this.campaignCollected,
  });

  final String id;
  final String campaignId;
  final int amount;
  final String status; // requested, needs_revision, paid
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final String? adminNote;
  final String? transferProofPath;
  final DateTime? requestedAt;
  final DateTime? processedAt;
  final String? campaignTitle;
  final int? campaignCollected; // dana berhasil (untuk admin)

  String get statusLabel => switch (status) {
    'requested' => 'Menunggu diproses admin',
    'needs_revision' => 'Perlu diperbaiki',
    'paid' => 'Sudah ditransfer',
    _ => status,
  };

  factory Disbursement.fromMap(Map<String, dynamic> m) => Disbursement(
    id: m['id'] as String,
    campaignId: m['campaign_id'] as String,
    amount: asInt(m['amount']),
    status: m['status'] as String,
    bankName: (m['bank_name'] ?? '') as String,
    accountNumber: (m['account_number'] ?? '') as String,
    accountHolder: (m['account_holder'] ?? '') as String,
    adminNote: m['admin_note'] as String?,
    transferProofPath: m['transfer_proof_url'] as String?,
    requestedAt: asDate(m['requested_at']),
    processedAt: asDate(m['processed_at']),
    campaignTitle: asSingle(m['campaigns'])?['title'] as String?,
    campaignCollected: asSingle(m['campaigns']) == null
        ? null
        : asInt(asSingle(m['campaigns'])!['collected_amount']),
  );
}

/// Hasil verifikasi admin terakhir (tabel `campaign_reviews`).
class CampaignReview {
  const CampaignReview({required this.decision, this.reason, this.reviewedAt});

  final String decision; // approved / rejected
  final String? reason;
  final DateTime? reviewedAt;

  factory CampaignReview.fromMap(Map<String, dynamic> m) => CampaignReview(
    decision: m['decision'] as String,
    reason: m['reason'] as String?,
    reviewedAt: asDate(m['reviewed_at']),
  );
}

/// Data rekening penggalang (kolom payout di `profiles`).
class PayoutInfo {
  const PayoutInfo({
    this.fullName,
    this.payoutMethod,
    this.bankName,
    this.accountNumber,
    this.accountHolder,
    this.role = 'user',
  });

  final String? fullName;
  final String? payoutMethod; // bank / ewallet
  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;
  final String role;

  bool get isComplete =>
      payoutMethod != null &&
      (bankName ?? '').trim().isNotEmpty &&
      (accountNumber ?? '').trim().isNotEmpty &&
      (accountHolder ?? '').trim().isNotEmpty;

  bool get isAdmin => role == 'admin';

  factory PayoutInfo.fromMap(Map<String, dynamic> m) => PayoutInfo(
    fullName: m['full_name'] as String?,
    payoutMethod: m['payout_method'] as String?,
    bankName: m['bank_name'] as String?,
    accountNumber: m['account_number'] as String?,
    accountHolder: m['account_holder'] as String?,
    role: (m['role'] ?? 'user') as String,
  );
}
