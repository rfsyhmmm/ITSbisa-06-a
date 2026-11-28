import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/services/file_pick_service.dart';
import 'package:itsbisa/services/storage_service.dart';
import 'package:itsbisa/services/supabase_errors.dart';
import 'package:itsbisa/utils/parse.dart';

/// Data yang diisi penggalang di form Galang Dana (F05).
class CampaignDraft {
  CampaignDraft({
    required this.categoryId,
    required this.title,
    required this.story,
    required this.targetAmount,
    required this.deadline,
    required this.isSelf,
    required this.recipientType,
    required this.recipientName,
    this.identityNumber,
    this.contactPhone,
    this.cover,
    this.documents = const [],
    this.consent,
  });

  final String categoryId;
  final String title;
  final String story;
  final int targetAmount;
  final DateTime deadline;
  final bool isSelf; // bantuan untuk diri sendiri
  final String recipientType; // contoh: Mahasiswa, Keluarga, Organisasi
  final String recipientName;
  final String? identityNumber;
  final String? contactPhone;
  final PickedFile? cover;
  final List<({String type, PickedFile file})> documents;
  final PickedFile? consent; // wajib jika bukan untuk diri sendiri
}

/// Semua akses data kampanye: daftar, detail, pengajuan, pencairan, laporan.
class CampaignService {
  CampaignService._();

  static SupabaseClient get _db => Supabase.instance.client;
  static String get _uid {
    final id = _db.auth.currentUser?.id;
    if (id == null)
      throw const ItsbisaException('Silakan masuk terlebih dahulu');
    return id;
  }

  // ------------------------------------------------------------------ daftar
  static Future<List<CampaignCategory>> fetchCategories() async {
    final rows = await _db
        .from('categories')
        .select('id, name, slug')
        .eq('is_active', true)
        .order('name');
    return rows.map(CampaignCategory.fromMap).toList();
  }

