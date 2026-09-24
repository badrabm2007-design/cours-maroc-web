import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/curriculum_models.dart';

class HistoryEntry {
  final String docId;
  final String title;
  final String subjectName;
  final String category;
  final DateTime viewedAt;

  HistoryEntry({
    required this.docId,
    required this.title,
    required this.subjectName,
    required this.category,
    required this.viewedAt,
  });

  Map<String, dynamic> toJson() => {
        'docId': docId,
        'title': title,
        'subjectName': subjectName,
        'category': category,
        'viewedAt': viewedAt.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        docId: json['docId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subjectName: json['subjectName'] as String? ?? '',
        category: json['category'] as String? ?? '',
        viewedAt: DateTime.tryParse(json['viewedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class UserProfileService extends ChangeNotifier {
  static const String _keyHasSelectedGrade = 'user_has_selected_grade_v1';
  static const String _keyLevelId = 'user_saved_level_id_v1';
  static const String _keyBranchId = 'user_saved_branch_id_v1';
  static const String _keyHistory = 'user_reading_history_v1';
  static const String _keySubjectStats = 'user_subject_stats_v1';
  static const String _keyCategoryStats = 'user_category_stats_v1';
  static const String _keyLastLessons = 'user_last_lessons_v1';
  static const String _keyBannerClicks = 'user_banner_clicks_v1';

  bool _initialized = false;
  bool _hasSelectedGrade = false;
  String _savedLevelId = '2eme-bac';
  String _savedBranchId = 'sciences-physiques';

  final List<HistoryEntry> _history = [];
  final Map<String, int> _subjectConsultationCounts = {};
  final Map<String, int> _categoryStats = {};
  final Map<String, String> _lastStudiedLessons = {};
  final Map<String, int> _bannerClicks = {};

  bool get isInitialized => _initialized;
  bool get hasSelectedGrade => _hasSelectedGrade;
  String get savedLevelId => _savedLevelId;
  String get savedBranchId => _savedBranchId;
  List<HistoryEntry> get history => List.unmodifiable(_history);
  Map<String, int> get subjectStats => Map.unmodifiable(_subjectConsultationCounts);
  Map<String, int> get categoryStats => Map.unmodifiable(_categoryStats);
  Map<String, String> get lastStudiedLessons => Map.unmodifiable(_lastStudiedLessons);
  Map<String, int> get bannerClicks => Map.unmodifiable(_bannerClicks);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSelectedGrade = prefs.getBool(_keyHasSelectedGrade) ?? false;
      _savedLevelId = prefs.getString(_keyLevelId) ?? '2eme-bac';
      _savedBranchId = prefs.getString(_keyBranchId) ?? 'sciences-physiques';

      // Load history
      final rawHist = prefs.getString(_keyHistory);
      if (rawHist != null && rawHist.isNotEmpty) {
        final List<dynamic> list = json.decode(rawHist);
        _history.clear();
        for (final item in list) {
          _history.add(HistoryEntry.fromJson(item as Map<String, dynamic>));
        }
      }

      // Load subject stats
      final rawStats = prefs.getString(_keySubjectStats);
      if (rawStats != null && rawStats.isNotEmpty) {
        final Map<String, dynamic> map = json.decode(rawStats);
        _subjectConsultationCounts.clear();
        for (final entry in map.entries) {
          _subjectConsultationCounts[entry.key] =
              (entry.value as num?)?.toInt() ?? 0;
        }
      }

      // Load category stats
      final rawCat = prefs.getString(_keyCategoryStats);
      if (rawCat != null && rawCat.isNotEmpty) {
        final Map<String, dynamic> map = json.decode(rawCat);
        _categoryStats.clear();
        for (final entry in map.entries) {
          _categoryStats[entry.key] = (entry.value as num?)?.toInt() ?? 0;
        }
      }

      // Load last studied lessons
      final rawLessons = prefs.getString(_keyLastLessons);
      if (rawLessons != null && rawLessons.isNotEmpty) {
        final Map<String, dynamic> map = json.decode(rawLessons);
        _lastStudiedLessons.clear();
        for (final entry in map.entries) {
          _lastStudiedLessons[entry.key] = entry.value.toString();
        }
      }

      // Load banner clicks
      final rawBannerClicks = prefs.getString(_keyBannerClicks);
      if (rawBannerClicks != null && rawBannerClicks.isNotEmpty) {
        final Map<String, dynamic> map = json.decode(rawBannerClicks);
        _bannerClicks.clear();
        for (final entry in map.entries) {
          _bannerClicks[entry.key] = (entry.value as num?)?.toInt() ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> saveGrade({
    required String levelId,
    required String branchId,
  }) async {
    _hasSelectedGrade = true;
    _savedLevelId = levelId;
    _savedBranchId = branchId;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSelectedGrade, true);
    await prefs.setString(_keyLevelId, levelId);
    await prefs.setString(_keyBranchId, branchId);
  }

  Future<void> resetGrade() async {
    _hasSelectedGrade = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSelectedGrade, false);
  }

  int getSubjectConsultationCount(String subjectName) {
    return _subjectConsultationCounts[subjectName] ?? 0;
  }

  int getCategoryConsultationCount(String subjectName, String category) {
    return _categoryStats['$subjectName:$category'] ?? 0;
  }

  Map<String, int> getGlobalCategoryCounts() {
    final Map<String, int> totals = {
      'cours': 0,
      'resumes': 0,
      'exercices': 0,
      'controles': 0,
      'examens': 0,
    };
    for (final entry in _categoryStats.entries) {
      final parts = entry.key.split(':');
      if (parts.length >= 2) {
        final cat = parts.last;
        if (totals.containsKey(cat)) {
          totals[cat] = (totals[cat] ?? 0) + entry.value;
        }
      }
    }
    return totals;
  }

  String getTopCategory({List<String>? allowedCategories}) {
    final counts = getGlobalCategoryCounts();
    final candidates = allowedCategories ?? ['cours', 'resumes', 'exercices', 'controles', 'examens'];
    String topCat = candidates.first;
    int maxCount = -1;
    for (final cat in candidates) {
      final c = counts[cat] ?? 0;
      if (c > maxCount) {
        maxCount = c;
        topCat = cat;
      }
    }
    return topCat;
  }

  Future<void> recordBannerClick({
    required String bannerId,
    required String bannerType,
    String? category,
  }) async {
    final key = bannerType;
    _bannerClicks[key] = (_bannerClicks[key] ?? 0) + 1;
    if (category != null && category.isNotEmpty) {
      final catKey = 'banner:$category';
      _bannerClicks[catKey] = (_bannerClicks[catKey] ?? 0) + 1;
    }
    notifyListeners();
    await _saveData();
  }

  String? getLastStudiedLessonTitle(String subjectName, String category) {
    return _lastStudiedLessons['$subjectName:$category'];
  }

  Future<void> recordDocumentView(DocumentItem doc, String subjectName) async {
    // Increment subject stats
    _subjectConsultationCounts[subjectName] =
        (_subjectConsultationCounts[subjectName] ?? 0) + 1;

    // Increment category stats for this subject
    final catKey = '$subjectName:${doc.category}';
    _categoryStats[catKey] = (_categoryStats[catKey] ?? 0) + 1;

    // Record last studied lesson title
    _lastStudiedLessons[catKey] = doc.title;

    // Add to history (remove old duplicate if exists to keep top fresh)
    _history.removeWhere((h) => h.docId == doc.id);
    _history.insert(
      0,
      HistoryEntry(
        docId: doc.id,
        title: doc.title,
        subjectName: subjectName,
        category: doc.category,
        viewedAt: DateTime.now(),
      ),
    );

    if (_history.length > 50) {
      _history.removeLast();
    }

    notifyListeners();
    await _saveData();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _keyHistory, json.encode(_history.map((h) => h.toJson()).toList()));
      await prefs.setString(
          _keySubjectStats, json.encode(_subjectConsultationCounts));
      await prefs.setString(
          _keyCategoryStats, json.encode(_categoryStats));
      await prefs.setString(
          _keyLastLessons, json.encode(_lastStudiedLessons));
      await prefs.setString(
          _keyBannerClicks, json.encode(_bannerClicks));
    } catch (e) {
      debugPrint('Error saving analytics: $e');
    }
  }

  int get totalConsultations {
    int sum = 0;
    for (final v in _subjectConsultationCounts.values) {
      sum += v;
    }
    return sum;
  }

  Map<String, dynamic> exportData() {
    return {
      'hasSelectedGrade': _hasSelectedGrade,
      'savedLevelId': _savedLevelId,
      'savedBranchId': _savedBranchId,
      'history': _history.map((h) => h.toJson()).toList(),
      'subjectStats': _subjectConsultationCounts,
      'categoryStats': _categoryStats,
      'lastStudiedLessons': _lastStudiedLessons,
      'bannerClicks': _bannerClicks,
    };
  }

  Future<void> importCloudData(Map<String, dynamic> data) async {
    try {
      if (data['hasSelectedGrade'] == true &&
          (data['savedLevelId'] as String? ?? '').isNotEmpty) {
        _hasSelectedGrade = true;
        _savedLevelId = data['savedLevelId'] as String;
        _savedBranchId = data['savedBranchId'] as String? ?? _savedBranchId;
      }

      // History: Intelligent union by docId and timestamp
      if (data['history'] is List) {
        final Map<String, HistoryEntry> mergedHistory = {};
        for (final h in _history) {
          final key = '${h.docId}_${h.viewedAt.toIso8601String()}';
          mergedHistory[key] = h;
        }
        for (final item in data['history'] as List) {
          HistoryEntry? entry;
          if (item is Map<String, dynamic>) {
            entry = HistoryEntry.fromJson(item);
          } else if (item is Map) {
            entry = HistoryEntry.fromJson(Map<String, dynamic>.from(item));
          }
          if (entry != null) {
            final key = '${entry.docId}_${entry.viewedAt.toIso8601String()}';
            mergedHistory[key] = entry;
          }
        }
        final sortedList = mergedHistory.values.toList()
          ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
        _history.clear();
        _history.addAll(sortedList.take(50));
      }

      // Subject Stats: Take max(local, cloud) for each subject
      if (data['subjectStats'] is Map) {
        final map = data['subjectStats'] as Map;
        for (final entry in map.entries) {
          final key = entry.key.toString();
          final cloudVal = (entry.value as num?)?.toInt() ?? 0;
          final localVal = _subjectConsultationCounts[key] ?? 0;
          _subjectConsultationCounts[key] = math.max(localVal, cloudVal);
        }
      }

      // Category Stats: Take max(local, cloud)
      if (data['categoryStats'] is Map) {
        final map = data['categoryStats'] as Map;
        for (final entry in map.entries) {
          final key = entry.key.toString();
          final cloudVal = (entry.value as num?)?.toInt() ?? 0;
          final localVal = _categoryStats[key] ?? 0;
          _categoryStats[key] = math.max(localVal, cloudVal);
        }
      }

      // Banner Clicks: Take max(local, cloud)
      if (data['bannerClicks'] is Map) {
        final map = data['bannerClicks'] as Map;
        for (final entry in map.entries) {
          final key = entry.key.toString();
          final cloudVal = (entry.value as num?)?.toInt() ?? 0;
          final localVal = _bannerClicks[key] ?? 0;
          _bannerClicks[key] = math.max(localVal, cloudVal);
        }
      }

      // Last Studied Lessons: Merge
      if (data['lastStudiedLessons'] is Map) {
        final map = data['lastStudiedLessons'] as Map;
        for (final entry in map.entries) {
          final key = entry.key.toString();
          final title = entry.value.toString();
          if (title.isNotEmpty) {
            _lastStudiedLessons[key] = title;
          }
        }
      }

      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasSelectedGrade, _hasSelectedGrade);
      await prefs.setString(_keyLevelId, _savedLevelId);
      await prefs.setString(_keyBranchId, _savedBranchId);
      await _saveData();
    } catch (e) {
      debugPrint('UserProfileService importCloudData error: $e');
    }
  }
}
