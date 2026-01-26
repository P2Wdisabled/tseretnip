import 'dart:convert';

import 'package:flutter/services.dart';

class AppConfig {
  AppConfig._();

  static String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  static String supabaseAnonKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static String supabaseDbPassword = const String.fromEnvironment(
    'SUPABASE_DB_PASSWORD',
  );

  static Future<void> load() async {
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      return;
    }

    final configString = await rootBundle.loadString('config.json');
    final json = jsonDecode(configString) as Map<String, dynamic>;

    supabaseUrl = (json['SUPABASE_URL'] ?? '') as String;
    supabaseAnonKey = (json['SUPABASE_ANON_KEY'] ?? '') as String;
    supabaseDbPassword = (json['SUPABASE_DB_PASSWORD'] ?? '') as String;
  }
}
