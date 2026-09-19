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
  bool _showWindowsBanner = true;

  Future<void> _openWindowsDownload() async {
    const url =
        'https://github.com/badrabm2007-design/CoursMaroc-Windows/releases/download/v1.0.0/CoursMaroc_Windows_v1.0.0.zip';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CurriculumService>().checkForRemoteUpdate();
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
          // On PC/Desktop: Show Windows App CTA button
          if (MediaQuery.of(context).size.width >= 700) ...[
            TextButton.icon(
              onPressed: _openWindowsDownload,
              icon: const Icon(
                Icons.laptop_windows_rounded,
                size: 17,
                color: Color(0xFF0F5132),
              ),
              label: Text(
                langService.isArabic ? 'تطبيق الحاسوب' : 'Version PC',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: Color(0xFF0F5132),
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132).withValues(
                  alpha: isDark ? 0.25 : 0.08,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
            const SizedBox(width: 4),
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
                  // Windows App Download Announcement Banner
                  SliverToBoxAdapter(
                    child: _buildWindowsAppDownloadBanner(
                        context, isDark, isDesktop),
                  ),

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
                      isAr ? 'الامتحانات والفروض' : 'Épreuves & Examens',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isAr ? 'التحضير الرسمي' : 'Préparation officielle',
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
            isAr
                ? 'مواضيع الامتحانات الوطنية والجهوية وفروض المراقبة مع عناصر الإجابة الرسمية.'
                : 'Sujets récents d\'examens régionaux, nationaux et contrôles avec leurs corrigés détaillés.',
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
            text: isAr
                ? 'عناصر إجابة مفصلة وسلالم تنقيط'
                : 'Corrigés détaillés & barèmes officiels',
            isDark: isDark,
          ),
          _buildBulletItem(
            icon: Icons.verified_outlined,
            iconColor: const Color(0xFF2563EB),
            text: isAr
                ? 'مطابقة للأطر المرجعية المحينة'
                : 'Conformes aux cadres de référence',
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
                    isAr
                        ? 'نصيحة: تدرب في نفس المدة الزمنية المحددة للامتحان.'
                        : 'Astuce : simulez l\'épreuve en temps réel pour gérer votre timing.',
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
                  Icons.lightbulb_rounded,
                  color: Color(0xFF0F5132),
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'نصائح ومنهجية' : 'Conseil & Méthode',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isAr ? 'تنظيم وتفوق' : 'Organisation & Réussite',
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

          // Clear, concise advice
          Text(
            isAr
                ? 'اعتمد منهجية مراجعة منظمة وثابتة لتحقيق أفضل النتائج والتقدم بثقة.'
                : 'Adoptez une méthode de révision structurée et régulière pour progresser sereinement.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),

          // 2 Key Method Highlights
          _buildBulletItem(
            icon: Icons.timer_outlined,
            iconColor: const Color(0xFF0F5132),
            text: isAr
                ? 'قاعدة 25/5: 25 دقيقة تركيز + 5 دقائق راحة'
                : 'Règle 25/5 : 25 min d\'effort + 5 min de pause',
            isDark: isDark,
          ),
          _buildBulletItem(
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFF0F5132),
            text: isAr
                ? 'بطاقات تلخيصية: لخص القوانين والصيغ'
                : 'Fiches clés : résumez les formules essentielles',
            isDark: isDark,
          ),

          const SizedBox(height: 8),

          // Compact Memory Tip Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4338CA)
                  .withValues(alpha: isDark ? 0.15 : 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF4338CA).withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.bedtime_outlined,
                    color: Color(0xFF4338CA),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    isAr
                        ? 'تثبيت الذاكرة: النوم الكافي يرسخ 80% من المعلومات.'
                        : 'Mémoire : un bon sommeil consolide 80% de vos acquis.',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFFC7D2FE)
                          : const Color(0xFF3730A3),
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
            child: ElevatedButton.icon(
              icon: const Icon(Icons.analytics_outlined, size: 15),
              label: Text(
                isAr ? 'مساحة المتابعة' : 'Mon Espace Suivi',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileAnalyticsScreen(),
                  ),
                );
              },
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

  Widget _buildWindowsAppDownloadBanner(
      BuildContext context, bool isDark, bool isDesktop) {
    if (!_showWindowsBanner) return const SizedBox.shrink();

    final langService = context.watch<AppLanguageService>();
    final isAr = langService.isArabic;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0F3A27),
                  const Color(0xFF142B20),
                ]
              : [
                  const Color(0xFFE8F5E9),
                  const Color(0xFFF1F8F4),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF0F5132).withValues(alpha: isDark ? 0.6 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -4,
            right: isAr ? null : -4,
            left: isAr ? -4 : null,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              visualDensity: VisualDensity.compact,
              tooltip: isAr ? 'إغلاق' : 'Masquer',
              onPressed: () {
                setState(() {
                  _showWindowsBanner = false;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F5132),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.laptop_windows_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAr
                            ? '🎉 متوفر الآن : تطبيق دروس المغرب للحاسوب (Windows) !'
                            : '🎉 Nouveau : Application Cours Maroc pour PC Windows !',
                        style: TextStyle(
                          fontSize: isDesktop ? 15.5 : 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F5132),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'حمّل النسخة الرسمية للكمبيوتر لتصفح الدروس والملخصات بسرعة فائقة، وحفظها للمراجعة بدون إنترنت.'
                            : 'Téléchargez la version PC pour consulter vos cours ultra-rapidement, prendre des notes et réviser hors-ligne sur grand écran.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _openWindowsDownload,
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: Text(
                              isAr
                                  ? 'تحميل للويندوز (.zip مجاناً)'
                                  : 'Télécharger pour Windows (.zip)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F5132),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(
                                alpha: isDark ? 0.25 : 0.15,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(
                                  alpha: isDark ? 0.6 : 0.4,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.android_rounded,
                                  size: 16,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isAr
                                      ? 'تطبيق الهاتف (أندرويد) : في مرحلة الاختبار المغلق حالياً'
                                      : 'App Android : En test fermé actuellement',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFFFDE68A)
                                        : const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
