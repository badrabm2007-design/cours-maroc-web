import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'user_profile_service.dart';
import 'favorites_service.dart';
import 'download_service.dart';
import 'app_language_service.dart';
import 'auth_service.dart';

enum SyncAction { cloudLoaded, localUploaded, error }

class SyncResult {
  final SyncAction action;
  final bool hasSelectedGrade;
  final String? message;

  const SyncResult({
    required this.action,
    required this.hasSelectedGrade,
    this.message,
  });
}

class UserSyncService extends ChangeNotifier {
  static const String _projectId = 'cours-maroc-app';
  static const String _firestoreBaseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/users';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  Timer? _debounceTimer;

  AuthService? _authService;
  UserProfileService? _profileService;
  FavoritesService? _favService;
  DownloadService? _downloadService;
  AppLanguageService? _langService;
  Function(bool)? _onThemeUpdate;
  bool Function()? _getIsDarkMode;
  String _platform = 'web';

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Wire services to enable continuous background auto-sync across the ecosystem
  void attachServices({
    required AuthService authService,
    required UserProfileService profileService,
    required FavoritesService favService,
    required DownloadService downloadService,
    required AppLanguageService langService,
    Function(bool)? onThemeUpdate,
    bool Function()? getIsDarkMode,
    String platform = 'web',
  }) {
    _authService = authService;
    _profileService = profileService;
    _favService = favService;
    _downloadService = downloadService;
    _langService = langService;
    _onThemeUpdate = onThemeUpdate;
    _getIsDarkMode = getIsDarkMode;
    _platform = platform;

    // Listen to changes on local services to trigger debounced push
    _profileService?.addListener(_onLocalStateChanged);
    _favService?.addListener(_onLocalStateChanged);
    _downloadService?.addListener(_onLocalStateChanged);
    _langService?.addListener(_onLocalStateChanged);
  }

  void _onLocalStateChanged() {
    if (_isSyncing) return;
    if (_authService == null || !_authService!.isAuthenticated) return;
    scheduleDebouncedPush();
  }

