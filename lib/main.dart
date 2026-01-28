import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tseretnip/pages/upload_photos_page.dart';
import 'package:tseretnip/services/core/config/app_config.dart';
import 'package:tseretnip/pages/auth.dart';
import 'package:tseretnip/pages/home.dart' as home_page;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return AdaptiveTheme(
      light: ThemeData(
       brightness: Brightness.light,
      ),
      dark: ThemeData(
       brightness: Brightness.dark,
      ),
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => MaterialApp(
      title: 'Tseretnip',
      theme: theme,
      darkTheme: darkTheme,
      home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // L'utilisateur est connecté, afficher la page d'accueil
          return const home_page.HomePage();
        } else {
          // L'utilisateur n'est pas connecté, afficher la page d'authentification
          return const AuthPage();
        }
      },
    );
  }
}
