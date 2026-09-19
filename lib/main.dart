import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/app_language_service.dart';
import 'services/curriculum_service.dart';
import 'services/download_service.dart';
import 'services/favorites_service.dart';
import 'services/smart_prefetch_service.dart';
import 'services/user_profile_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/level_selection_screen.dart';

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
  final userProfileService = UserProfileService();
  final curriculumService = CurriculumService();
  final downloadService = DownloadService();
  final favoritesService = FavoritesService();
  final smartPrefetchService = SmartPrefetchService();

  // Initialize all services in parallel
  await Future.wait([
    appLanguageService.init(),
    userProfileService.init(),
    curriculumService.init(),
    downloadService.init(),
    favoritesService.init(),
  ]);

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
        ChangeNotifierProvider.value(value: userProfileService),
        ChangeNotifierProvider.value(value: curriculumService),
        ChangeNotifierProvider.value(value: downloadService),
        ChangeNotifierProvider.value(value: favoritesService),
        ChangeNotifierProvider.value(value: smartPrefetchService),
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

  void _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<UserProfileService>();
    final langService = context.watch<AppLanguageService>();

    return MaterialApp(
      title: 'Cours Maroc',
      debugShowCheckedModeBanner: false,
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
      // If student hasn't selected their grade yet, launch onboarding selector.
      // Otherwise, open straight into their courses!
      home: userProfile.hasSelectedGrade
          ? HomeScreen(
              onToggleTheme: _toggleTheme,
              isDarkMode: _isDarkMode,
            )
          : const LevelSelectionScreen(),
    );
  }
}