  /// Triggers a push to Cloud with 1.5s debounce to consolidate rapid edits
  void scheduleDebouncedPush({Duration delay = const Duration(milliseconds: 1500)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      pushCurrentStateToCloud();
    });
  }

  /// Pushes current state to cloud if authenticated
  Future<void> pushCurrentStateToCloud() async {
    if (_isSyncing) return;
    if (_authService == null || !_authService!.isAuthenticated) return;
    final user = _authService!.currentUser;
    if (user == null) return;
    final token = await _authService!.getIdToken();
    if (token == null) return;

    await _pushDataInternal(
      userId: user.id,
      idToken: token,
      platform: _platform,
      profileService: _profileService,
      favService: _favService,
      downloadService: _downloadService,
      langService: _langService,
      isDarkMode: _getIsDarkMode?.call(),
    );
  }

  /// Syncs data upon user sign-in.
  /// RULE: If cloud document exists, performs non-destructive bidirectional merge
  /// and writes back the reconciled state to both device and Firestore immediately.
  Future<SyncResult> syncOnLogin({
    required String userId,
    required String idToken,
    UserProfileService? profileService,
    FavoritesService? favService,
    DownloadService? downloadService,
    AppLanguageService? langService,
    String? platform,
  }) async {
    _isSyncing = true;
    notifyListeners();

    final targetProfile = profileService ?? _profileService;
    final targetFav = favService ?? _favService;
    final targetDownload = downloadService ?? _downloadService;
    final targetLang = langService ?? _langService;
    final targetPlatform = platform ?? _platform;

    final docUrl = '$_firestoreBaseUrl/$userId';

    try {
      final res = await _dio.get(
        docUrl,
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        // 1. Cloud document exists: Reconcile cloud data with local data
        final fields = res.data['fields'] as Map<String, dynamic>?;
        final rawPayload = fields?['payload']?['stringValue'] as String?;

        if (rawPayload != null && rawPayload.isNotEmpty) {
          final cloudData = json.decode(rawPayload) as Map<String, dynamic>;

          // Apply cloud data to local services (non-destructive merge)
          if (targetProfile != null) {
            await targetProfile.importCloudData(cloudData);
          }

          if (targetFav != null && cloudData['favorites'] is List) {
            await targetFav.importCloudData(cloudData['favorites'] as List);
          }

          if (targetDownload != null && cloudData['downloads'] is List) {
            await targetDownload.importCloudData(cloudData['downloads'] as List);
          }

          if (targetLang != null && cloudData['language'] is String) {
            await targetLang.importCloudData(cloudData['language'] as String);
          }

          if (cloudData['isDarkMode'] is bool && _onThemeUpdate != null) {
            _onThemeUpdate!(cloudData['isDarkMode'] as bool);
          }

          // Write unified reconciled state back to Firestore so cloud has the latest
          await _pushDataInternal(
            userId: userId,
            idToken: idToken,
            platform: targetPlatform,
            profileService: targetProfile,
            favService: targetFav,
            downloadService: targetDownload,
            langService: targetLang,
            isDarkMode: _getIsDarkMode?.call(),
          );

          _lastSyncTime = DateTime.now();
          _isSyncing = false;
          notifyListeners();

          return SyncResult(
            action: SyncAction.cloudLoaded,
            hasSelectedGrade: targetProfile?.hasSelectedGrade ?? true,
            message: 'Données synchronisées avec succès.',
          );
        }
      }

      // 2. No cloud document yet (HTTP 404 or empty)
      // Upload current local state to cloud to initialize this account
      await _pushDataInternal(
        userId: userId,
        idToken: idToken,
        platform: targetPlatform,
        profileService: targetProfile,
        favService: targetFav,
        downloadService: targetDownload,
        langService: targetLang,
        isDarkMode: _getIsDarkMode?.call(),
      );

      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      notifyListeners();

      return SyncResult(
        action: SyncAction.localUploaded,
        hasSelectedGrade: targetProfile?.hasSelectedGrade ?? false,
        message: 'Vos données ont été sauvegardées sur votre compte Cloud.',
      );
    } catch (e) {
      debugPrint('UserSyncService syncOnLogin error on web: $e');
      _isSyncing = false;
      notifyListeners();

      return SyncResult(
        action: SyncAction.error,
        hasSelectedGrade: targetProfile?.hasSelectedGrade ?? false,
        message: 'Erreur lors de la synchronisation: $e',
      );
    }
  }

  /// Pushes current local state to Cloud in the background whenever changes occur.
  Future<void> pushLocalToCloud({
    required String userId,
    required String idToken,
    UserProfileService? profileService,
    FavoritesService? favService,
    DownloadService? downloadService,
    AppLanguageService? langService,
    String? platform,
    bool? isDarkMode,
  }) async {
    await _pushDataInternal(
      userId: userId,
      idToken: idToken,
      platform: platform ?? _platform,
      profileService: profileService ?? _profileService,
      favService: favService ?? _favService,
      downloadService: downloadService ?? _downloadService,
      langService: langService ?? _langService,
      isDarkMode: isDarkMode ?? _getIsDarkMode?.call(),
    );
  }

  Future<void> _pushDataInternal({
    required String userId,
    required String idToken,
    required String platform,
    UserProfileService? profileService,
    FavoritesService? favService,
    DownloadService? downloadService,
    AppLanguageService? langService,
    bool? isDarkMode,
  }) async {
    final docUrl = '$_firestoreBaseUrl/$userId';

    try {
      final localPayload = {
        ...?profileService?.exportData(),
        'favorites': favService?.exportData() ?? [],
        'downloads': downloadService?.exportData() ?? [],
        'language': langService?.exportData() ?? 'fr',
        'isDarkMode': isDarkMode ?? _getIsDarkMode?.call() ?? false,
      };

      await _dio.patch(
        docUrl,
        data: {
          'fields': {
            'updatedAt': {'stringValue': DateTime.now().toIso8601String()},
            'platform': {'stringValue': platform},
            'payload': {'stringValue': json.encode(localPayload)},
          }
        },
        options: Options(
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      );

      _lastSyncTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('UserSyncService _pushDataInternal error on web: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _profileService?.removeListener(_onLocalStateChanged);
    _favService?.removeListener(_onLocalStateChanged);
    _downloadService?.removeListener(_onLocalStateChanged);
    _langService?.removeListener(_onLocalStateChanged);
    super.dispose();
  }
}
