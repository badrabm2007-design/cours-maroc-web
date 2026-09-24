import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

class LanguageOption {
  final String code;
  final String label;
  final String nativeLabel;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.flag,
  });
}

class AppLanguageService extends ChangeNotifier {
  static const String _prefKey = 'app_selected_language';

  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(
      code: 'fr',
      label: 'Français',
      nativeLabel: 'Français',
      flag: '🇫🇷',
    ),
    LanguageOption(
      code: 'ar',
      label: 'Arabe',
      nativeLabel: 'العربية',
      flag: '🇲🇦',
    ),
    LanguageOption(
      code: 'en',
      label: 'Anglais',
      nativeLabel: 'English',
      flag: '🇬🇧',
    ),
  ];

  String _currentLanguageCode = 'fr';
  bool _initialized = false;

  bool get isInitialized => _initialized;
  String get currentLanguageCode => _currentLanguageCode;
  Locale get currentLocale => Locale(_currentLanguageCode);
  bool get isArabic => _currentLanguageCode == 'ar';
  bool get isRTL => _currentLanguageCode == 'ar';

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_prefKey);

      if (savedLang != null && ['fr', 'ar', 'en'].contains(savedLang)) {
        _currentLanguageCode = savedLang;
      } else {
        // Auto-detect from system device locale
        final deviceLocale = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
        if (deviceLocale.startsWith('ar')) {
          _currentLanguageCode = 'ar';
        } else if (deviceLocale.startsWith('en')) {
          _currentLanguageCode = 'en';
        } else {
          _currentLanguageCode = 'fr';
        }
      }
    } catch (e) {
      debugPrint('Error initializing AppLanguageService: $e');
      _currentLanguageCode = 'fr';
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String langCode) async {
    if (!['fr', 'ar', 'en'].contains(langCode)) return;
    if (_currentLanguageCode == langCode) return;

    _currentLanguageCode = langCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  String exportData() => _currentLanguageCode;

  Future<void> importCloudData(String? langCode) async {
    if (langCode != null &&
        ['fr', 'ar', 'en'].contains(langCode) &&
        _currentLanguageCode != langCode) {
      await setLanguage(langCode);
    }
  }

  String tr(String key) {
    return AppStrings.get(key, _currentLanguageCode);
  }
}
