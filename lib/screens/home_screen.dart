import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/curriculum_models.dart';
import '../services/curriculum_service.dart';
import '../services/download_service.dart';
import '../services/favorites_service.dart';
import '../services/smart_prefetch_service.dart';
import '../services/user_profile_service.dart';
import 'level_selection_screen.dart';
import '../widgets/level_branch_selector.dart';
import '../widgets/subject_grid_card.dart';
import 'profile_analytics_screen.dart';
import 'offline_downloads_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'orientation_screen.dart';
import 'focus_mode_screen.dart';
import '../services/app_language_service.dart';
import '../services/auth_service.dart';
import '../services/user_sync_service.dart';
import '../services/focus_timer_service.dart';
import '../services/smart_banner_service.dart';
import '../widgets/smart_banner_cards.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Set<String> _prefetchedSubjectIds = {};
  String? _lastBranchId;

  Future<void> _openWindowsDownload() async {
    const url =
        'https://github.com/badrabm2007-design/CoursMaroc-Windows/releases/download/v1.1.0/CoursMaroc_Windows_v1.1.0.zip';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _checkAndPromptGoogleAuth() {
    final authService = context.read<AuthService>();
    if (!authService.hasShownPrompt && !authService.isAuthenticated) {
      _showGoogleSignInDialog();
    }
  }

  void _showGoogleSignInDialog() {
    final langService = context.read<AppLanguageService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5132).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_circle_rounded,
                  color: Color(0xFF0F5132),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  langService.tr('auth_google_prompt_title'),
                  style: const TextStyle(
                      fontSize: 16.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Text(
            langService.tr('auth_google_prompt_desc'),
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                context.read<AuthService>().markPromptShown();
                Navigator.of(ctx).pop();
              },
              child: Text(
                langService.tr('auth_google_later'),
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
              label: Text(
                langService.tr('auth_google_signin'),
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final auth = context.read<AuthService>();
                final syncService = context.read<UserSyncService>();
                final profileService = context.read<UserProfileService>();
                final favService = context.read<FavoritesService>();
                final curriculumService = context.read<CurriculumService>();

                final success = await auth.signInWithGoogle();
                if (!mounted) return;

                if (success && auth.currentUser != null) {
                  final token = await auth.getIdToken();
                  if (token != null) {
                    final result = await syncService.syncOnLogin(
                      userId: auth.currentUser!.id,
                      idToken: token,
                      profileService: profileService,
                      favService: favService,
                      platform: 'web',
                    );

                    if (!mounted) return;

                    if (result.hasSelectedGrade) {
                      await curriculumService.selectLevelAndBranch(
                        profileService.savedLevelId,
                        profileService.savedBranchId,
                      );
                    }
                  }

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        langService.isArabic
                            ? 'مرحباً ${auth.currentUser!.displayName}! تمت المزامنة بنجاح.'
                            : 'Bienvenue ${auth.currentUser!.displayName} ! Synchronisation réussie.',
                      ),
                      backgroundColor: const Color(0xFF0F5132),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CurriculumService>().checkForRemoteUpdate();
        _checkAndPromptGoogleAuth();
        context.read<FocusTimerService>().pushDockingScreen(ActiveDockingScreen.home);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      context.read<FocusTimerService>().popDockingScreen(ActiveDockingScreen.home);
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<CurriculumService>().checkForRemoteUpdate();
    }
  }

  void _onHomeScrollSettled(ScrollMetrics metrics, List<SubjectItem> subjects) {
    if (subjects.length <= 6) return;

    // Header offset before grid: Selector (~45) + Quick Actions (~75) + Title (~40) = ~160px
    const double headerHeight = 160.0;
    final double scrollOffset = metrics.pixels;
    if (scrollOffset <= 60) return; // Top items are already prefetched

    final double gridOffset =
        (scrollOffset - headerHeight).clamp(0.0, double.infinity);
    // In phone 2 columns, each row has height ~145px
    const double approxRowHeight = 145.0;
    final int firstRow = (gridOffset / approxRowHeight).floor();
    final int firstSubjectIdx = (firstRow * 2).clamp(0, subjects.length - 1);
    final int lastSubjectIdx =
        (firstSubjectIdx + 6).clamp(0, subjects.length);

    if (firstSubjectIdx < lastSubjectIdx) {
      final newlyVisible = <SubjectItem>[];
      for (int i = firstSubjectIdx; i < lastSubjectIdx; i++) {
        final s = subjects[i];
        if (!_prefetchedSubjectIds.contains(s.id)) {
          _prefetchedSubjectIds.add(s.id);
          newlyVisible.add(s);
        }
      }
      if (newlyVisible.isNotEmpty) {
        context.read<SmartPrefetchService>().prefetchHomeScrolledSubjects(
              newlyVisibleSubjects: newlyVisible,
              userProfile: context.read<UserProfileService>(),
              downloadService: context.read<DownloadService>(),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final curriculum = context.watch<CurriculumService>();
    final downloadService = context.watch<DownloadService>();
    final favoritesService = context.watch<FavoritesService>();
    final langService = context.watch<AppLanguageService>();

    if (curriculum.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF0F5132)),
              SizedBox(height: 20),
              Text(
                'Chargement du programme scolaire...',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (curriculum.errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  curriculum.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => curriculum.init(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final subjects = curriculum.getCurrentSubjects();
    final totalDocsInBranch =
        subjects.fold<int>(0, (sum, s) => sum + s.totalCount);

    final currentBranchId = curriculum.selectedBranchId;
    if (_lastBranchId != currentBranchId) {
      _lastBranchId = currentBranchId;
      _prefetchedSubjectIds.clear();

      if (subjects.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<SmartPrefetchService>().prefetchHomeScreenInitial(
                subjects: subjects,
                userProfile: context.read<UserProfileService>(),
                downloadService: context.read<DownloadService>(),
              );
          for (final s in subjects.take(6)) {
            _prefetchedSubjectIds.add(s.id);
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cours Maroc',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  langService.isArabic
                      ? 'دروس المغرب'
                      : 'دروس المغرب • الثانوي',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF0F5132),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            // On Desktop/PC: Show Level & Branch selector chip in AppBar
            if (MediaQuery.of(context).size.width >= 700) ...[
              const SizedBox(width: 18),
              Tooltip(
                message: langService.isArabic
                    ? 'تغيير المستوى الدراسي أو دليل التوجيه'
                    : 'Changer de niveau ou accéder à l\'Orientation',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const LevelSelectionScreen(isChangingGrade: true),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF162032)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0F5132)
                            .withValues(alpha: isDark ? 0.5 : 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF0F5132),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F5132).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            curriculum.shortLevelAndBranchCode,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F5132),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          langService.isArabic ? 'تغيير' : 'Changer',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF0F5132),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // On Web (Desktop): Show Windows App Download CTA button (never show inside native Windows app)
          if (kIsWeb && MediaQuery.of(context).size.width >= 700) ...[
            FilledButton.icon(
              onPressed: _openWindowsDownload,
              icon: const Icon(
                Icons.download_rounded,
                size: 17,
                color: Colors.white,
              ),
              label: Text(
                langService.isArabic ? 'تحميل تطبيق الويندوز' : 'Télécharger PC',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: Colors.white,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 6),
          ],

          // On PC/Desktop: Show Offline and Favorites in AppBar
          if (MediaQuery.of(context).size.width >= 700) ...[
            IconButton(
              icon: Badge(
                isLabelVisible: downloadService.allDownloads.isNotEmpty,
                label: Text('${downloadService.allDownloads.length}'),
                backgroundColor: const Color(0xFF10B981),
                child: const Icon(Icons.offline_pin_rounded),
              ),
              tooltip: 'Mes Cours Hors-ligne (${downloadService.allDownloads.length} docs)',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OfflineDownloadsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Badge(
                isLabelVisible: favoritesService.allFavorites.isNotEmpty,
                label: Text('${favoritesService.allFavorites.length}'),
                backgroundColor: const Color(0xFFF59E0B),
                child: const Icon(Icons.star_rounded),
              ),
              tooltip: 'Mes Favoris (${favoritesService.allFavorites.length} sauvés)',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FavoritesScreen(),
                  ),
                );
              },
            ),
          ],

          // Google Auth profile / sign in button
          Consumer<AuthService>(
            builder: (context, auth, _) {
              if (auth.isAuthenticated) {
                final user = auth.currentUser!;
                return PopupMenuButton<String>(
                  tooltip: user.displayName,
                  offset: const Offset(0, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF0F5132),
                      child: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded,
                              size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            langService.tr('auth_sign_out'),
                            style:
                                const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'logout') {
                      auth.signOut();
                    }
                  },
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextButton.icon(
                    onPressed: () => _showGoogleSignInDialog(),
                    icon: const Icon(Icons.account_circle_outlined, size: 18),
                    label: Text(
                      langService.isArabic ? 'دخول' : 'Connexion',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0F5132),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                );
              }
            },
          ),

          // Student analytics / profile data button
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: langService.isArabic
                ? 'فضاء التلميذ والإحصائيات'
                : 'Mon Espace & Statistiques',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ProfileAnalyticsScreen()),
              );
            },
          ),

          // Orientation Post-Bac icon (Only on desktop/PC; on mobile it is in the quick action card)
          if (MediaQuery.of(context).size.width >= 700)
            IconButton(
              icon: const Icon(Icons.explore_outlined),
              tooltip: langService.isArabic
                  ? 'دليل التوجيه لما بعد الباك 2026'
                  : 'Orientation Post-Bac 2026',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/orientation'),
                    builder: (_) => const OrientationScreen(),
                  ),
                );
              },
            ),

          // Focus / Pomodoro mode icon (Respects settings preference)
          if (context.watch<FocusTimerService>().showHomeIcon)
            IconButton(
              icon: const Icon(Icons.self_improvement_rounded),
              tooltip: langService.isArabic
                  ? 'فضاء التركيز والمذاكرة (بومودورو)'
                  : 'Espace de Concentration (Pomodoro)',
              visualDensity: VisualDensity.compact,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FocusModeScreen()),
                );
              },
            ),

          // Search button
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: langService.isArabic ? 'بحث شامل' : 'Recherche globale',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),

          // Theme toggle (Only on desktop/PC; on mobile it is in Settings)
          if (widget.onToggleTheme != null && MediaQuery.of(context).size.width >= 700)
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              ),
              tooltip: isDark
                  ? (langService.isArabic ? 'الوضع النهاري' : 'Mode clair')
                  : (langService.isArabic ? 'الوضع الليلي' : 'Mode sombre'),
              visualDensity: VisualDensity.compact,
              onPressed: widget.onToggleTheme,
            ),

          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: langService.tr('settings_title'),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    onToggleTheme: widget.onToggleTheme,
                    isDarkMode: isDark,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 700;
          final showSideBanners = constraints.maxWidth >= 1050;

          final mainGridContent = RefreshIndicator(
            color: const Color(0xFF0F5132),
            onRefresh: () async {
              await curriculum.refreshCurriculumNow();
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  _onHomeScrollSettled(notification.metrics, subjects);
                }
                return false;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Level & Branch selector (Only on mobile phone screens)
                  if (!isDesktop)
                    const SliverToBoxAdapter(
                      child: LevelBranchSelector(),
                    ),

                  // Quick Action Cards (Only on mobile phone screens)
                  if (!isDesktop)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                        child: Row(
                          children: [
                            // Offline Downloads Card
                            Expanded(
                              child: _buildQuickActionCard(
                                context: context,
                                title: 'Hors-ligne',
                                subtitle:
                                    '${downloadService.allDownloads.length} docs',
                                icon: Icons.offline_pin_rounded,
                                iconColor: const Color(0xFF10B981),
                                isDark: isDark,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const OfflineDownloadsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Favorites Card
                            Expanded(
                              child: _buildQuickActionCard(
                                context: context,
                                title: 'Favoris',
                                subtitle:
                                    '${favoritesService.allFavorites.length} sauvés',
                                icon: Icons.star_rounded,
                                iconColor: const Color(0xFFF59E0B),
                                isDark: isDark,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const FavoritesScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Orientation Card (Replacing static "Programme" card)
                            Expanded(
                              child: _buildQuickActionCard(
                                context: context,
                                title: langService.isArabic ? 'التوجيه' : 'Orientation',
                                subtitle: langService.isArabic ? 'دليل ومحاكي' : 'Écoles & Guide',
                                icon: Icons.explore_rounded,
                                iconColor: const Color(0xFF2563EB),
                                isDark: isDark,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      settings: const RouteSettings(name: '/orientation'),
                                      builder: (_) => const OrientationScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Section Title: Matières
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        isDesktop ? 6 : 12,
                        16,
                        isDesktop ? 6 : 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Matières (${subjects.length}) • $totalDocsInBranch docs',
                            style: TextStyle(
                              fontSize: isDesktop ? 16.5 : 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Subject Grid: exactly 3 cards per row on desktop (centered), 2 on mobile
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, isDesktop ? 24 : 32),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 3 : 2,
                        crossAxisSpacing: isDesktop ? 14 : 14,
                        mainAxisSpacing: isDesktop ? 12 : 14,
                        mainAxisExtent: isDesktop ? 138 : 116,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return SubjectGridCard(subject: subjects[index]);
                        },
                        childCount: subjects.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          if (!showSideBanners) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: mainGridContent,
              ),
            );
          }

          // Desktop with Left Banner (Suggestions/Examens), Center (3 cards), and Right Banner (Motivation)
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Vertical Banner
              SizedBox(
                width: 240,
                child: _buildLeftBanner(context, isDark, langService),
              ),

              // Centered Main Content
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: mainGridContent,
                  ),
                ),
              ),

              // Right Vertical Banner
              SizedBox(
                width: 240,
                child: _buildRightBanner(context, isDark, langService),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftBanner(
    BuildContext context,
    bool isDark,
    AppLanguageService langService,
  ) {
    final curriculum = context.watch<CurriculumService>();
    final userProfile = context.watch<UserProfileService>();
    final focusTimer = context.watch<FocusTimerService>();

    final banners = SmartBannerService.getLeftBanners(
      context: context,
      curriculum: curriculum,
      userProfile: userProfile,
      focusTimer: focusTimer,
      langService: langService,
      onWindowsDownload: _openWindowsDownload,
    );

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: banners.map((banner) {
            return SmartBannerCardWidget(
              item: banner,
              isDark: isDark,
              langService: langService,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRightBanner(
    BuildContext context,
    bool isDark,
    AppLanguageService langService,
  ) {
    final curriculum = context.watch<CurriculumService>();
    final userProfile = context.watch<UserProfileService>();
    final focusTimer = context.watch<FocusTimerService>();

    final banners = SmartBannerService.getRightBanners(
      context: context,
      curriculum: curriculum,
      userProfile: userProfile,
      focusTimer: focusTimer,
      langService: langService,
      onWindowsDownload: _openWindowsDownload,
    );

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: banners.map((banner) {
            return SmartBannerCardWidget(
              item: banner,
              isDark: isDark,
              langService: langService,
            );
          }).toList(),
        ),
      ),
    );
  }


  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 16),
                    ),
                    Flexible(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: iconColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