  /// Daftar kampanye publik. Dipakai Home dan tab Donasi (F03).
  static Future<List<Campaign>> fetchCampaigns({
    String? search,
    String? categoryId,
    bool urgentOnly = false,
    bool activeOnly = true,
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _db.rpc(
      'get_campaigns',
      params: {
        'p_search': search,
        'p_category_id': categoryId,
        'p_urgent_only': urgentOnly,
        'p_statuses': activeOnly ? [CampaignStatus.active] : null,
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return _toCampaigns(rows);
  }

  /// Kampanye milik pengguna (semua status), untuk Riwayat > Kampanye Saya (F08).
  static Future<List<Campaign>> fetchMyCampaigns() async {
    final rows = await _db.rpc(
      'get_campaigns',
      params: {'p_owner_only': true, 'p_limit': 100},
    );
    return _toCampaigns(rows);
  }

  static Future<Campaign?> fetchCampaign(String id) async {
    final rows = await _db.rpc(
      'get_campaigns',
      params: {'p_campaign_id': id, 'p_limit': 1},
    );
    final list = _toCampaigns(rows);
    return list.isEmpty ? null : list.first;
  }

  static List<Campaign> _toCampaigns(dynamic rows) => (rows as List)
      .cast<Map<String, dynamic>>()
      .map(Campaign.fromMap)
      .toList();

  // ------------------------------------------------------------------ detail
  static Future<List<DonorEntry>> fetchDonors(
    String campaignId, {
    int limit = 50,
  }) async {
    final rows = await _db.rpc(
      'list_campaign_donors',
      params: {'p_campaign_id': campaignId, 'p_limit': limit},
    );
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(DonorEntry.fromMap)
        .toList();
  }

  static Future<List<CampaignUpdate>> fetchUpdates(String campaignId) async {
    final rows = await _db
        .from('campaign_updates')
        .select('title, content, image_url, created_at')
        .eq('campaign_id', campaignId)
        .eq('is_published', true)
        .order('created_at', ascending: false);
    return rows.map(CampaignUpdate.fromMap).toList();
  }

  static Future<FundReport?> fetchReport(String campaignId) async {
    final row = await _db
        .from('fund_usage_reports')
        .select(
          'description, total_used, created_at, report_evidence(file_path)',
        )
        .eq('campaign_id', campaignId)
        .maybeSingle();
    if (row == null) return null;
    final evidence = (row['report_evidence'] as List? ?? const [])
        .map(
          (e) => StorageService.publicUrl(
            Buckets.reportEvidence,
            e['file_path'] as String,
          ),
        )
        .toList();
    return FundReport(
      description: row['description'] as String,
      totalUsed: asInt(row['total_used']),
      evidenceUrls: evidence,
      createdAt: asDate(row['created_at']),
    );
  }

  static Future<CampaignReview?> fetchLatestReview(String campaignId) async {
    final row = await _db
        .from('campaign_reviews')
        .select('decision, reason, reviewed_at')
        .eq('campaign_id', campaignId)
        .order('reviewed_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : CampaignReview.fromMap(row);
  }

  // ------------------------------------------------------------------ profil & rekening
  static Future<PayoutInfo> fetchMyProfile() async {
    final row = await _db
        .from('profiles')
        .select(
          'full_name, payout_method, bank_name, account_number, account_holder, role',
        )
        .eq('id', _uid)
        .single();
    return PayoutInfo.fromMap(row);
  }

  static Future<void> updatePayout({
    required String fullName,
    required String payoutMethod,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    await _db
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'payout_method': payoutMethod,
          'bank_name': bankName.trim(),
          'account_number': accountNumber.trim(),
          'account_holder': accountHolder.trim(),
        })
        .eq('id', _uid);
  }

  // ------------------------------------------------------------------ pengajuan (F05)
  /// Urutan sesuai aturan database:
  /// sampul -> draf kampanye -> data penerima -> dokumen -> submit_campaign.
  /// Jika salah satu langkah gagal, draf dihapus supaya tidak menggantung.
  static Future<String> submitCampaign(CampaignDraft d) async {
    final uid = _uid;
    final uploaded = <({String bucket, String path})>[];
    String? campaignId;

    try {
      String? coverUrl;
      if (d.cover != null) {
        final path = await StorageService.upload(Buckets.covers, uid, d.cover!);
        uploaded.add((bucket: Buckets.covers, path: path));
        coverUrl = StorageService.publicUrl(Buckets.covers, path);
      }

      final campaign = await _db
          .from('campaigns')
          .insert({
            'category_id': d.categoryId,
            'title': d.title.trim(),
            'story': d.story.trim(),
            'cover_image_url': coverUrl,
            'target_amount': d.targetAmount,
            'deadline': d.deadline.toUtc().toIso8601String(),
          })
          .select('id')
          .single();
      campaignId = campaign['id'] as String;

      await _db.from('campaign_beneficiaries').insert({
        'campaign_id': campaignId,
        'recipient_type': d.recipientType.trim(),
        'recipient_name': d.recipientName.trim(),
        'identity_number': _blankToNull(d.identityNumber),
        'contact_phone': _blankToNull(d.contactPhone),
        'is_self': d.isSelf,
      });

      final docs = [
        ...d.documents,
        if (!d.isSelf && d.consent != null) (type: 'consent', file: d.consent!),
      ];
      for (final doc in docs) {
        final path = await StorageService.upload(
          Buckets.documents,
          '$uid/$campaignId',
          doc.file,
        );
        uploaded.add((bucket: Buckets.documents, path: path));
        await _db.from('campaign_documents').insert({
          'campaign_id': campaignId,
          'document_type': doc.type,
          'file_path': path,
          'file_name': doc.file.name,
        });
      }

      await _db.rpc('submit_campaign', params: {'p_campaign_id': campaignId});
      return campaignId;
    } catch (_) {
      // Bersihkan draf dan berkas yang sempat terunggah.
      if (campaignId != null) {
        try {
          await _db.from('campaigns').delete().eq('id', campaignId);
        } catch (_) {}
      }
      for (final f in uploaded) {
        try {
          await StorageService.remove(f.bucket, [f.path]);
        } catch (_) {}
      }
      rethrow;
    }
  }

  // ------------------------------------------------------------------ pencairan (F11)
  static Future<Disbursement?> fetchDisbursement(String campaignId) async {
    final row = await _db
        .from('disbursements')
        .select()
        .eq('campaign_id', campaignId)
        .maybeSingle();
    return row == null ? null : Disbursement.fromMap(row);
  }

  static Future<void> requestDisbursement(String campaignId) async {
    await _db.rpc(
      'request_disbursement',
      params: {'p_campaign_id': campaignId},
    );
  }

  // ------------------------------------------------------------------ laporan (F12)
  static Future<void> submitReport({
    required String campaignId,
    required String description,
    required int totalUsed,
    required List<PickedFile> evidence,
  }) async {
    if (evidence.isEmpty)
      throw const ItsbisaException('Tambahkan minimal satu bukti');
    final uid = _uid;
    final paths = <String>[];
    try {
      for (final file in evidence) {
        paths.add(
          await StorageService.upload(
            Buckets.reportEvidence,
            '$uid/$campaignId',
            file,
          ),
        );
      }
      await _db.rpc(
        'submit_fund_report',
        params: {
          'p_campaign_id': campaignId,
          'p_description': description.trim(),
          'p_total_used': totalUsed,
          'p_evidence_paths': paths,
        },
      );
    } catch (_) {
      try {
        await StorageService.remove(Buckets.reportEvidence, paths);
      } catch (_) {}
      rethrow;
    }
  }

  static String? _blankToNull(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();
}
