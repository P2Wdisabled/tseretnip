import 'package:flutter/material.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();

  factory LanguageService() {
    return _instance;
  }

  LanguageService._internal();

  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  void changeLocale(Locale newLocale) {
    if (_currentLocale == newLocale) return;
    _currentLocale = newLocale;
    notifyListeners();
  }
}
