import 'package:flutter/material.dart';
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
import '../services/app_language_service.dart';
import '../services/auth_service.dart';
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
        'https://github.com/badrabm2007-design/CoursMaroc-Windows/releases/download/v1.0.0/CoursMaroc_Windows_v1.0.0.zip';
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
                await context.read<AuthService>().signInWithGoogle();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(langService.tr('auth_sync_active')),
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
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
              InkWell(
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
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF162032)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
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
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${curriculum.currentLevel.localizedName(langService.currentLanguageCode)} • ${curriculum.currentBranch.localizedName(langService.currentLanguageCode)}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Color(0xFF0F5132),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // On PC/Desktop: Show Windows App Download CTA button
          if (MediaQuery.of(context).size.width >= 700) ...[
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

          // Theme toggle
          if (widget.onToggleTheme != null)
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

                            // Total Docs in Branch
                            Expanded(
                              child: _buildQuickActionCard(
                                context: context,
                                title: 'Programme',
                                subtitle: '$totalDocsInBranch docs',
                                icon: Icons.library_books_rounded,
                                iconColor: const Color(0xFF2563EB),
                                isDark: isDark,
                                onTap: () {},
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
                          Text(
                            curriculum.currentBranch.shortOrCode(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
                        mainAxisExtent: isDesktop ? 138 : 165,
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

  Widget _buildBulletItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.3,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftBanner(
    BuildContext context,
    bool isDark,
    AppLanguageService langService,
  ) {
    final isAr = langService.isArabic;
    final curriculum = context.watch<CurriculumService>();
    final levelId = curriculum.selectedLevelId;

    String title;
    String subtitle;
    String description;
    String bullet1;
    String bullet2;
    String tipText;

    switch (levelId) {
      case '3eme-annee-college':
        title = isAr ? 'امتحانات 3 إعدادي' : 'Examens 3ème Collège';
        subtitle = isAr ? 'محلي (د1) وجهوي (د2)' : 'Local (S1) & Régional (S2)';
        description = isAr
            ? 'نماذج الامتحانات الموحدة المحلية والجهوية بجميع جهات المملكة مع عناصر الإجابة الرسمية.'
            : 'Épreuves normalisées locales (S1) et régionales (S2) avec corrigés détaillés conformes.';
        bullet1 = isAr ? 'الامتحان الموحد المحلي (دورة يناير)' : 'Examen Local Normalisé (Janvier)';
        bullet2 = isAr ? 'الامتحان الجهوي الموحد (دورة يونيو)' : 'Examen Régional Normalisé (Juin)';
        tipText = isAr
            ? 'نصيحة: ابدأ بحل مواضيع الامتحان المحلي فور إنهاء دروس الدورة 1 لضمان أعلى معدل.'
            : 'Astuce : commencez l\'entraînement sur les épreuves locales dès la fin du semestre 1.';
        break;
      case '1ere-bac':
        title = isAr ? 'الامتحان الجهوي (1 باك)' : 'Examen Régional (1BAC)';
        subtitle = isAr ? 'المواد المعنية بالجهوي' : 'Matières du Régional';
        description = isAr
            ? 'مواضيع الامتحانات الجهوية الموحدة لجميع أكاديميات المملكة مع أطر التصحيح.'
            : 'Sujets récents d\'examens régionaux avec corrigés officiels et barèmes détaillés.';
        bullet1 = isAr ? 'الفرنسية، التربية الإسلامية، الاجتماعيات، العربية' : 'Français, Éduc. Islamique, Arabe, Hist-Géo';
        bullet2 = isAr ? 'نماذج محينة وفق الأطر المرجعية' : 'Conformes aux cadres de référence';
        tipText = isAr
            ? 'نصيحة: ركز على تحليل مؤلفات الفرنسية والتربية الإسلامية لرفع معدل الجهوي.'
            : 'Astuce : maîtrisez les œuvres de Français et les axes d\'Éducation Islamique.';
        break;
      case 'tronc-commun':
        title = isAr ? 'فروض المراقبة (جذع مشترك)' : 'Contrôles Tronc Commun';
        subtitle = isAr ? 'فروض وتمارين الدورة 1 و 2' : 'Préparation continue S1 & S2';
        description = isAr
            ? 'سلاسل الفروض المحروسة والتمارين النموذجية مع التصحيح لتثبيت المعارف.'
            : 'Modèles de devoirs surveillés et exercices corrigés pour consolider vos bases.';
        bullet1 = isAr ? 'فروض محروسة نموذجية مع التصحيح' : 'Contrôles continus 1, 2 et 3 corrigés';
        bullet2 = isAr ? 'تمارين تدريبية تطبيقية محددة' : 'Exercices d\'application ciblés';
        tipText = isAr
            ? 'نصيحة: ضبط دروس الجذع المشترك هو أساس تفوقك في سلك البكالوريا.'
            : 'Conseil : le Tronc Commun forge les fondations de votre cursus du Baccalauréat.';
        break;
      case '2eme-bac':
      default:
        title = isAr ? 'الامتحان الوطني (2 باك)' : 'Examen National (2BAC)';
        subtitle = isAr ? 'التحضير الرسمي للباكالوريا' : 'Préparation officielle';
        description = isAr
            ? 'مواضيع الامتحانات الوطنية الموحدة وفروض المراقبة مع عناصر الإجابة وسلالم التنقيط.'
            : 'Sujets d\'examens nationaux, régionaux et contrôles avec leurs corrigés officiels.';
        bullet1 = isAr ? 'عناصر إجابة مفصلة وسلالم تنقيط' : 'Corrigés détaillés & barèmes officiels';
        bullet2 = isAr ? 'مطابقة للأطر المرجعية المحينة' : 'Conformes aux cadres de référence';
        tipText = isAr
            ? 'نصيحة: تدرب في نفس المدة الزمنية المحددة للامتحان الوطني.'
            : 'Astuce : simulez l\'épreuve en temps réel pour gérer votre timing.';
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 6, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Color(0xFF2563EB),
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Clear, concise description
          Text(
            description,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),

          // 2 Key Highlights
          _buildBulletItem(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF16A34A),
            text: bullet1,
            isDark: isDark,
          ),
          _buildBulletItem(
            icon: Icons.verified_outlined,
            iconColor: const Color(0xFF2563EB),
            text: bullet2,
            isDark: isDark,
          ),

          const SizedBox(height: 8),

          // Compact Tip Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706)
                  .withValues(alpha: isDark ? 0.15 : 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFD97706),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    tipText,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.search_rounded, size: 15),
              label: Text(
                isAr ? 'بحث في الامتحانات' : 'Rechercher épreuve',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightBanner(
    BuildContext context,
    bool isDark,
    AppLanguageService langService,
  ) {
    final isAr = langService.isArabic;
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 10, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5132).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.laptop_windows_rounded,
                  color: Color(0xFF0F5132),
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'تطبيق الحاسوب' : 'Application PC Windows',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isAr ? 'دروس المغرب لويندوز' : 'Cours Maroc pour Windows',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF0F5132),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Promo Description
          Text(
            isAr
                ? 'استمتع بمذاكرة مريحة على شاشة حاسوبك بدون إنترنت، بتصفح سريع وأدوات متقدمة.'
                : 'Installez l\'application officielle sur votre PC pour réviser sur grand écran, 100% hors-ligne et avec fluidité.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),

          // Feature Highlights
          _buildBulletItem(
            icon: Icons.offline_pin_rounded,
            iconColor: const Color(0xFF0F5132),
            text: isAr
                ? 'مراجعة كاملة بدون إنترنت (100% Hors-ligne)'
                : '100% Hors-ligne : vos cours partout sans réseau',
            isDark: isDark,
          ),
          _buildBulletItem(
            icon: Icons.speed_rounded,
            iconColor: const Color(0xFF0F5132),
            text: isAr
                ? 'تصفح وفتح سريع للمستندات والامتحانات'
                : 'Navigation ultra-rapide sur grand écran',
            isDark: isDark,
          ),
          _buildBulletItem(
            icon: Icons.draw_rounded,
            iconColor: const Color(0xFF0F5132),
            text: isAr
                ? 'أدوات قراءة متقدمة، زوم وتكبير ذكي'
                : 'Lecture fluide, zoom et outils de révision',
            isDark: isDark,
          ),

          const SizedBox(height: 10),

          // Primary Download Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(
                isAr ? 'تحميل للويندوز (.zip)' : 'Télécharger pour Windows (.zip)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              onPressed: _openWindowsDownload,
            ),
          ),

          const SizedBox(height: 10),

          // Android Closed Test Status Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.4 : 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.android_rounded,
                  size: 15,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    isAr
                        ? 'تطبيق أندرويد : في مرحلة الاختبار المغلق'
                        : 'App Android : En test fermé actuellement',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

extension on BranchOption {
  String shortOrCode() {
    switch (id) {
      case 'sciences':
        return 'Tronc Commun Sc.';
      case 'sciences-experimentales':
        return '1BAC Sc. Exp';
      case 'sciences-maths':
        return 'Sc. Maths';
      case 'sciences-physiques':
        return '2BAC PC';
      case 'sciences-svt':
        return '2BAC SVT';
      case 'sciences-economiques':
        return '2BAC Éco';
      case 'sciences-economiques-et-gestion':
        return '1BAC Éco-Gestion';
      case 'lettres-et-sciences-humaines':
        return levelId == 'tronc-commun' ? 'TC Lettres' : '1BAC Lettres';
      case 'technologie':
        return 'TC Tech';
      default:
        return nameFr;
    }
  }
}
