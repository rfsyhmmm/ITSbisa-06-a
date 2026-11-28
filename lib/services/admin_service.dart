import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/services/file_pick_service.dart';
import 'package:itsbisa/services/storage_service.dart';

/// Dokumen pendukung yang diperiksa admin.
class CampaignDocument {
  const CampaignDocument({
    required this.type,
    required this.fileName,
    required this.url,
  });

  final String type;
  final String fileName;
  final String url; // signed URL, berlaku 1 jam
}

/// Data penerima bantuan.
class Beneficiary {
  const Beneficiary({
    required this.recipientType,
    required this.recipientName,
    required this.isSelf,
    this.identityNumber,
    this.contactPhone,
  });

  final String recipientType;
  final String recipientName;
  final bool isSelf;
  final String? identityNumber;
  final String? contactPhone;
}

/// Bagian admin yang dibutuhkan alur kampanye: verifikasi (F06) dan pencairan (F11).
class AdminService {
  AdminService._();

  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<Campaign>> fetchPendingCampaigns() async {
    final rows = await _db.rpc(
      'get_campaigns',
      params: {
        'p_statuses': [CampaignStatus.pendingReview],
        'p_limit': 100,
      },
    );
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Campaign.fromMap)
        .toList();
  }

  static Future<Beneficiary?> fetchBeneficiary(String campaignId) async {
    final row = await _db
        .from('campaign_beneficiaries')
        .select()
        .eq('campaign_id', campaignId)
        .maybeSingle();
    if (row == null) return null;
    return Beneficiary(
      recipientType: row['recipient_type'] as String,
      recipientName: row['recipient_name'] as String,
      isSelf: row['is_self'] as bool,
      identityNumber: row['identity_number'] as String?,
      contactPhone: row['contact_phone'] as String?,
    );
  }

  static Future<List<CampaignDocument>> fetchDocuments(
    String campaignId,
  ) async {
    final rows = await _db
        .from('campaign_documents')
        .select('document_type, file_name, file_path')
        .eq('campaign_id', campaignId)
        .order('created_at');
    final docs = <CampaignDocument>[];
    for (final r in rows) {
      final url = await StorageService.signedUrl(
        Buckets.documents,
        r['file_path'] as String,
      );
      docs.add(
        CampaignDocument(
          type: r['document_type'] as String,
          fileName: r['file_name'] as String,
          url: url,
        ),
      );
    }
    return docs;
  }

  static Future<void> reviewCampaign(
    String campaignId, {
    required bool approve,
    String? reason,
  }) async {
    await _db.rpc(
      'review_campaign',
      params: {
        'p_campaign_id': campaignId,
        'p_decision': approve ? 'approved' : 'rejected',
        'p_reason': reason,
      },
    );
  }

  static Future<List<Disbursement>> fetchRequestedDisbursements() async {
    final rows = await _db
        .from('disbursements')
        .select('*, campaigns(title, collected_amount)')
        .eq('status', 'requested')
        .order('requested_at');
    return rows.map(Disbursement.fromMap).toList();
  }

  /// Setujui: unggah bukti transfer ke bucket privat lalu tandai dibayar.
  static Future<void> approveDisbursement(
    Disbursement d,
    PickedFile proof, {
    String? note,
  }) async {
    final path = await StorageService.upload(
      Buckets.transferProofs,
      d.campaignId,
      proof,
    );
    await _db.rpc(
      'process_disbursement',
      params: {
        'p_disbursement_id': d.id,
        'p_approve': true,
        'p_admin_note': note,
        'p_transfer_proof_url': path,
      },
    );
  }

  /// Ringkasan untuk dashboard admin.
  static Future<(int pendingCampaigns, int requestedDisbursements)>
  fetchCounts() async {
    final (campaigns, disbursements) = await (
      fetchPendingCampaigns(),
      fetchRequestedDisbursements(),
    ).wait;
    return (campaigns.length, disbursements.length);
  }

  static Future<void> requestRevision(Disbursement d, String note) async {
    await _db.rpc(
      'process_disbursement',
      params: {
        'p_disbursement_id': d.id,
        'p_approve': false,
        'p_admin_note': note,
      },
    );
  }
}
