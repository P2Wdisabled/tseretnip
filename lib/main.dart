import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tseretnip/pages/upload_photos_page.dart';
import 'package:tseretnip/services/core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.load();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UploadPhotosPage(),
    );
  }
}
