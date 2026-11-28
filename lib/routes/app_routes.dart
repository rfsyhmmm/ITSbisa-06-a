import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/models/campaign_extras.dart';
import 'package:itsbisa/models/donation.dart';
import 'package:itsbisa/screens/admin/admin_decision_page.dart';
import 'package:itsbisa/screens/admin/admin_disbursement_review_page.dart';
import 'package:itsbisa/screens/admin/admin_page.dart';
import 'package:itsbisa/screens/admin/admin_review_page.dart';
import 'package:itsbisa/screens/auth/auth_gate.dart';
import 'package:itsbisa/screens/campaign/campaign_detail_page.dart';
import 'package:itsbisa/screens/campaign/create_campaign_type_page.dart';
import 'package:itsbisa/screens/campaign/disbursement_page.dart';
import 'package:itsbisa/screens/campaign/donation_form_page.dart';
import 'package:itsbisa/screens/campaign/donation_success_page.dart';
import 'package:itsbisa/screens/campaign/fund_report_page.dart';
import 'package:itsbisa/screens/campaign/fund_report_preview_page.dart';
import 'package:itsbisa/screens/campaign/manage_campaign_page.dart';
import 'package:itsbisa/screens/campaign/my_campaigns_page.dart';
import 'package:itsbisa/screens/campaign/payment_status_page.dart';
import 'package:itsbisa/screens/campaign/submit_campaign_page.dart';
import 'package:itsbisa/screens/campaign/submit_review_page.dart';
import 'package:itsbisa/screens/notifikasi/notifications_page.dart';
import 'package:itsbisa/screens/riwayat/donation_detail_page.dart';
import 'package:itsbisa/screens/splash/splash_page.dart';

/// Semua nama rute ITSbisa ada di sini.
/// Cara pindah halaman: Navigator.pushNamed(context, AppRoutes.notifications);
/// Kode Figma di komentar = frame di halaman "ITSBisa_sandbox_codex w13".
class AppRoutes {
  AppRoutes._();

  static const splash = '/'; // halaman pertama saat aplikasi dibuka
  static const authGate = '/masuk'; // login, atau Home kalau sudah login
  static const notifications = '/notifikasi';

  // Penggalang (Proses A)
  static const createCampaign = '/kampanye/baru'; // S03.01 pilih jenis bantuan
  static const submitCampaign = '/kampanye/ajukan'; // S03.02 informasi kampanye
  static const submitReview =
      '/kampanye/ajukan/tinjau'; // S03.06 (SubmitReviewArgs)
  static const myCampaigns = '/kampanye/saya'; // S03.08
  static const manageCampaign =
      '/kampanye/kelola'; // S03.09 + S07.04 (Campaign)
  static const disbursement =
      '/kampanye/pencairan'; // S08.01 / S08.02 (Campaign)
  static const fundReport = '/kampanye/laporan'; // S08.06 (Campaign)
  static const fundReportPreview =
      '/kampanye/laporan/tinjau'; // S08.07 (ReportDraft)

  // Donatur (Proses B)
  static const campaignDetail = '/kampanye/detail'; // (Campaign)
  static const donationForm = '/donasi/form'; // S05.01 (Campaign)
  static const paymentStatus = '/donasi/status'; // S05.04 (PaymentArgs)
  static const donationSuccess = '/donasi/berhasil'; // 101:5873 (PaymentArgs)
  static const donationDetail = '/donasi/detail'; // S05.07 (DonationRef)

  // Admin
  static const admin = '/admin'; // S04.01
  static const adminCampaignQueue = '/admin/kampanye'; // S04.02
  static const adminReview = '/admin/kampanye/tinjau'; // S04.03 (Campaign)
  static const adminDecision =
      '/admin/kampanye/keputusan'; // S04.05 (DecisionArgs)
  static const adminDisbursementQueue = '/admin/pencairan'; // S08.03
  static const adminDisbursementReview =
      '/admin/pencairan/periksa'; // S08.04 (Disbursement)

  /// Rute tanpa data tambahan.
  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashPage(),
    authGate: (_) => const AuthGate(),
    notifications: (_) => const NotificationsPage(),
    createCampaign: (_) => const CreateCampaignTypePage(),
    submitCampaign: (_) => const SubmitCampaignPage(),
    myCampaigns: (_) => const MyCampaignsPage(),
    admin: (_) => const AdminPage(),
    adminCampaignQueue: (_) => const AdminCampaignQueuePage(),
    adminDisbursementQueue: (_) => const AdminDisbursementQueuePage(),
  };

  /// Rute yang membawa objek lewat `arguments`, contoh:
  /// Navigator.pushNamed(context, AppRoutes.campaignDetail, arguments: campaign);
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget? page = switch ((settings.name, args)) {
      (campaignDetail, Campaign c) => CampaignDetailPage(campaign: c),
      (donationForm, Campaign c) => DonationFormPage(campaign: c),
      (manageCampaign, Campaign c) => ManageCampaignPage(campaign: c),
      (disbursement, Campaign c) => DisbursementPage(campaign: c),
      (fundReport, Campaign c) => FundReportPage(campaign: c),
      (adminReview, Campaign c) => AdminReviewPage(campaign: c),
      (paymentStatus, PaymentArgs a) => PaymentStatusPage(args: a),
      (donationSuccess, PaymentArgs a) => DonationSuccessPage(args: a),
      (donationDetail, DonationRef r) => DonationDetailPage(donationId: r.id),
      (submitReview, SubmitReviewArgs a) => SubmitReviewPage(args: a),
      (fundReportPreview, ReportDraft d) => FundReportPreviewPage(draft: d),
      (adminDecision, DecisionArgs a) => AdminDecisionPage(args: a),
      (adminDisbursementReview, Disbursement d) => AdminDisbursementReviewPage(
        disbursement: d,
      ),
      _ => null,
    };
    if (page == null) return null;
    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }
}
