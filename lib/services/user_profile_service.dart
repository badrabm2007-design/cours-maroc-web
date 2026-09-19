import 'dart:convert';
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

  bool _initialized = false;
  bool _hasSelectedGrade = false;
  String _savedLevelId = '2eme-bac';
  String _savedBranchId = 'sciences-physiques';

  final List<HistoryEntry> _history = [];
  final Map<String, int> _subjectConsultationCounts = {};
  final Map<String, int> _categoryStats = {};
  final Map<String, String> _lastStudiedLessons = {};

  bool get isInitialized => _initialized;
  bool get hasSelectedGrade => _hasSelectedGrade;
  String get savedLevelId => _savedLevelId;
  String get savedBranchId => _savedBranchId;
  List<HistoryEntry> get history => List.unmodifiable(_history);
  Map<String, int> get subjectStats => Map.unmodifiable(_subjectConsultationCounts);
  Map<String, int> get categoryStats => Map.unmodifiable(_categoryStats);
  Map<String, String> get lastStudiedLessons => Map.unmodifiable(_lastStudiedLessons);

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
}
