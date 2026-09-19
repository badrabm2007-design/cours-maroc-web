import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TranslationSource { online, offlineLexicon, cache }

class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final TranslationSource source;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.source,
  });
}

class TranslationService {
  static final TranslationService instance = TranslationService._internal();
  TranslationService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 2500),
      receiveTimeout: const Duration(milliseconds: 2500),
    ),
  );

  static const String _cachePrefix = 'trans_cache_';
  final Map<String, String> _memoryCache = {};

  /// Determine default source language based on subject name
  static String detectSourceLangForSubject(String subjectName) {
    final lower = subjectName.toLowerCase();
    if (lower.contains('anglais') || lower.contains('english')) {
      return 'en';
    }
    return 'fr';
  }

  /// Translate a given text to target language (default 'ar')
  Future<TranslationResult> translate({
    required String text,
    String? subjectName,
    String? preferredSourceLang,
    String targetLang = 'ar',
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return TranslationResult(
        originalText: text,
        translatedText: '',
        sourceLang: 'auto',
        targetLang: targetLang,
        source: TranslationSource.cache,
      );
    }

    final sourceLang = preferredSourceLang ??
        (subjectName != null ? detectSourceLangForSubject(subjectName) : 'auto');

    final cacheKey = '$sourceLang->$targetLang:${cleanText.toLowerCase()}';

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      return TranslationResult(
        originalText: cleanText,
        translatedText: _memoryCache[cacheKey]!,
        sourceLang: sourceLang,
        targetLang: targetLang,
        source: TranslationSource.cache,
      );
    }

    // 2. Check local persistent cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('$_cachePrefix$cacheKey');
      if (saved != null && saved.isNotEmpty) {
        _memoryCache[cacheKey] = saved;
        return TranslationResult(
          originalText: cleanText,
          translatedText: saved,
          sourceLang: sourceLang,
          targetLang: targetLang,
          source: TranslationSource.cache,
        );
      }
    } catch (_) {}

    // 3. Try Online Translation (Google Translate for desktop/mobile, skipped on Web due to browser CORS)
    if (!kIsWeb) {
      try {
        final result = await _translateOnlineGoogle(cleanText, sourceLang, targetLang);
        if (result != null && result.isNotEmpty) {
          _saveToCache(cacheKey, result);
          return TranslationResult(
            originalText: cleanText,
            translatedText: result,
            sourceLang: sourceLang,
            targetLang: targetLang,
            source: TranslationSource.online,
          );
        }
      } catch (e) {
        debugPrint('Google Translate online error: $e');
      }
    }

    // 4. Try Online Translation (MyMemory API - supports Web CORS)
    try {
      final result = await _translateOnlineMyMemory(cleanText, sourceLang, targetLang);
      if (result != null && result.isNotEmpty) {
        _saveToCache(cacheKey, result);
        return TranslationResult(
          originalText: cleanText,
          translatedText: result,
          sourceLang: sourceLang,
          targetLang: targetLang,
          source: TranslationSource.online,
        );
      }
    } catch (e) {
      debugPrint('MyMemory fallback online error: $e');
    }

    // 5. Offline Fallback: Embedded Moroccan Curriculum Lexicon
    final offlineMatch = _lookupOfflineLexicon(cleanText, sourceLang, targetLang);
    if (offlineMatch != null) {
      _saveToCache(cacheKey, offlineMatch);
      return TranslationResult(
        originalText: cleanText,
        translatedText: offlineMatch,
        sourceLang: sourceLang,
        targetLang: targetLang,
        source: TranslationSource.offlineLexicon,
      );
    }

    // Default if completely offline and not in dictionary
    return TranslationResult(
      originalText: cleanText,
      translatedText: cleanText,
      sourceLang: sourceLang,
      targetLang: targetLang,
      source: TranslationSource.offlineLexicon,
    );
  }

  Future<String?> _translateOnlineGoogle(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final sl = sourceLang == 'auto' ? 'auto' : sourceLang;
    final url =
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$sl&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}';

    final response = await _dio.get(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final dynamic decoded = json.decode(response.data.toString());
      if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
        final buffer = StringBuffer();
        for (final item in decoded[0]) {
          if (item is List && item.isNotEmpty) {
            buffer.write(item[0].toString());
          }
        }
        final translation = buffer.toString().trim();
        if (translation.isNotEmpty) {
          return translation;
        }
      }
    }
    return null;
  }

  Future<String?> _translateOnlineMyMemory(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final from = sourceLang == 'auto' ? 'fr' : sourceLang;
    final langpair = '$from|$targetLang';
    final url =
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$langpair';

    final response = await _dio.get(url);
    if (response.statusCode == 200 && response.data != null) {
      final dynamic data = response.data is String
          ? json.decode(response.data as String)
          : response.data;
      if (data is Map && data['responseData'] != null) {
        final translated = data['responseData']['translatedText'] as String?;
        if (translated != null &&
            translated.isNotEmpty &&
            !translated.toUpperCase().contains('MYMEMORY WARNING')) {
          return translated.trim();
        }
      }
    }
    return null;
  }

  void _saveToCache(String key, String translation) async {
    _memoryCache[key] = translation;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$key', translation);
    } catch (_) {}
  }

  /// High School Moroccan Curriculum Offline Lexicon (French-Arabic & English-Arabic)
  String? _lookupOfflineLexicon(String text, String sourceLang, String targetLang) {
    final query = text.toLowerCase().trim();

    // English -> Arabic Lexicon (Moroccan Bac English Curriculum)
    if (sourceLang == 'en' || detectSourceLangForSubject(sourceLang) == 'en') {
      if (_englishArabicLexicon.containsKey(query)) {
        return _englishArabicLexicon[query];
      }
      for (final entry in _englishArabicLexicon.entries) {
        if (query.contains(entry.key) || entry.key.contains(query)) {
          return entry.value;
        }
      }
    }

    // French -> Arabic Lexicon (Maths, PC, SVT, Philo, etc.)
    if (_frenchArabicLexicon.containsKey(query)) {
      return _frenchArabicLexicon[query];
    }
    for (final entry in _frenchArabicLexicon.entries) {
      if (query.contains(entry.key) || entry.key.contains(query)) {
        return entry.value;
      }
    }

    return null;
  }

  static final Map<String, String> _englishArabicLexicon = {
    // Bac English Units & Common Vocabulary
    'education': 'التعليم / التربية',
    'culture': 'الثقافة',
    'citizenship': 'المواطنة',
    'sustainable development': 'التنمية المستدامة',
    'development': 'التنمية / التطوير',
    'brain drain': 'هجرة الأدمغة',
    'human rights': 'حقوق الإنسان',
    'gender equality': 'المساواة بين الجنسين',
    'technology': 'التكنولوجيا',
    'humour': 'الدعابة / الفكاهة',
    'formal education': 'التعليم النظامي',
    'informal education': 'التعليم غير النظامي',
    'non-formal education': 'التعليم غير الرسمي',
    'literacy': 'محو الأمية / معرفة القراءة والكتابة',
    'illiteracy': 'الأمية',
    'achievement': 'إنجاز / نجاح',
    'ambition': 'طموح',
    'community': 'المجتمع المحلي',
    'volunteer': 'متطوع / يتطوع',
    'diversity': 'التنوع',
    'tolerance': 'التسامح',
    'values': 'القيم',
    'environment': 'البيئة',
    'pollution': 'التلوث',
    'global warming': 'الاحتباس الحراري',
    'renewable energy': 'الطاقة المتجددة',
    'poverty': 'الفقر',
    'employment': 'التشغيل / العمل',
    'unemployment': 'البطالة',
    'empowerment': 'التمكين',
    'opportunity': 'فرصة',
    'challenge': 'تحدي',
    'solution': 'حل',
    'opinion': 'رأي',
    'agreement': 'موافقة / اتفاق',
    'disagreement': 'عدم الاتفاق / معارضة',
    'purpose': 'الهدف / الغاية',
    'cause': 'السبب',
    'effect': 'النتيجة / الأثر',
    'consequence': 'النتيجة / العاقبة',
    'contrast': 'التعارض / التناقض',
    'conclusion': 'الخاتمة / الاستنتاج',
    'introduction': 'المقدمة',
    'summary': 'تلخيص',
    'skills': 'مهارات',
    'knowledge': 'المعرفة',
  };

  static final Map<String, String> _frenchArabicLexicon = {
    // Mathématiques
    'dérivée': 'مشتقة',
    'dérivation': 'الاشتقاق',
    'dérivabilité': 'قابلية الاشتقاق',
    'intégrale': 'تكامل',
    'intégration': 'التكامل',
    'continuité': 'الاتصال',
    'fonction': 'دالة',
    'suite': 'متتالية',
    'limite': 'نهاية',
    'théorème': 'مبرهنة',
    'propriété': 'خاصية',
    'asymptote': 'مقارِب',
    'tangente': 'مماس',
    'intervalle': 'مجال',
    'domaine de définition': 'مجموعة التعريف',
    'probabilité': 'الاحتمالات',
    'nombre complexe': 'عدد عقدي',
    'équation différentielle': 'معادلة تفاضلية',
    'vecteur': 'متجهة',
    'matrice': 'مصفوفة',
    'produit scalaire': 'جداء سلمي',
    'produit vectoriel': 'جداء متجهي',

    // Physique - Chimie
    'onde': 'موجة',
    'onde mécanique': 'موجة ميكانيكية',
    'onde lumineuse': 'موجة ضوئية',
    'longueur d\'onde': 'طول الموجة',
    'fréquence': 'تردد',
    'période': 'دور',
    'diffraction': 'حيود',
    'décroissance radioactive': 'التناقص الإشعاعي',
    'radioactivité': 'النشاط الإشعاعي',
    'demi-vie': 'عمر النصف',
    'noyau': 'نواة',
    'fission': 'انشطار',
    'fusion': 'اندماج',
    'circuit': 'دارة كهربائية',
    'condensateur': 'مكثف',
    'bobine': 'وشيعة',
    'oscillations': 'تذبذبات',
    'loi de newton': 'قانون نيوتن',
    'vitesse': 'سرعة',
    'accélération': 'تسارع',
    'trajectoire': 'مسار',
    'énergie cinétique': 'طاقة حركية',
    'énergie potentielle': 'طاقة وضع',
    'énergie mécanique': 'طاقة ميكانيكية',
    'réaction chimique': 'تفاعل كيميائي',
    'avancement': 'تقدم التفاعل',
    'tableau d\'avancement': 'جدول التقدم',
    'acide': 'حمض',
    'base': 'قاعدة',
    'ph': 'الأس الهيدروجيني',
    'dosage': 'معايرة',
    'équivalence': 'تكافؤ',
    'estérification': 'أسترة',
    'hydrolyse': 'حلمأة',
    'oxydant': 'مؤكسد',
    'réducteur': 'مختزل',
    'oxydoréduction': 'أكسدة واختزال',

    // SVT
    'cellule': 'خلية',
    'adn': 'حمض نووي ريبوزي منقوص الأكسجين (ADN)',
    'arn': 'حمض نووي ريبوزي (ARN)',
    'gène': 'مورثة',
    'allèle': 'حليل',
    'mutation': 'طفرة',
    'chromosomes': 'صبغيات',
    'mitose': 'انقسام غير مباشر',
    'méiose': 'انقسام اختزالي',
    'brassage': 'تخليط صبغي',
    'immunité': 'المناعة',
    'anticorps': 'مضاد أجسام',
    'antigène': 'مولد المضاد',
    'tectonique des plaques': 'تكتونية الصفائح',
    'séisme': 'زلزال',
    'volcanisme': 'بركانية',
    'roche': 'صخرة',
    'magma': 'صهيرة',
    'métamorphisme': 'تحول',

    // Philosophie & Général
    'conscience': 'الوعي',
    'inconscient': 'اللاوعي',
    'personne': 'الشخص',
    'sujet': 'الذات / الموضوع',
    'liberté': 'الحرية',
    'devoir': 'الواجب',
    'société': 'المجتمع',
    'état': 'الدولة',
    'justice': 'العدالة',
    'droit': 'الحق',
    'vérité': 'الحقيقة',
    'théorie': 'النظرية',
    'expérience': 'التجربة',
    'bonheur': 'السعادة',
    'morale': 'الأخلاق',
    'définition': 'تعريف',
    'remarque': 'ملاحظة',
    'exemple': 'مثال',
    'exercice': 'تمرين',
    'corrigé': 'تصحيح',
    'solution': 'حل',
  };
}
