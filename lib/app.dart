import 'package:flutter/material.dart';

import 'package:itsbisa/routes/app_routes.dart';
import 'package:itsbisa/theme/app_theme.dart';

/// Akar aplikasi: tema dan daftar rute diatur di sini.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ITSbisa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
