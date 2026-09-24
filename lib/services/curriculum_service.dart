import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/curriculum_models.dart';

class CurriculumService extends ChangeNotifier {
  static const String _levelPrefKey = 'selected_level_id';
  static const String _branchPrefKey = 'selected_branch_id';
  static const String _remoteCatalogUrlPrefKey = 'remote_catalog_url_override_v1';
  static const String catalogDriveFileId = '1HXG24aQmnvxj5pl19b7OdqNvQcJSzeyG';
  static const String defaultRemoteCatalogUrl =
      'https://drive.usercontent.google.com/download?id=$catalogDriveFileId&export=download&authuser=0&confirm=t';
  static const List<String> defaultRemoteCatalogUrls = [
    'https://drive.usercontent.google.com/download?id=$catalogDriveFileId&export=download&authuser=0&confirm=t',
    'https://drive.google.com/uc?id=$catalogDriveFileId&export=download&confirm=t',
    'https://docs.google.com/uc?export=download&id=$catalogDriveFileId',
  ];

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _rawCurriculumData;

  String _selectedLevelId = '2eme-bac';
  String _selectedBranchId = 'sciences-physiques';

  final Map<String, List<SubjectItem>> _cacheByBranch = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedLevelId => _selectedLevelId;
  String get selectedBranchId => _selectedBranchId;

  LevelOption get currentLevel {
    return LevelOption.allLevels.firstWhere(
      (l) => l.id == _selectedLevelId,
      orElse: () => LevelOption.allLevels.last,
    );
  }

  BranchOption get currentBranch {
    final lvl = currentLevel;
    return lvl.branches.firstWhere(
      (b) => b.id == _selectedBranchId,
      orElse: () => lvl.branches.first,
    );
  }

  /// Abréviation standard marocaine pour l'affichage en haut (ex: TCS, 3AC, 1BAC SE, 2BAC SMA, 2BAC PC, etc.)
  String get shortLevelAndBranchCode {
    final lvlId = _selectedLevelId;
    final brId = _selectedBranchId;

    if (lvlId == '3eme-annee-college') {
      return '3AC';
    }
    if (lvlId == 'tronc-commun') {
      if (brId.contains('science')) return 'TCS';
      if (brId.contains('lettre')) return 'TCL';
      if (brId.contains('techno')) return 'TCT';
      return 'TC';
    }
    if (lvlId == '1ere-bac') {
      if (brId.contains('experimentale')) return '1BAC SE';
      if (brId.contains('math')) return '1BAC SM';
      if (brId.contains('economique')) return '1BAC SEG';
      if (brId.contains('lettre')) return '1BAC LSH';
      if (brId.contains('electrique')) return '1BAC STE';
      if (brId.contains('mecanique')) return '1BAC STM';
      return '1BAC';
    }
    if (lvlId == '2eme-bac') {
      if (brId.contains('physique')) return '2BAC PC';
      if (brId.contains('vie') || brId.contains('terre') || brId.contains('svt')) return '2BAC SVT';
      if (brId.contains('math') && (brId.endsWith('-b') || brId.contains('sciences-maths-b') || brId.contains('option-b'))) return '2BAC SM-B';
      if (brId.contains('math')) return '2BAC SM-A';
      if (brId.contains('economique')) return '2BAC SE';
      if (brId.contains('comptable') || brId.contains('sgc')) return '2BAC SGC';
      if (brId.contains('lettre')) return '2BAC Lettres';
      if (brId.contains('humaine')) return '2BAC SH';
      if (brId.contains('electrique')) return '2BAC STE';
      if (brId.contains('mecanique')) return '2BAC STM';
      return '2BAC';
    }
    return currentLevel.shortName;
  }

  static const String _cachedCatalogPrefKey = 'cached_curriculum_catalog_json_v1';

  int _extractVersion(Map<String, dynamic>? meta) {
    if (meta == null) return 0;
    final v1 = (meta['catalogVersion'] as num?)?.toInt() ?? 0;
    final v2 = (meta['version'] as num?)?.toInt() ?? 0;
    return v1 > v2 ? v1 : v2;
  }

  int _extractDocCount(Map<String, dynamic>? meta) {
    if (meta == null) return 0;
    final c1 = (meta['totalDocuments'] as num?)?.toInt() ?? 0;
    final c2 = (meta['totalPdfs'] as num?)?.toInt() ?? 0;
    return c1 > c2 ? c1 : c2;
  }

  Future<void> _loadLocalCurriculum(SharedPreferences prefs) async {
    Map<String, dynamic>? bundledData;
    int bundledVersion = 0;
    int bundledCount = 0;

    // 1. Load bundled asset
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/curriculum.json');
      bundledData = json.decode(jsonString) as Map<String, dynamic>?;
      if (bundledData != null) {
        final meta = bundledData['metadata'] as Map<String, dynamic>?;
        bundledVersion = _extractVersion(meta);
        bundledCount = _extractDocCount(meta);
      }
    } catch (e) {
      debugPrint('Warning: Could not read bundled curriculum asset: $e');
    }

