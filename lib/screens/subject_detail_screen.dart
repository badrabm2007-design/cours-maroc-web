import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/curriculum_models.dart';
import '../services/app_language_service.dart';
import '../services/curriculum_service.dart';
import '../services/download_service.dart';
import '../services/focus_timer_service.dart';
import '../services/smart_prefetch_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/document_card.dart';

class SubjectDetailScreen extends StatefulWidget {
  final SubjectItem subject;
  final String? levelId;
  final String? initialCategory;

  const SubjectDetailScreen({
    super.key,
    required this.subject,
    this.levelId,
    this.initialCategory,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _availableCategories;

  // Selected semester filter: 'semestre-1', 'semestre-2'
  String _selectedSemester = 'semestre-1';
  final Set<String> _expandedRegionIds = {};
  bool _onlyCorriges = false;
  String _selectedExamSession = 'all'; // 'all', 'normale', 'rattrapage'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> regionalSubjects1BacSciencesAndEco = [
    'arabe',
    'francais',
    'education-islamique',
    'histoire-geographie',
  ];

  static const List<String> regionalSubjects1BacLettres = [
    'francais',
    'education-islamique',
    'mathematiques',
  ];

  static const List<String> nationalSubjects2Bac = [
    'mathematiques',
    'physique-chimie',
    'svt',
    'philosophie',
    'anglais',
    // 2BAC Sciences Économiques official national exam subjects:
    'economie-generale',
    'comptabilite',
    'organisation-entreprises',
    'sciences-ingenieur',
  ];

  String get _effectiveLevelId {
    if (widget.levelId != null && widget.levelId!.isNotEmpty) {
      return widget.levelId!;
    }
    return context.read<UserProfileService>().savedLevelId;
  }

  String get _effectiveBranchId {
    return context.read<UserProfileService>().savedBranchId;
  }

  bool _isOfficialExamSubject(String level, String subjectId) {
    if (level == '1ere-bac') {
      if (_effectiveBranchId == 'lettres-et-sciences-humaines') {
        return regionalSubjects1BacLettres.contains(subjectId);
      }
      return regionalSubjects1BacSciencesAndEco.contains(subjectId);
    }
    if (level == '2eme-bac') {
      return nationalSubjects2Bac.contains(subjectId);
    }
    return false;
  }

  String _effectiveDocCategory(DocumentItem doc) {
    if (doc.category == 'examens') {
      if (_isOfficialExamSubject(_effectiveLevelId, widget.subject.meta.id)) {
        return 'examens';
      }
      return 'controles';
    }
    return doc.category;
  }

  @override
  void initState() {
    super.initState();
    _initCategories();
  }

  void _initCategories() {
    final categoriesSet = <String>{};
    for (final doc in widget.subject.documents) {
      categoriesSet.add(_effectiveDocCategory(doc));
    }

    // Only include 'examens' if this subject officially has regional (1BAC) or national (2BAC) exams
    // AND actually has exam documents available!
    final hasOfficialExams =
        _isOfficialExamSubject(_effectiveLevelId, widget.subject.meta.id);
    final hasExamDocuments = widget.subject.documents
        .any((d) => _effectiveDocCategory(d) == 'examens');

    if (hasOfficialExams && hasExamDocuments) {
      categoriesSet.add('examens');
    } else {
      categoriesSet.remove('examens');
    }

    // Preferred pedagogical order:
    // 1. Cours
    // 2. Résumés
    // 3. Exercices
    // 4. Contrôles continus
    // 5. Régionaux / Nationaux (examens)
    const preferredOrder = [
      'cours',
      'resumes',
      'exercices',
      'controles',
      'examens',
    ];
    _availableCategories =
        preferredOrder.where((c) => categoriesSet.contains(c)).toList();

    for (final c in categoriesSet) {
      if (!_availableCategories.contains(c)) {
        _availableCategories.add(c);
      }
    }

    if (_availableCategories.isEmpty) {
      _availableCategories = ['cours'];
    }

    int initialIndex = 0;
    if (widget.initialCategory != null) {
      final foundIdx = _availableCategories.indexOf(widget.initialCategory!);
      if (foundIdx != -1) {
        initialIndex = foundIdx;
      }
    }

    _tabController = TabController(
      length: _availableCategories.length,
      initialIndex: initialIndex,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final currentCat = _availableCategories[
            _tabController.index.clamp(0, _availableCategories.length - 1)];
        // Auto-disable corrigé filter if switching away from exercices/controles/examens
        if (currentCat != 'exercices' && currentCat != 'controles' && currentCat != 'examens') {
          if (_onlyCorriges) {
            _onlyCorriges = false;
          }
        }
        setState(() {});

        // Predictive smart pre-caching: prefetch top documents in OTHER tabs and current category
        try {
          final showCorriges = currentCat == 'exercices' || currentCat == 'controles';
          context.read<FocusTimerService>().updateSubjectDetailCorriges(showCorriges);
          final smartPrefetch = context.read<SmartPrefetchService>();
          final profile = context.read<UserProfileService>();
          final dl = context.read<DownloadService>();

          // Anticipate other tabs
          smartPrefetch.prefetchSubjectOtherTabs(
            subject: widget.subject,
            activeCategory: currentCat,
            userProfile: profile,
            downloadService: dl,
          );

          // Also prefetch active category's predicted documents
          final catDocs = _getFilteredDocuments(currentCat);
          smartPrefetch.prefetchDocumentListScroll(
            visibleDocuments: catDocs,
            downloadService: dl,
            maxCount: 3,
          );
        } catch (_) {}
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final initialCat = _availableCategories.first;
        final showCorriges = initialCat == 'exercices' || initialCat == 'controles';
        context.read<FocusTimerService>().pushDockingScreen(
              ActiveDockingScreen.subjectDetail,
              hasCorriges: showCorriges,
            );
        final smartPrefetch = context.read<SmartPrefetchService>();
        final profile = context.read<UserProfileService>();
        final dl = context.read<DownloadService>();

        // Pre-download other tabs in background
        smartPrefetch.prefetchSubjectOtherTabs(
          subject: widget.subject,
          activeCategory: initialCat,
          userProfile: profile,
          downloadService: dl,
        );

        // Pre-download top documents of initial tab
        final initialDocs = _getFilteredDocuments(initialCat);
        smartPrefetch.prefetchDocumentListScroll(
          visibleDocuments: initialDocs,
          downloadService: dl,
          maxCount: 4,
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    try {
      context.read<FocusTimerService>().popDockingScreen(ActiveDockingScreen.subjectDetail);
    } catch (_) {}
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getCategoryLabel(String cat, AppLanguageService langService) {
    switch (cat) {
      case 'cours':
        return langService.tr('tab_cours');
      case 'exercices':
        return langService.tr('tab_exercices');
      case 'controles':
        return langService.tr('tab_controles');
      case 'examens':
        if (_effectiveLevelId == '1ere-bac') {
          return langService.tr('tab_regionaux');
        }
        if (_effectiveLevelId == '2eme-bac') {
          return langService.tr('tab_nationaux');
        }
        return langService.tr('tab_examens');
      case 'resumes':
        return langService.tr('tab_resumes');
      default:
        return cat.toUpperCase();
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'cours':
        return Icons.menu_book_rounded;
      case 'exercices':
        return Icons.edit_note_rounded;
      case 'controles':
        return Icons.assignment_rounded;
      case 'examens':
        if (_effectiveLevelId == '1ere-bac') {
          return Icons.workspace_premium_rounded;
        }
        return Icons.military_tech_rounded;
      case 'resumes':
        return Icons.summarize_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  bool _docMatchesRegion(DocumentItem doc, String regionId) {
    if (regionId == 'all') return true;
    if (doc.region != null && doc.region!.isNotEmpty) {
      return doc.region == regionId;
    }
    final t = doc.title.toLowerCase();
    for (final r in MoroccanRegion.all) {
      if (r.id == regionId) {
        if (t.contains(r.nameFr.toLowerCase()) ||
            t.contains(r.nameAr) ||
            t.contains(r.shortName.toLowerCase())) {
          return true;
        }
      }
    }
    if (regionId == 'casablanca-settat' &&
        (t.contains('casablanca') ||
            t.contains('settat') ||
            t.contains('الدار البيضاء') ||
            t.contains('casa') ||
            t.contains('chaouia'))) {
      return true;
    }
    if (regionId == 'rabat-sale-kenitra' &&
        (t.contains('rabat') ||
            t.contains('salé') ||
            t.contains('sale') ||
            t.contains('kénitra') ||
            t.contains('kenitra') ||
            t.contains('الرباط') ||
            t.contains('gharb'))) {
      return true;
    }
    if (regionId == 'fes-meknes' &&
        (t.contains('fès') ||
            t.contains('fes') ||
            t.contains('meknès') ||
            t.contains('meknes') ||
            t.contains('فاس') ||
            t.contains('taza'))) {
      return true;
    }
    if (regionId == 'marrakech-safi' &&
        (t.contains('marrakech') ||
            t.contains('safi') ||
            t.contains('مراكش') ||
            t.contains('doukkala'))) {
      return true;
    }
    if (regionId == 'tanger-tetouan-al-hoceima' &&
        (t.contains('tanger') ||
            t.contains('tétouan') ||
            t.contains('tetouan') ||
            t.contains('al hoceïma') ||
            t.contains('al hoceima') ||
            t.contains('طنجة') ||
            t.contains('larache'))) {
      return true;
    }
    if (regionId == 'souss-massa' &&
        (t.contains('souss') ||
            t.contains('massa') ||
            t.contains('agadir') ||
            t.contains('سوس') ||
            t.contains('sous'))) {
      return true;
    }
    if (regionId == 'beni-mellal-khenifra' &&
        (t.contains('béni mellal') ||
            t.contains('beni mellal') ||
            t.contains('khénifra') ||
            t.contains('khenifra') ||
            t.contains('بني ملال') ||
            t.contains('tadla'))) {
      return true;
    }
    if (regionId == 'oriental' &&
        (t.contains('oriental') ||
            t.contains('oujda') ||
            t.contains('الشرق') ||
            t.contains('orient'))) {
      return true;
    }
    if (regionId == 'draa-tafilalet' &&
        (t.contains('drâa') ||
            t.contains('draa') ||
            t.contains('tafilalet') ||
            t.contains('درعة'))) {
      return true;
    }
    if (regionId == 'guelmim-oued-noun' &&
        (t.contains('guelmim') ||
            t.contains('oued noun') ||
            t.contains('كلميم'))) {
      return true;
    }
    if (regionId == 'laayoune-sakia-el-hamra' &&
        (t.contains('laâyoune') ||
            t.contains('laayoune') ||
            t.contains('العيون'))) {
      return true;
    }
    if (regionId == 'dakhla-oued-ed-dahab' &&
        (t.contains('dakhla') ||
            t.contains('الداخلة'))) {
      return true;
    }

    return false;
  }

  bool _docMatchesExamSession(DocumentItem doc, String session) {
    if (session == 'all') return true;
    final t = '${doc.title} ${doc.name}'.toLowerCase();
    final isRatt = t.contains('rattrapage') ||
        t.contains('ratt') ||
        t.contains('استدراكية') ||
        t.contains('الاستدراكية') ||
        t.contains('-sr') ||
        t.contains('_sr');
    if (session == 'rattrapage') {
      return isRatt;
    }
    if (session == 'normale') {
      final isNorm = t.contains('normale') ||
          t.contains('normal') ||
          t.contains('عادية') ||
          t.contains('العادية') ||
          t.contains('-sn') ||
          t.contains('_sn');
      return isNorm || !isRatt;
    }
    return true;
  }

  List<DocumentItem> _getFilteredDocuments(String category) {
    final list = widget.subject.documents.where((doc) {
      if (_effectiveDocCategory(doc) != category) return false;

      // When in examens tab, filter by session & corrigé
      if (category == 'examens') {
        if (_onlyCorriges && !doc.isCorrige) return false;
        if (_effectiveLevelId == '2eme-bac' && _selectedExamSession != 'all') {
          if (!_docMatchesExamSession(doc, _selectedExamSession)) return false;
        }
      }

      // Semester filter (only applied to regular school year categories, not annual exams)
      // When searching, search across both semesters so student finds what they need
      if (_searchQuery.isEmpty && category != 'examens') {
        if (doc.semester != _selectedSemester) return false;
      }

      // Corrigé filter (for exercices and controles)
      if (_onlyCorriges &&
          (category == 'exercices' || category == 'controles')) {
        if (!doc.isCorrige) return false;
      }

      // Search query inside subject
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = doc.title.toLowerCase().contains(q);
        final matchName = doc.name.toLowerCase().contains(q);
        final matchRegionTag =
            doc.region != null && doc.region!.toLowerCase().contains(q);
        final matchRegionName = MoroccanRegion.all.any((r) =>
            _docMatchesRegion(doc, r.id) &&
            (r.nameFr.toLowerCase().contains(q) ||
                r.nameAr.contains(q) ||
                r.shortName.toLowerCase().contains(q)));
        if (!matchTitle && !matchName && !matchRegionTag && !matchRegionName) {
          return false;
        }
      }

      return true;
    }).toList();

    // In examens tab: sort strictly antéchronologiquement (2024 -> 2008), Sujets before Corrigés
    if (category == 'examens') {
      list.sort((a, b) {
        final yrA = a.examYear;
        final yrB = b.examYear;
        if (yrA != yrB) return yrB.compareTo(yrA); // Descending year: 2024, 2023, 2022...
        if (a.isCorrige != b.isCorrige) return a.isCorrige ? 1 : -1; // Sujets first
        return a.title.compareTo(b.title);
      });
    } else if (category == 'controles') {
      // In controles tab: sort by Contrôle / Devoir / Test number, then Model number (integer), Sujets before Corrigés
      list.sort((a, b) {
        final tA = '${a.title} ${a.name}'.toLowerCase();
        final tB = '${b.title} ${b.name}'.toLowerCase();

        final devA = _extractOrderNumber(
            tA, r'(?:contr[oô]le|devoir|test|فرض\s*محروس|إمتحان\s*محروس)\s*(\d+)');
        final devB = _extractOrderNumber(
            tB, r'(?:contr[oô]le|devoir|test|فرض\s*محروس|إمتحان\s*محروس)\s*(\d+)');
        if (devA != devB) return devA.compareTo(devB);

        final modA = _extractOrderNumber(tA, r'(?:mod[eè]le|mod|نموذج)\s*(\d+)');
        final modB = _extractOrderNumber(tB, r'(?:mod[eè]le|mod|نموذج)\s*(\d+)');
        if (modA != modB) return modA.compareTo(modB);

        if (a.isCorrige != b.isCorrige) return a.isCorrige ? 1 : -1;
        return a.title.compareTo(b.title);
      });
    }

    return list;
  }

  int _extractOrderNumber(String text, String pattern) {
    final m = RegExp(pattern).firstMatch(text);
    if (m != null) {
      return int.tryParse(m.group(1) ?? '') ?? 999;
    }
    return 999;
  }

  int _getEffectiveTotalCount(String category) {
    return widget.subject.documents
        .where((d) => _effectiveDocCategory(d) == category)
        .length;
  }

  String _getFilterSummary(String category) {
    final docs = _getFilteredDocuments(category);
    final total = _getEffectiveTotalCount(category);
    final count = docs.length;

    if (_searchQuery.isNotEmpty) {
      return '$count résultat${count > 1 ? 's' : ''} pour "$_searchQuery"';
    }
    if (category == 'examens') {
      final is1Bac = _effectiveLevelId == '1ere-bac';
      if (is1Bac) {
        if (_onlyCorriges) {
          return '$count examen${count > 1 ? 's' : ''} avec corrigé sur $total (12 régions)';
        }
        return '$count examens régionaux répartis sur les 12 régions';
      }
      if (_onlyCorriges) {
        return '$count examen${count > 1 ? 's' : ''} avec corrigé sur $total';
      }
      return '$count examens nationaux au total';
    }
    if (_onlyCorriges) {
      return '$count document${count > 1 ? 's' : ''} avec corrigé sur $total';
    }
    final semLabel =
        _selectedSemester == 'semestre-1' ? 'Semestre 1' : 'Semestre 2';
    return '$count document${count > 1 ? 's' : ''} ($semLabel)';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langService = context.watch<AppLanguageService>();
    final currentLang = langService.currentLanguageCode;
    final isArabic = currentLang == 'ar';
    final color = Color(widget.subject.colorHex);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final currentCategoryIndex =
        _tabController.index.clamp(0, _availableCategories.length - 1);
    final currentCategory = _availableCategories[currentCategoryIndex];
    final isExamTab = currentCategory == 'examens';
    final showCorrigesFilter =
        currentCategory == 'exercices' || currentCategory == 'controles';

    final allCategoryDocs = widget.subject.documents
        .where((d) => _effectiveDocCategory(d) == currentCategory)
        .toList();
    final s1Count =
        allCategoryDocs.where((d) => d.semester == 'semestre-1').length;
    final s2Count =
        allCategoryDocs.where((d) => d.semester == 'semestre-2').length;
    final corrigesCount = allCategoryDocs.where((d) => d.isCorrige).length;

    final hasFilterActive =
        (_onlyCorriges && (showCorrigesFilter || isExamTab)) ||
        _searchQuery.isNotEmpty;

    final primaryTitle = isArabic
        ? widget.subject.nameAr
        : widget.subject.meta.localizedName(currentLang);
    final secondaryTitle =
        isArabic ? widget.subject.nameFr : widget.subject.nameAr;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isDesktop ? 64 : null,
        automaticallyImplyLeading: !isDesktop,
        titleSpacing: isDesktop ? 0 : null,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: isDesktop
            ? SizedBox(
                width: double.infinity,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Left: Back Button + Subject Title
                    Positioned(
                      left: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  primaryTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  secondaryTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Center: Categories Selector (Always at the absolute center of the screen)
                    Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF131D2E)
                                : const Color(0xFFE9ECEF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E2E48)
                                  : const Color(0xFFDEE2E6),
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                List.generate(_availableCategories.length, (i) {
                              final cat = _availableCategories[i];
                              final totalCount = _getEffectiveTotalCount(cat);
                              final filteredCount =
                                  _getFilteredDocuments(cat).length;
                              final currentIdx = _tabController.index.clamp(
                                  0, _availableCategories.length - 1);
                              final isSelected = currentIdx == i;

                              return Padding(
                                padding: EdgeInsets.only(
                                  right: i < _availableCategories.length - 1
                                      ? 4.0
                                      : 0.0,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(9),
                                  onTap: () {
                                    _tabController.animateTo(i);
                                    setState(() {});
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? color : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: color.withValues(alpha: 0.35),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1.5),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getCategoryIcon(cat),
                                          size: 15,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF495057)),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _getCategoryLabel(cat, langService),
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark
                                                    ? Colors.white70
                                                    : const Color(
                                                        0xFF495057)),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white.withValues(alpha: 0.25)
                                                : (isDark
                                                    ? Colors.white10
                                                    : Colors.black.withValues(
                                                        alpha: 0.07)),
                                            borderRadius:
                                                BorderRadius.circular(7),
                                          ),
                                          child: Text(
                                            hasFilterActive &&
                                                    filteredCount != totalCount
                                                ? '$filteredCount/$totalCount'
                                                : '$totalCount',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isDark
                                                      ? Colors.white70
                                                      : const Color(
                                                          0xFF495057)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),

                    // 3. Right: Search Bar
                    Positioned(
                      right: 16,
                      child: SizedBox(
                        width: 250,
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: isExamTab
                                ? langService.tr('search_hint_exam')
                                : langService.tr('search_hint_subject'),
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            prefixIconConstraints:
                                const BoxConstraints(minWidth: 34, minHeight: 34),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 8),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF18233C)
                                : const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF2A3756)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF2A3756)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: color, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    secondaryTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
        bottom: isDesktop
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicatorColor: color,
                indicatorWeight: 3,
                labelColor: isDark ? Colors.white : color,
                unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                labelStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                tabs: _availableCategories.map((cat) {
                  final totalCount = _getEffectiveTotalCount(cat);
                  final filteredCount = _getFilteredDocuments(cat).length;

                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getCategoryIcon(cat), size: 18),
                        const SizedBox(width: 6),
                        Text(_getCategoryLabel(cat, langService)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                color.withValues(alpha: isDark ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            hasFilterActive && filteredCount != totalCount
                                ? '$filteredCount/$totalCount'
                                : '$totalCount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
        actions: isDesktop ? null : null,
      ),
      body: Column(
        children: [
          // 1. Semester Filter Bar (Semestre 1, Semestre 2) & Corrigé Toggle
          // Placed directly below the categories/tabs as requested!
          if (!isExamTab)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF111A2E) : Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: isDesktop ? 840 : double.infinity),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSemesterPill(
                            langService.tr('filter_s1'), 'semestre-1', s1Count, isDark),
                        const SizedBox(width: 8),
                        _buildSemesterPill(
                            langService.tr('filter_s2'), 'semestre-2', s2Count, isDark),

                        // Show Corrigé toggle ONLY in Exercices and Contrôles continus!
                        if (showCorrigesFilter) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 12),

                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(langService.tr('filter_corrige')),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: _onlyCorriges
                                        ? const Color(0xFF10B981)
                                        : (isDark
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$corrigesCount',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: _onlyCorriges
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF475569)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            selected: _onlyCorriges,
                            selectedColor:
                                const Color(0xFF10B981).withValues(alpha: 0.2),
                            checkmarkColor: const Color(0xFF10B981),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _onlyCorriges
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            onSelected: (val) {
                              setState(() {
                                _onlyCorriges = val;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              color: isDark ? const Color(0xFF111A2E) : Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: isDesktop ? 840 : double.infinity),
                  child: _buildExamFilterHeader(
                      context, isDark, langService, color, allCategoryDocs),
                ),
              ),
            ),

          // 2. Search Bar for this Subject on MOBILE only (on desktop it's in the AppBar)
          if (!isDesktop)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              color: isDark ? const Color(0xFF111A2E) : Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: isExamTab
                      ? langService.tr('search_hint_exam')
                      : langService.tr('search_hint_subject'),
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF18233C)
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          // 3. Active filter contextual summary banner
          if (hasFilterActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF162032) : const Color(0xFFF1F5F9),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF1F2E45)
                        : const Color(0xFFE2E8F0),
                  ),
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF1F2E45)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: isDesktop ? 840 : double.infinity),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 15,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFilterSummary(currentCategory),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _onlyCorriges = false;
                            _expandedRegionIds.clear();
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close_rounded, size: 14, color: color),
                              const SizedBox(width: 4),
                              Text(
                                isArabic ? 'إلغاء التصفية' : 'Réinitialiser',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            const Divider(height: 1, thickness: 1),

          // 4. Document list for each category tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _availableCategories.map((cat) {
                final docs = _getFilteredDocuments(cat);
                final totalCatCount = _getEffectiveTotalCount(cat);
                return _buildDocumentList(
                    docs, color, isDark, totalCatCount, cat);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterPill(
      String label, String value, int count, bool isDark) {
    final isSelected = _selectedSemester == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.25)
                  : (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0F5132),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : const Color(0xFF334155)),
      ),
      backgroundColor:
          isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedSemester = value;
          });
        }
      },
    );
  }

  Widget _buildExamSessionPill({
    required String label,
    required String value,
    required int count,
    required bool isDark,
    required Color activeColor,
  }) {
    final isSelected = _selectedExamSession == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.25)
                  : (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      selectedColor: activeColor,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : const Color(0xFF334155)),
      ),
      backgroundColor:
          isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedExamSession = value;
          });
        }
      },
    );
  }

  Widget _buildExamFilterHeader(
    BuildContext context,
    bool isDark,
    AppLanguageService langService,
    Color color,
    List<DocumentItem> examDocs,
  ) {
    final isArabic = langService.currentLanguageCode == 'ar';
    final totalCorriges = examDocs.where((d) => d.isCorrige).length;
    final is1Bac = _effectiveLevelId == '1ere-bac';

    if (!is1Bac) {
      final normaleCount =
          examDocs.where((d) => _docMatchesExamSession(d, 'normale')).length;
      final rattrapageCount =
          examDocs.where((d) => _docMatchesExamSession(d, 'rattrapage')).length;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        color: isDark ? const Color(0xFF111A2E) : Colors.white,
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildExamSessionPill(
                  label: isArabic ? 'الكل' : 'Toutes',
                  value: 'all',
                  count: examDocs.length,
                  isDark: isDark,
                  activeColor: color,
                ),
                const SizedBox(width: 8),
                _buildExamSessionPill(
                  label: isArabic ? 'الدورة العادية' : 'Normale',
                  value: 'normale',
                  count: normaleCount,
                  isDark: isDark,
                  activeColor: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                _buildExamSessionPill(
                  label: isArabic ? 'الاستدراكية' : 'Rattrapage',
                  value: 'rattrapage',
                  count: rattrapageCount,
                  isDark: isDark,
                  activeColor: const Color(0xFFD97706),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  avatar: Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color:
                        _onlyCorriges ? Colors.white : const Color(0xFF10B981),
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(langService.tr('filter_corrige')),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _onlyCorriges
                              ? Colors.white.withValues(alpha: 0.25)
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$totalCorriges',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _onlyCorriges
                                ? Colors.white
                                : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  selected: _onlyCorriges,
                  selectedColor: const Color(0xFF10B981),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _onlyCorriges
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  onSelected: (val) {
                    setState(() {
                      _onlyCorriges = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 800;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      color: isDark ? const Color(0xFF111A2E) : Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: isDesktop ? 840 : double.infinity),
          child: isDesktop
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    // Filter chip for Corrigé (centered in the middle!)
                    Center(
                      child: FilterChip(
                        avatar: Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: _onlyCorriges
                              ? Colors.white
                              : const Color(0xFF10B981),
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(langService.tr('filter_corrige')),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _onlyCorriges
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : (isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$totalCorriges',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _onlyCorriges
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF475569)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        selected: _onlyCorriges,
                        selectedColor: const Color(0xFF10B981),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _onlyCorriges
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        onSelected: (val) {
                          setState(() {
                            _onlyCorriges = val;
                          });
                        },
                      ),
                    ),

                    // For 1BAC Regional exams: Provide Expand All / Collapse All toggle button
                    if (is1Bac)
                      Positioned(
                        right: 0,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              if (_expandedRegionIds.length >=
                                  MoroccanRegion.all.length) {
                                _expandedRegionIds.clear();
                              } else {
                                _expandedRegionIds
                                    .addAll(MoroccanRegion.all.map((r) => r.id));
                              }
                            });
                          },
                          icon: Icon(
                            _expandedRegionIds.length >=
                                    MoroccanRegion.all.length
                                ? Icons.unfold_less_rounded
                                : Icons.unfold_more_rounded,
                            size: 17,
                            color: color,
                          ),
                          label: Text(
                            _expandedRegionIds.length >=
                                    MoroccanRegion.all.length
                                ? (isArabic ? 'طي الكل' : 'Tout replier')
                                : (isArabic ? 'فتح الكل' : 'Tout déplier'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: color.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilterChip(
                      avatar: Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: _onlyCorriges
                            ? Colors.white
                            : const Color(0xFF10B981),
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(langService.tr('filter_corrige')),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _onlyCorriges
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$totalCorriges',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _onlyCorriges
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      selected: _onlyCorriges,
                      selectedColor: const Color(0xFF10B981),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _onlyCorriges
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      onSelected: (val) {
                        setState(() {
                          _onlyCorriges = val;
                        });
                      },
                    ),
                    if (is1Bac) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (_expandedRegionIds.length >=
                                MoroccanRegion.all.length) {
                              _expandedRegionIds.clear();
                            } else {
                              _expandedRegionIds
                                  .addAll(MoroccanRegion.all.map((r) => r.id));
                            }
                          });
                        },
                        icon: Icon(
                          _expandedRegionIds.length >=
                                  MoroccanRegion.all.length
                              ? Icons.unfold_less_rounded
                              : Icons.unfold_more_rounded,
                          size: 17,
                          color: color,
                        ),
                        label: Text(
                          _expandedRegionIds.length >=
                                  MoroccanRegion.all.length
                              ? (isArabic ? 'طي الكل' : 'Tout replier')
                              : (isArabic ? 'فتح الكل' : 'Tout déplier'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: color.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  void _onScrollSettled(List<DocumentItem> docs, ScrollMetrics metrics) {
    if (docs.isEmpty) return;

    // Approximate height of each DocumentCard (including margins): ~70px
    const double approxItemHeight = 70.0;
    final double scrollOffset = metrics.pixels;
    final double viewportHeight = metrics.viewportDimension;

    // First visible item index based on scroll position
    final int firstVisible =
        (scrollOffset / approxItemHeight).floor().clamp(0, docs.length - 1);

    // Number of visible cards on screen
    final int visibleCount =
        ((viewportHeight / approxItemHeight).ceil() + 1).clamp(1, 6);

    final int lastVisible =
        (firstVisible + visibleCount).clamp(0, docs.length);

    if (firstVisible < lastVisible) {
      final visibleDocs = docs.sublist(firstVisible, lastVisible);
      // Automatically prefetch the 3-4 documents stopped under the user's eyes using SmartPrefetchService
      try {
        context.read<SmartPrefetchService>().prefetchDocumentListScroll(
              visibleDocuments: visibleDocs,
              downloadService: context.read<DownloadService>(),
              maxCount: 4,
            );
      } catch (_) {
        context.read<DownloadService>().prefetchDocuments(visibleDocs, maxCount: 4);
      }
    }
  }

  Widget _buildRegionalAccordionList(
    List<DocumentItem> docs,
    Color accentColor,
    bool isDark,
    int totalCategoryDocs,
  ) {
    if (docs.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF0F5132),
        onRefresh: () async {
          await context.read<CurriculumService>().refreshCurriculumNow();
        },
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 64,
                  color: accentColor.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Examens Régionaux (1ère Bac)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Aucun résultat pour "$_searchQuery".'
                      : (_onlyCorriges
                          ? 'Aucun document avec corrigé pour cette sélection'
                          : 'Les épreuves régionales pour cette matière seront disponibles très prochainement.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final langService = context.watch<AppLanguageService>();
    final isArabic = langService.currentLanguageCode == 'ar';

    final List<_RegionalListItem> flatItems = [];

    for (final reg in MoroccanRegion.all) {
      final regionDocs =
          docs.where((d) => _docMatchesRegion(d, reg.id)).toList();

      // If user is searching and this region has no matches, hide it
      if (_searchQuery.isNotEmpty && regionDocs.isEmpty) {
        continue;
      }

      final isExpanded = _searchQuery.isNotEmpty
          ? regionDocs.isNotEmpty
          : _expandedRegionIds.contains(reg.id);

      final corrigesCount = regionDocs.where((d) => d.isCorrige).length;
      final theme = _RegionVisualTheme.getTheme(reg.id);

      flatItems.add(_RegionHeaderItem(
        regionId: reg.id,
        title: isArabic ? reg.nameAr : reg.nameFr,
        subtitle: isArabic ? reg.nameFr : reg.nameAr,
        nickname: isArabic ? theme.nicknameAr : theme.nicknameFr,
        icon: theme.icon,
        totalCount: regionDocs.length,
        corrigesCount: corrigesCount,
        isExpanded: isExpanded,
        theme: theme,
        onTap: () {
          setState(() {
            if (_expandedRegionIds.contains(reg.id)) {
              _expandedRegionIds.remove(reg.id);
            } else {
              _expandedRegionIds.add(reg.id);
              if (regionDocs.isNotEmpty) {
                context
                    .read<DownloadService>()
                    .prefetchDocuments(regionDocs, maxCount: 2);
              }
            }
          });
        },
      ));

      if (isExpanded) {
        if (regionDocs.isEmpty) {
          flatItems.add(_RegionEmptyItem(
            message: 'Aucun examen avec les filtres sélectionnés.',
            theme: theme,
          ));
        } else {
          for (int i = 0; i < regionDocs.length; i++) {
            flatItems.add(_RegionDocItem(
              document: regionDocs[i],
              regionId: reg.id,
              theme: theme,
              categoryDocuments: regionDocs,
              documentIndex: i,
            ));
          }
        }
      }
    }

    // 13. Check for practice models / national tests (unmatched docs)
    final unmatchedDocs = docs
        .where((d) =>
            !MoroccanRegion.all.any((r) => _docMatchesRegion(d, r.id)))
        .toList();
    if (unmatchedDocs.isNotEmpty) {
      final isExpanded =
          _searchQuery.isNotEmpty || _expandedRegionIds.contains('other');
      final otherTheme = _RegionVisualTheme.getTheme('other');
      final otherCorriges = unmatchedDocs.where((d) => d.isCorrige).length;

      flatItems.add(_RegionHeaderItem(
        regionId: 'other',
        title: isArabic ? 'نماذج امتحانات وطنية وموحدة' : 'Épreuves nationales & modèles',
        subtitle: isArabic ? 'المغرب' : 'Maroc (National)',
        nickname: isArabic ? otherTheme.nicknameAr : otherTheme.nicknameFr,
        icon: otherTheme.icon,
        totalCount: unmatchedDocs.length,
        corrigesCount: otherCorriges,
        isExpanded: isExpanded,
        theme: otherTheme,
        onTap: () {
          setState(() {
            if (_expandedRegionIds.contains('other')) {
              _expandedRegionIds.remove('other');
            } else {
              _expandedRegionIds.add('other');
            }
          });
        },
      ));

      if (isExpanded) {
        for (int i = 0; i < unmatchedDocs.length; i++) {
          flatItems.add(_RegionDocItem(
            document: unmatchedDocs[i],
            regionId: 'other',
            theme: otherTheme,
            categoryDocuments: unmatchedDocs,
            documentIndex: i,
          ));
        }
      }
    }

    return RefreshIndicator(
      color: const Color(0xFF0F5132),
      onRefresh: () async {
        await context.read<CurriculumService>().refreshCurriculumNow();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            _onRegionalScrollSettled(flatItems, notification.metrics);
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 28),
          itemCount: flatItems.length,
          itemBuilder: (context, index) {
            final isDesktop = MediaQuery.of(context).size.width >= 800;
            final item = flatItems[index];
            Widget child;
            if (item is _RegionHeaderItem) {
              child = _buildRegionHeaderCard(item, isDark);
            } else if (item is _RegionDocItem) {
              child = DocumentCard(
                key: ValueKey('reg_${item.regionId}_${item.document.id}'),
                document: item.document,
                subjectName: widget.subject.nameFr,
                accentColor: item.theme.primaryColor,
                categoryDocuments: item.categoryDocuments,
                documentIndex: item.documentIndex,
              );
            } else if (item is _RegionEmptyItem) {
              child = _buildRegionEmptyCard(item, isDark);
            } else {
              return const SizedBox.shrink();
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isDesktop ? 840 : double.infinity),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }

  void _onRegionalScrollSettled(
      List<_RegionalListItem> flatItems, ScrollMetrics metrics) {
    if (flatItems.isEmpty) return;

    const double approxItemHeight = 72.0;
    final double scrollOffset = metrics.pixels;
    final double viewportHeight = metrics.viewportDimension;

    final int firstVisible =
        (scrollOffset / approxItemHeight).floor().clamp(0, flatItems.length - 1);
    final int visibleCount =
        ((viewportHeight / approxItemHeight).ceil() + 1).clamp(1, 8);
    final int lastVisible =
        (firstVisible + visibleCount).clamp(0, flatItems.length);

    if (firstVisible < lastVisible) {
      final visibleDocs = <DocumentItem>[];
      for (int i = firstVisible; i < lastVisible; i++) {
        final item = flatItems[i];
        if (item is _RegionDocItem) {
          visibleDocs.add(item.document);
        }
      }

      if (visibleDocs.isNotEmpty) {
        try {
          context.read<SmartPrefetchService>().prefetchDocumentListScroll(
                visibleDocuments: visibleDocs,
                downloadService: context.read<DownloadService>(),
                maxCount: 4,
              );
        } catch (_) {
          context.read<DownloadService>().prefetchDocuments(visibleDocs, maxCount: 4);
        }
      }
    }
  }

  Widget _buildRegionHeaderCard(_RegionHeaderItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isExpanded
              ? item.theme.primaryColor.withValues(alpha: 0.70)
              : (isDark
                  ? item.theme.primaryColor.withValues(alpha: 0.22)
                  : const Color(0xFFE2E8F0)),
          width: item.isExpanded ? 1.8 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: item.isExpanded
                ? item.theme.primaryColor
                    .withValues(alpha: isDark ? 0.20 : 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: item.isExpanded ? 12 : 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // Left Colored Indicator Bar
                Container(
                  width: 4.5,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.theme.primaryColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),

                // Distinctive Region Icon Squircle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item.theme.primaryColor.withValues(
                            alpha: isDark ? 0.35 : 0.18),
                        item.theme.primaryColor.withValues(
                            alpha: isDark ? 0.15 : 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: item.theme.primaryColor.withValues(
                          alpha: isDark ? 0.40 : 0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.theme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Region Names and Cultural Nickname
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.subtitle,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: item.theme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              item.nickname,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: item.theme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Badge: Exam Count & Corrigés
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: item.theme.primaryColor.withValues(
                          alpha: item.isExpanded
                              ? 0.22
                              : (isDark ? 0.20 : 0.10),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: item.theme.primaryColor.withValues(
                            alpha: item.isExpanded ? 0.5 : 0.25,
                          ),
                        ),
                      ),
                      child: Text(
                        '${item.totalCount} ex.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: item.theme.primaryColor,
                        ),
                      ),
                    ),
                    if (item.corrigesCount > 0 && !_onlyCorriges) ...[
                      const SizedBox(height: 2.5),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 11,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${item.corrigesCount}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                const SizedBox(width: 6),

                // Smooth Animated Rotating Chevron
                AnimatedRotation(
                  turns: item.isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.fastOutSlowIn,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 24,
                    color: item.isExpanded
                        ? item.theme.primaryColor
                        : (isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionEmptyCard(_RegionEmptyItem item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF10192A)
              : const Color(0xFFF1F5F9).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 16,
                color: isDark ? Colors.white54 : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              item.message,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList(List<DocumentItem> docs, Color accentColor,
      bool isDark, int totalCategoryDocs, String category) {
    if (category == 'examens' && _effectiveLevelId == '1ere-bac') {
      return _buildRegionalAccordionList(
          docs, accentColor, isDark, totalCategoryDocs);
    }

    if (docs.isEmpty) {
      if (category == 'examens') {
        final is1Bac = _effectiveLevelId == '1ere-bac';
        return RefreshIndicator(
          color: const Color(0xFF0F5132),
          onRefresh: () async {
            await context.read<CurriculumService>().refreshCurriculumNow();
          },
          child: Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    is1Bac
                        ? Icons.workspace_premium_rounded
                        : Icons.military_tech_rounded,
                    size: 64,
                    color: accentColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    is1Bac
                        ? 'Examens Régionaux (1ère Bac)'
                        : 'Examens Nationaux (2ème Bac)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    is1Bac
                        ? 'Les épreuves régionales officielles et leurs corrigés pour cette matière seront disponibles très prochainement.'
                        : 'Les épreuves nationales officielles et leurs corrigés pour cette matière seront disponibles très prochainement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: const Color(0xFF0F5132),
        onRefresh: () async {
          await context.read<CurriculumService>().refreshCurriculumNow();
        },
        child: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: 56,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Aucun résultat pour "$_searchQuery"'
                      : (_onlyCorriges
                          ? 'Aucun document avec corrigé pour cette sélection'
                          : 'Aucun document disponible pour ce filtre'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                if (_onlyCorriges && totalCategoryDocs > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '$totalCategoryDocs documents sont disponibles sans corrigé officiel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                if (_selectedSemester != 'all' ||
                    _onlyCorriges ||
                    _searchQuery.isNotEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Réinitialiser les filtres'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5132),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedSemester = 'all';
                        _onlyCorriges = false;
                        _expandedRegionIds.clear();
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final hasHiddenUncorrected =
        _onlyCorriges && docs.length < totalCategoryDocs;

    return RefreshIndicator(
      color: const Color(0xFF0F5132),
      onRefresh: () async {
        await context.read<CurriculumService>().refreshCurriculumNow();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            _onScrollSettled(docs, notification.metrics);
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: docs.length + (hasHiddenUncorrected ? 1 : 0),
          itemBuilder: (context, index) {
            final isDesktop = MediaQuery.of(context).size.width >= 800;
            Widget child;
            if (index == docs.length) {
              final hiddenCount = totalCategoryDocs - docs.length;
              child = Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF131D30) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 20, color: accentColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$hiddenCount autre${hiddenCount > 1 ? 's' : ''} document${hiddenCount > 1 ? 's' : ''} sans corrigé masqué${hiddenCount > 1 ? 's' : ''} par le filtre.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _onlyCorriges = false;
                        });
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
              );
            } else {
              child = DocumentCard(
                document: docs[index],
                subjectName: widget.subject.nameFr,
                accentColor: accentColor,
                categoryDocuments: docs,
                documentIndex: index,
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isDesktop ? 840 : double.infinity),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RegionVisualTheme {
  final Color primaryColor;
  final IconData icon;
  final String nicknameFr;
  final String nicknameAr;

  const _RegionVisualTheme({
    required this.primaryColor,
    required this.icon,
    required this.nicknameFr,
    required this.nicknameAr,
  });

  static _RegionVisualTheme getTheme(String regionId) {
    switch (regionId) {
      case 'casablanca-settat':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFF1D4ED8), // Royal Blue
          icon: Icons.business_rounded,
          nicknameFr: 'Pôle économique',
          nicknameAr: 'القطب الاقتصادي',
        );
      case 'rabat-sale-kenitra':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFF7C3AED), // Imperial Violet
          icon: Icons.account_balance_rounded,
          nicknameFr: 'Capitale & Savoir',
          nicknameAr: 'عاصمة المملكة',
        );
      case 'fes-meknes':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFF047857), // Historic Emerald
          icon: Icons.menu_book_rounded,
          nicknameFr: 'Héritage & Culture',
          nicknameAr: 'العاصمة الروحية',
        );
      case 'marrakech-safi':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFFDC2626), // Ochre Red
          icon: Icons.fort_rounded,
          nicknameFr: 'Cité ocre',
          nicknameAr: 'المدينة الحمراء',
        );
      case 'tanger-tetouan-al-hoceima':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFF0284C7), // Strait Azure
          icon: Icons.explore_rounded,
          nicknameFr: 'Détroit & Nord',
          nicknameAr: 'عروس الشمال',
        );
      case 'souss-massa':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFFD97706), // Argan Gold
          icon: Icons.wb_sunny_rounded,
          nicknameFr: 'Souss & Argan',
          nicknameAr: 'عاصمة سوس',
        );
      case 'beni-mellal-khenifra':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFF15803D), // Atlas Forest Green
          icon: Icons.terrain_rounded,
          nicknameFr: 'Moyen Atlas',
          nicknameAr: 'قلب الأطلس',
        );
      case 'oriental':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFFEA580C), // Desert Amber
          icon: Icons.landscape_rounded,
          nicknameFr: "L'Oriental",
          nicknameAr: 'جهة الشرق',
        );
      case 'draa-tafilalet':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFFB45309), // Palm Oasis
          icon: Icons.park_rounded,
          nicknameFr: 'Oasis & Dunes',
          nicknameAr: 'درعة وتافيلالت',
        );
      case 'guelmim-oued-noun':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFFC2410C), // Sahara Terracotta
          icon: Icons.navigation_rounded,
          nicknameFr: 'Porte du Sahara',
          nicknameAr: 'باب الصحراء',
        );
      case 'laayoune-sakia-el-hamra':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFF0D9488), // Ocean Teal
          icon: Icons.beach_access_rounded,
          nicknameFr: 'Provinces du Sud',
          nicknameAr: 'الساقية الحمراء',
        );
      case 'dakhla-oued-ed-dahab':
        return const _RegionVisualTheme(
          primaryColor: Color(0xFF0891B2), // Lagoon Turquoise
          icon: Icons.water_rounded,
          nicknameFr: 'Perle du Sud',
          nicknameAr: 'وادي الذهب',
        );
      default:
        return const _RegionVisualTheme(
          primaryColor: Color(0xFF64748B), // Slate Grey
          icon: Icons.auto_stories_rounded,
          nicknameFr: 'Épreuves nationales',
          nicknameAr: 'نماذج مشتركة',
        );
    }
  }
}

abstract class _RegionalListItem {}

class _RegionHeaderItem extends _RegionalListItem {
  final String regionId;
  final String title;
  final String subtitle;
  final String nickname;
  final IconData icon;
  final int totalCount;
  final int corrigesCount;
  final bool isExpanded;
  final _RegionVisualTheme theme;
  final VoidCallback onTap;

  _RegionHeaderItem({
    required this.regionId,
    required this.title,
    required this.subtitle,
    required this.nickname,
    required this.icon,
    required this.totalCount,
    required this.corrigesCount,
    required this.isExpanded,
    required this.theme,
    required this.onTap,
  });
}

class _RegionDocItem extends _RegionalListItem {
  final DocumentItem document;
  final String regionId;
  final _RegionVisualTheme theme;
  final List<DocumentItem> categoryDocuments;
  final int documentIndex;

  _RegionDocItem({
    required this.document,
    required this.regionId,
    required this.theme,
    required this.categoryDocuments,
    required this.documentIndex,
  });
}

class _RegionEmptyItem extends _RegionalListItem {
  final String message;
  final _RegionVisualTheme theme;

  _RegionEmptyItem({
    required this.message,
    required this.theme,
  });
}

