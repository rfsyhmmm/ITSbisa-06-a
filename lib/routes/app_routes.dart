import 'package:flutter/material.dart';

import 'package:itsbisa/models/campaign.dart';
import 'package:itsbisa/screens/auth/auth_gate.dart';
import 'package:itsbisa/screens/campaign/campaign_detail_page.dart';
import 'package:itsbisa/screens/campaign/donation_form_page.dart';
import 'package:itsbisa/screens/campaign/submit_campaign_page.dart';
import 'package:itsbisa/screens/notifikasi/notifications_page.dart';
import 'package:itsbisa/screens/splash/splash_page.dart';

/// Semua nama rute ITSbisa ada di sini.
/// Cara pindah halaman: Navigator.pushNamed(context, AppRoutes.notifications);
class AppRoutes {
  AppRoutes._();

  static const splash = '/'; // halaman pertama saat aplikasi dibuka
  static const authGate = '/masuk'; // login, atau Home kalau sudah login
  static const notifications = '/notifikasi';
  static const submitCampaign = '/kampanye/ajukan';

  // Rute yang butuh data kampanye (dikirim lewat `arguments`).
  static const campaignDetail = '/kampanye/detail';
  static const donationForm = '/donasi/form';

  /// Rute tanpa data tambahan.
  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashPage(),
        authGate: (_) => const AuthGate(),
        notifications: (_) => const NotificationsPage(),
        submitCampaign: (_) => const SubmitCampaignPage(),
      };

  /// Rute yang membawa objek Campaign, contoh:
  /// Navigator.pushNamed(context, AppRoutes.campaignDetail, arguments: campaign);
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case campaignDetail:
        if (args is Campaign) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => CampaignDetailPage(campaign: args),
          );
        }
        break;
      case donationForm:
        if (args is Campaign) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => DonationFormPage(campaign: args),
          );
        }
        break;
    }
    return null;
  }
}