    // 2. Check local persistent cache in SharedPreferences (localStorage)
    try {
      final cachedContent = prefs.getString(_cachedCatalogPrefKey);
      if (cachedContent != null && cachedContent.isNotEmpty) {
        final Map<String, dynamic> cachedData = json.decode(cachedContent);
        if (cachedData.containsKey('levels') &&
            cachedData['levels'] is Map &&
            (cachedData['levels'] as Map).isNotEmpty) {
          final cachedMeta = cachedData['metadata'] as Map<String, dynamic>?;
          final cachedVersion = _extractVersion(cachedMeta);
          final cachedCount = _extractDocCount(cachedMeta);

          // If bundled asset is newer, bundled wins!
          if (bundledData != null &&
              (bundledVersion > cachedVersion ||
                  (bundledVersion == cachedVersion &&
                      bundledCount > cachedCount))) {
            _rawCurriculumData = bundledData;
            _cacheByBranch.clear();
            await prefs.setString(_cachedCatalogPrefKey, json.encode(bundledData));
            debugPrint(
              'Curriculum updated from newer bundled asset (v$bundledVersion, $bundledCount docs > cached v$cachedVersion, $cachedCount docs). Cache synced.',
            );
            return;
          }

          // Otherwise, local cache is newer or equal
          _rawCurriculumData = cachedData;
          _cacheByBranch.clear();
          debugPrint(
            'Curriculum loaded from local persistent cache (v$cachedVersion, $cachedCount docs).',
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Warning: Could not read local cached curriculum: $e');
    }

    // 3. Fallback to bundled asset if no valid cache existed
    if (bundledData != null) {
      _rawCurriculumData = bundledData;
      _cacheByBranch.clear();
      try {
        await prefs.setString(_cachedCatalogPrefKey, json.encode(bundledData));
      } catch (_) {}
      debugPrint(
        'Curriculum loaded from bundled asset (v$bundledVersion, $bundledCount docs).',
      );
    }
  }

  Future<void> _checkRemoteCatalogUpdate(SharedPreferences prefs) async {
    final customUrl = prefs.getString(_remoteCatalogUrlPrefKey);
    final List<String> urlsToTry = [];
    if (customUrl != null &&
        customUrl.isNotEmpty &&
        !customUrl.contains('githubusercontent.com')) {
      urlsToTry.add(customUrl);
    }
    urlsToTry.addAll(defaultRemoteCatalogUrls);

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.plain,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile)',
        },
      ),
    );

    for (final remoteUrl in urlsToTry) {
      try {
        final response = await dio.get(remoteUrl);
        if (response.statusCode == 200 && response.data != null) {
          final dynamic rawData = response.data;
          final String rawString =
              rawData is String ? rawData : json.encode(rawData);
          if (rawString.isEmpty) continue;

          final Map<String, dynamic> remoteData =
              rawData is Map<String, dynamic>
                  ? rawData
                  : (json.decode(rawString) as Map<String, dynamic>);

          if (!remoteData.containsKey('levels') ||
              (remoteData['levels'] as Map).isEmpty) {
            continue;
          }

          final remoteMeta =
              remoteData['metadata'] as Map<String, dynamic>? ?? {};
          final localMeta =
              _rawCurriculumData?['metadata'] as Map<String, dynamic>? ?? {};

          final remoteVersion = _extractVersion(remoteMeta);
          final localVersion = _extractVersion(localMeta);

          final remoteCount = _extractDocCount(remoteMeta);
          final localCount = _extractDocCount(localMeta);

          // If remote has a higher version or higher document count, update!
          if (remoteVersion > localVersion ||
              (remoteVersion == localVersion && remoteCount > localCount)) {
            debugPrint(
              'Found new curriculum catalog! (Remote v$remoteVersion / $remoteCount PDFs vs Local v$localVersion / $localCount PDFs)',
            );

            // Save to local cached SharedPreferences
            await prefs.setString(_cachedCatalogPrefKey, rawString);

            // Update local memory state
            _rawCurriculumData = remoteData;
            _cacheByBranch.clear();
            notifyListeners();
            debugPrint(
              'Curriculum successfully updated dynamically in background from Google Drive!',
            );
          }
          // Successfully checked with a reachable endpoint
          return;
        }
      } catch (e) {
        debugPrint('Background curriculum check at $remoteUrl failed: $e');
      }
    }
  }

  Future<void> checkForRemoteUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkRemoteCatalogUpdate(prefs);
  }

  Future<void> refreshCurriculumNow() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadLocalCurriculum(prefs);
    _cacheByBranch.clear();
    notifyListeners();
    await _checkRemoteCatalogUpdate(prefs);
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedLevelId = prefs.getString(_levelPrefKey) ?? '2eme-bac';
      _selectedBranchId =
          prefs.getString(_branchPrefKey) ?? 'sciences-physiques';

      // Validate saved branch against level
      final level = LevelOption.allLevels.firstWhere(
        (l) => l.id == _selectedLevelId,
        orElse: () => LevelOption.allLevels.last,
      );
      if (!level.branches.any((b) => b.id == _selectedBranchId)) {
        _selectedBranchId = level.branches.first.id;
      }

      // Step 1: Load local cache or bundled asset immediately (0ms blocking)
      await _loadLocalCurriculum(prefs);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      // Step 2: Trigger background check for dynamic catalog updates
      _checkRemoteCatalogUpdate(prefs);
    } catch (e, stack) {
      debugPrint('Error initializing curriculum data: $e\n$stack');
      _errorMessage = 'Impossible de charger les cours: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectLevelAndBranch(String levelId, String branchId) async {
    _selectedLevelId = levelId;
    _selectedBranchId = branchId;
    _cacheByBranch.clear();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_levelPrefKey, levelId);
    await prefs.setString(_branchPrefKey, branchId);
    _checkRemoteCatalogUpdate(prefs);
  }

  Future<void> selectLevel(String levelId) async {
    final level = LevelOption.allLevels.firstWhere(
      (l) => l.id == levelId,
      orElse: () => LevelOption.allLevels.first,
    );
    await selectLevelAndBranch(levelId, level.branches.first.id);
  }

  Future<void> selectBranch(String branchId) async {
    await selectLevelAndBranch(_selectedLevelId, branchId);
  }

  List<SubjectItem> getCurrentSubjects() {
    final cacheKey = '$_selectedLevelId/$_selectedBranchId';
    if (_cacheByBranch.containsKey(cacheKey)) {
      return _cacheByBranch[cacheKey]!;
    }

    if (_rawCurriculumData == null) return [];

    final levels = _rawCurriculumData!['levels'] as Map<String, dynamic>?;
    if (levels == null) return [];

    final levelBranches = levels[_selectedLevelId] as Map<String, dynamic>?;
    if (levelBranches == null) return [];

    final branchSubjects = levelBranches[_selectedBranchId] as Map<String, dynamic>?;
    if (branchSubjects == null) return [];

    final List<SubjectItem> subjectsList = [];

    // Preferred subject ordering:
    const preferredOrder = [
      'economie-generale',
      'comptabilite',
      'organisation-entreprises',
      'droit',
      'informatique',
      'informatique-gestion',
      'mathematiques',
      'physique-chimie',
      'svt',
      'philosophie',
      'anglais',
      'histoire-geographie',
      'francais',
      'arabe',
      'education-islamique',
    ];

    final sortedKeys = branchSubjects.keys.toList()
      ..sort((a, b) {
        final idxA = preferredOrder.indexOf(a);
        final idxB = preferredOrder.indexOf(b);
        if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
        if (idxA != -1) return -1;
        if (idxB != -1) return 1;
        return a.compareTo(b);
      });

    for (final key in sortedKeys) {
      final rawDocs = branchSubjects[key] as List<dynamic>? ?? [];
      final docs = rawDocs
          .map((d) => DocumentItem.fromJson(d as Map<String, dynamic>))
          .toList();

      final meta = SubjectMeta.get(key);
      subjectsList.add(SubjectItem(meta: meta, documents: docs));
    }

    _cacheByBranch[cacheKey] = subjectsList;
    return subjectsList;
  }

  SubjectItem? getSubjectById(String subjectId) {
    final list = getCurrentSubjects();
    try {
      return list.firstWhere((s) => s.id == subjectId);
    } catch (_) {
      return null;
    }
  }

  // Global search across all levels and subjects
  List<Map<String, dynamic>> searchAllDocuments(String query) {
    if (query.trim().isEmpty || _rawCurriculumData == null) return [];
    final lower = query.toLowerCase().trim();
    final terms = lower.split(RegExp(r'\s+'));

    final levels = _rawCurriculumData!['levels'] as Map<String, dynamic>?;
    if (levels == null) return [];

    final List<Map<String, dynamic>> results = [];

    // Prioritize current branch first, then search others
    final subjects = getCurrentSubjects();
    for (final subj in subjects) {
      for (final doc in subj.documents) {
        final docText = '${doc.title} ${doc.name} ${doc.category} ${doc.semester} ${subj.nameFr}'
            .toLowerCase();
        final matches = terms.every((term) => docText.contains(term));
        if (matches) {
          results.add({
            'document': doc,
            'subject': subj,
            'level': currentLevel,
            'branch': currentBranch,
          });
          if (results.length >= 100) return results;
        }
      }
    }

    return results;
  }
}
