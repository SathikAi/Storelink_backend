import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _langKey = 'selected_language';

  String _currentLanguage = 'English';

  String get currentLanguage => _currentLanguage;

  LocaleProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final savedLang = await _storage.read(key: _langKey);
    if (savedLang != null) {
      _currentLanguage = savedLang;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String language) async {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      await _storage.write(key: _langKey, value: language);
      notifyListeners();
    }
  }
}
