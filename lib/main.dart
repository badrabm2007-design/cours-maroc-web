import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/app_language_service.dart';
import 'services/auth_service.dart';
import 'services/curriculum_service.dart';
import 'services/download_service.dart';
import 'services/favorites_service.dart';
import 'services/focus_sound_service.dart';
import 'services/focus_timer_service.dart';
import 'services/orientation_service.dart';
import 'services/smart_prefetch_service.dart';
import 'services/user_profile_service.dart';
import 'services/user_sync_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/level_selection_screen.dart';
import 'screens/orientation_screen.dart';
import 'screens/school_detail_screen.dart';
import 'screens/subject_detail_screen.dart';
import 'widgets/floating_focus_timer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('is_dark_mode') ?? false;

  final appLanguageService = AppLanguageService();
  final authService = AuthService();
  final userProfileService = UserProfileService();
  final curriculumService = CurriculumService();
  final downloadService = DownloadService();
  final favoritesService = FavoritesService();
  final smartPrefetchService = SmartPrefetchService();
  final userSyncService = UserSyncService();
  final focusSoundService = FocusSoundService();
  final focusTimerService = FocusTimerService();
  final orientationService = OrientationService();

  // Initialize all services in parallel
  await Future.wait([
    appLanguageService.init(),
    authService.init(),
    userProfileService.init(),
    curriculumService.init(),
    downloadService.init(),
    favoritesService.init(),
    orientationService.init(),
  ]);

  // Attach services to enable auto-sync across the ecosystem
  userSyncService.attachServices(
    authService: authService,
    profileService: userProfileService,
    favService: favoritesService,
    downloadService: downloadService,
    langService: appLanguageService,
    getIsDarkMode: () => isDarkMode,
    platform: 'web',
  );

  // Synchronize with cloud if already logged in
  if (authService.isAuthenticated) {
    final token = await authService.getIdToken();
    if (token != null) {
      await userSyncService.syncOnLogin(
        userId: authService.currentUser!.id,
        idToken: token,
        profileService: userProfileService,
        favService: favoritesService,
        downloadService: downloadService,
        langService: appLanguageService,
        platform: 'web',
      );
    }
  }

  // Synchronize saved level & branch if user has previously selected one
  if (userProfileService.hasSelectedGrade) {
    await curriculumService.selectLevelAndBranch(
      userProfileService.savedLevelId,
      userProfileService.savedBranchId,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appLanguageService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: userProfileService),
        ChangeNotifierProvider.value(value: curriculumService),
        ChangeNotifierProvider.value(value: downloadService),
        ChangeNotifierProvider.value(value: favoritesService),
        ChangeNotifierProvider.value(value: smartPrefetchService),
        ChangeNotifierProvider.value(value: userSyncService),
        ChangeNotifierProvider.value(value: focusSoundService),
        ChangeNotifierProvider.value(value: focusTimerService),
        ChangeNotifierProvider.value(value: orientationService),
      ],
      child: CoursLyceeApp(initialDarkMode: isDarkMode),
    ),
  );
}

class CoursLyceeApp extends StatefulWidget {
  final bool initialDarkMode;

  const CoursLyceeApp({super.key, required this.initialDarkMode});

  @override
  State<CoursLyceeApp> createState() => _CoursLyceeAppState();
}

class _CoursLyceeAppState extends State<CoursLyceeApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final syncService = context.read<UserSyncService>();
    syncService.attachServices(
      authService: context.read<AuthService>(),
      profileService: context.read<UserProfileService>(),
      favService: context.read<FavoritesService>(),
      downloadService: context.read<DownloadService>(),
      langService: context.read<AppLanguageService>(),
      onThemeUpdate: (cloudDark) {
        if (mounted && cloudDark != _isDarkMode) {
          setState(() {
            _isDarkMode = cloudDark;
          });
        }
      },
      getIsDarkMode: () => _isDarkMode,
      platform: 'web',
    );
  }

  void _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    if (mounted) {
      context.read<UserSyncService>().scheduleDebouncedPush();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<UserProfileService>();
    final langService = context.watch<AppLanguageService>();

    return MaterialApp(
      title: 'Cours Maroc',
      debugShowCheckedModeBanner: false,
      navigatorKey: FocusTimerService.navigatorKey,
      builder: (context, child) => FocusTimerOverlayWrapper(
        child: child ?? const SizedBox.shrink(),
      ),
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: langService.currentLocale,
      supportedLocales: const [
        Locale('fr'),
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        final segments = uri.pathSegments;

        // 1. Root / Dashboard
        if (segments.isEmpty || (segments.length == 1 && segments[0].isEmpty)) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => userProfile.hasSelectedGrade
                ? HomeScreen(
                    onToggleTheme: _toggleTheme,
                    isDarkMode: _isDarkMode,
                  )
                : const LevelSelectionScreen(),
          );
        }

        // 2. /orientation -> Section Orientation Post-Bac
        if (segments.length == 1 && segments[0] == 'orientation') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const OrientationScreen(),
          );
        }

        // 3. /orientation/:schoolId (ex: /orientation/ensa, /orientation/est)
        if (segments.length == 2 && segments[0] == 'orientation') {
          final schoolId = segments[1];
          final orientService = context.read<OrientationService>();
          final school = orientService.getSchoolById(schoolId);
          if (school != null) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => SchoolDetailScreen(school: school),
            );
          }
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const OrientationScreen(),
          );
        }

        // 4. Curriculum route: /:level/:subject (ex: /2bac/maths, /2bac/pc, /3ac/maths)
        if (segments.length == 2) {
          final rawLevel = segments[0].toLowerCase();
          final rawSubj = segments[1].toLowerCase();

          String levelId = '2eme-bac';
          if (rawLevel == '3ac' || rawLevel.contains('college')) {
            levelId = '3eme-annee-college';
          } else if (rawLevel == 'tc' || rawLevel.contains('tronc')) {
            levelId = 'tronc-commun';
          } else if (rawLevel == '1bac') {
            levelId = '1ere-bac';
          } else if (rawLevel == '2bac') {
            levelId = '2eme-bac';
          }

          String subjectId = rawSubj;
          if (rawSubj == 'maths' || rawSubj == 'math') subjectId = 'mathematiques';
          if (rawSubj == 'pc' || rawSubj == 'physique') subjectId = 'physique-chimie';
          if (rawSubj == 'ei' || rawSubj == 'islamique') subjectId = 'education-islamique';
          if (rawSubj == 'hg' || rawSubj == 'histoire') subjectId = 'histoire-geographie';

          final curriculumService = context.read<CurriculumService>();
          final subject = curriculumService.getSubjectById(subjectId);
          if (subject != null) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => SubjectDetailScreen(
                subject: subject,
                levelId: levelId,
              ),
            );
          }
        }

        // Fallback default
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => userProfile.hasSelectedGrade
              ? HomeScreen(
                  onToggleTheme: _toggleTheme,
                  isDarkMode: _isDarkMode,
                )
              : const LevelSelectionScreen(),
        );
      },
    );
  }
}
