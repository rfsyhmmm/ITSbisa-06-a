import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:itsbisa/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Koneksi Supabase dari Rafsyah, jangan diubah.
  await Supabase.initialize(
    url: 'https://qiapjprevekcaedrvqfk.supabase.co',
    publishableKey: 'sb_publishable_PCcsY19B8SWNajYdclRvUg_h1hKMoi9',
  );
  runApp(const MyApp());
}
