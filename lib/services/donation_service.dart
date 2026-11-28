import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:itsbisa/models/donation.dart';
import 'package:itsbisa/services/supabase_errors.dart';

/// Donasi dan pembayaran Midtrans (F07, F08).
class DonationService {
  DonationService._();

  static const minAmount = 5000;

  static SupabaseClient get _db => Supabase.instance.client;

  /// Membuat donasi lewat Edge Function create-donation.
  /// Edge Function memanggil RPC create_donation lalu Midtrans Snap.
  static Future<DonationCheckout> createDonation({
    required String campaignId,
    required int amount,
    required bool isAnonymous,
    String? message,
  }) async {
    if (amount < minAmount) {
      throw const ItsbisaException('Nominal donasi minimal Rp5.000');
    }
    final res = await _db.functions.invoke(
      'create-donation',
      body: {
        'campaign_id': campaignId,
        'amount': amount,
        'is_anonymous': isAnonymous,
        'message': (message ?? '').trim().isEmpty ? null : message!.trim(),
      },
    );
    final data = res.data;
    if (data is! Map || data['redirect_url'] == null) {
      throw ItsbisaException(
        data is Map && data['error'] is String
            ? data['error'] as String
            : 'Gagal membuat transaksi',
      );
    }
    return DonationCheckout(
      donationId: data['donation_id'] as String,
      orderId: data['order_id'] as String,
      redirectUrl: data['redirect_url'] as String,
    );
  }

  /// Membuka halaman pembayaran Midtrans Snap (Custom Tab / in-app browser).
  static Future<void> openPayment(String redirectUrl) async {
    final ok = await launchUrl(
      Uri.parse(redirectUrl),
      mode: LaunchMode.inAppBrowserView,
    );
    if (!ok)
      throw const ItsbisaException('Halaman pembayaran tidak dapat dibuka');
  }

  /// Status donasi terbaru (pending, paid, failed, expired, refunded).
  static Future<String> fetchStatus(String donationId) async {
    final row = await _db
        .from('donations')
        .select('status')
        .eq('id', donationId)
        .single();
    return row['status'] as String;
  }

  static Future<Donation> fetchDonation(String donationId) async {
    final row = await _db
        .from('donations')
        .select(_select)
        .eq('id', donationId)
        .single();
    return Donation.fromMap(row);
  }

  /// Riwayat donasi milik pengguna (F08).
  static Future<List<Donation>> fetchMyDonations() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _db
        .from('donations')
        .select(_select)
        .eq('donor_id', uid)
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map(Donation.fromMap).toList();
  }

  // Kolom payment_transactions dibatasi grant: jangan pakai `*` untuk tabel itu.
  static const _select =
      'id, campaign_id, amount, status, is_anonymous, message, paid_at, created_at, '
      'campaigns(title, cover_image_url), '
      'payment_transactions(order_id, payment_type, status, redirect_url, expiry_time)';
}
