import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/orientation_service.dart';
import '../services/app_language_service.dart';
import '../services/focus_timer_service.dart';
import 'school_detail_screen.dart';
import 'orientation_faq_screen.dart';
import 'orientation_conseils_screen.dart';

class OrientationScreen extends StatefulWidget {
  const OrientationScreen({super.key});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  String _selectedCategory = 'toutes';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Simulator state
  bool _showSimulator = false;
  String _simBranch = 'pc';
  final TextEditingController _nationalController =
      TextEditingController(text: '14.50');
  final TextEditingController _regionalController =
      TextEditingController(text: '14.00');
  List<SimulationResult>? _simResults;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrientationService>().init();
        context.read<FocusTimerService>().pushDockingScreen(ActiveDockingScreen.orientation);
      }
    });
  }

  @override
  void dispose() {
    try {
      context.read<FocusTimerService>().popDockingScreen(ActiveDockingScreen.orientation);
    } catch (_) {}
    _searchController.dispose();
    _nationalController.dispose();
    _regionalController.dispose();
    super.dispose();
  }

  void _runSimulation() {
    final nat = double.tryParse(_nationalController.text.trim()) ?? 14.0;
    final reg = double.tryParse(_regionalController.text.trim()) ?? 14.0;

    final results = context.read<OrientationService>().simulateChances(
          noteNational: nat.clamp(0.0, 20.0),
          noteRegional: reg.clamp(0.0, 20.0),
          branchCode: _simBranch,
        );

    setState(() {
      _simResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orientationService = context.watch<OrientationService>();
    final langService = context.watch<AppLanguageService>();
    final isAr = langService.isArabic;
    final isDesktop = MediaQuery.of(context).size.width >= 750;

    final filteredSchools = orientationService.filterSchools(
      query: _searchQuery,
      categoryId: _selectedCategory,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Text(
          isAr ? 'دليل التوجيه بعد البكالوريا' : 'Orientation & Post-Bac Maroc',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          // 1. Bouton Questions Fréquentes (FAQ) à gauche de la barre de recherche
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip:
                isAr ? 'الأسئلة الشائعة (FAQ)' : 'Questions fréquentes (FAQ)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OrientationFaqScreen(),
                ),
              );
            },
          ),

          // 2. Bouton Conseils & Concours
          IconButton(
            icon: const Icon(Icons.tips_and_updates_outlined),
            tooltip: isAr
                ? 'دليل النصائح والمباريات الشفوية'
                : 'Conseils, Concours & Entretiens',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OrientationConseilsScreen(),
                ),
              );
            },
          ),

          // 3. Bouton Simulateur de calcul
          IconButton(
            icon: Icon(
              _showSimulator
                  ? Icons.calculate_rounded
                  : Icons.calculate_outlined,
              color: _showSimulator ? const Color(0xFF10B981) : null,
            ),
            tooltip: isAr
                ? 'محاكي حساب معدل الانتقاء'
                : 'Simulateur de calcul CursusSup',
            onPressed: () {
              setState(() {
                _showSimulator = !_showSimulator;
                if (_showSimulator && _simResults == null) {
                  _runSimulation();
                }
              });
            },
          ),

          // 4. Barre de recherche : TOUT À DROITE sur PC
          if (isDesktop)
            Container(
              width: 270,
              height: 38,
              margin: const EdgeInsets.only(left: 6, right: 12, top: 8, bottom: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'ابحث عن مدرسة أو ديبلوم...'
                      : 'Rechercher une école, diplôme...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
      body: orientationService.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F5132)),
            )
          : orientationService.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(orientationService.errorMessage!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => orientationService.init(),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Header Banner
                    _buildHeaderBanner(isDark, isAr),

                    // Quick access chips for mobile users
                    if (!isDesktop) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.help_outline_rounded,
                                  size: 18),
                              label: Text(
                                isAr ? 'الأسئلة الشائعة' : 'FAQ Post-Bac',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const OrientationFaqScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(
                                  Icons.tips_and_updates_outlined,
                                  size: 18),
                              label: Text(
                                isAr
                                    ? 'النصائح والمباريات'
                                    : 'Conseils & Concours',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const OrientationConseilsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Simulator Card (Collapsible)
                    if (_showSimulator) ...[
                      _buildSimulatorCard(isDark, isAr),
                      const SizedBox(height: 14),
                    ],

                    // Search Bar (Only shown in body on Mobile)
                    if (!isDesktop) ...[
                      _buildSearchBar(isDark, isAr),
                      const SizedBox(height: 10),
                    ],

                    // Categories Selector with Domain Colors & Icons
                    _buildCategoryChips(orientationService, isDark, isAr),

                    const SizedBox(height: 14),

                    // Section Title
                    Row(
                      children: [
                        Text(
                          isAr
                              ? 'المؤسسات والمدارس العليا (${filteredSchools.length})'
                              : 'Écoles et Instituts Supérieurs (${filteredSchools.length})',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Schools List: 2 cards per row on PC (16:9), 1 per row on Mobile
                    if (filteredSchools.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            isAr
                                ? 'لا توجد مؤسسة مطابقة للبحث'
                                : 'Aucun établissement ne correspond à votre recherche.',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      )
                    else if (isDesktop) ...[
                      for (int i = 0; i < filteredSchools.length; i += 2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _OrientationSchoolCard(
                                  school: filteredSchools[i],
                                  isDark: isDark,
                                  isAr: isAr,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (i + 1 < filteredSchools.length)
                                Expanded(
                                  child: _OrientationSchoolCard(
                                    school: filteredSchools[i + 1],
                                    isDark: isDark,
                                    isAr: isAr,
                                  ),
                                )
                              else
                                const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                        ),
                    ] else ...[
                      for (final s in filteredSchools)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _OrientationSchoolCard(
                            school: s,
                            isDark: isDark,
                            isAr: isAr,
                          ),
                        ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
    );
  }

  Widget _buildHeaderBanner(bool isDark, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F5132), const Color(0xFF064E3B)]
              : [const Color(0xFF0F5132), const Color(0xFF198754)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5132).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAr ? 'دليل رسمي محدث 2026' : 'Guide Officiel Actualisé 2026',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? 'بوابتك الشاملة لمدارس ومعاهد المغرب'
                      : 'Explorez les Grandes Écoles et Facultés du Maroc',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isAr
                      ? 'عتبات الانتقاء، التخصصات، شروط الولوج ومحاكي القبول'
                      : 'Seuils historiques, concours, débouchés et simulateur de chances',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.explore_rounded,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  /// Simulateur CursusSup avec 4 blocs visuels :
  Widget _buildSimulatorCard(bool isDark, bool isAr) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final nat = double.tryParse(_nationalController.text.trim()) ?? 0.0;
    final reg = double.tryParse(_regionalController.text.trim()) ?? 0.0;
    final scoreCursusSup =
        (nat.clamp(0.0, 20.0) * 0.75) + (reg.clamp(0.0, 20.0) * 0.25);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF0F5132).withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5132).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calculate_rounded,
                    color: Color(0xFF0F5132), size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'محاكي حساب معدل الانتقاء CursusSup والفرص'
                          : 'Simulateur de calcul CursusSup & Chances',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isAr
                          ? 'الصيغة الوزارية الرسمية : 75% الامتحان الوطني + 25% الامتحان الجهوي'
                          : 'Formule unifiée : 75% Examen National + 25% Examen Régional',
                      style: TextStyle(
                        fontSize: 10.5,
                        color:
                            isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() => _showSimulator = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Disposition responsive des 4 cartes du simulateur
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 820;
              final colCount =
                  isWide ? 4 : (constraints.maxWidth >= 500 ? 2 : 1);
              final spacing = 8.0;
              final itemWidth =
                  (constraints.maxWidth - (colCount - 1) * spacing) / colCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  // Carte 1 : Choix de la filière
                  SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? '1. شعبة البكالوريا' : '1. Filière du Bac',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 2),
                          DropdownButtonFormField<String>(
                            initialValue: _simBranch,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 2),
                              border: InputBorder.none,
                            ),
                            items: [
                              DropdownMenuItem(
                                  value: 'pc',
                                  child: Text(
                                      isAr
                                          ? 'العلوم الفيزيائية (PC)'
                                          : 'Sc. Physiques (PC)',
                                      style: const TextStyle(fontSize: 11.5))),
                              DropdownMenuItem(
                                  value: 'svt',
                                  child: Text(
                                      isAr
                                          ? 'علوم الحياة والأرض (SVT)'
                                          : 'SVT',
                                      style: const TextStyle(fontSize: 11.5))),
                              DropdownMenuItem(
                                  value: 'sm',
                                  child: Text(
                                      isAr
                                          ? 'العلوم الرياضية (SM)'
                                          : 'Sc. Maths (A/B)',
                                      style: const TextStyle(fontSize: 11.5))),
                              DropdownMenuItem(
                                  value: 'eco',
                                  child: Text(
                                      isAr
                                          ? 'العلوم الاقتصادية'
                                          : 'Éco & Gestion',
                                      style: const TextStyle(fontSize: 11.5))),
                              DropdownMenuItem(
                                  value: 'technique',
                                  child: Text(
                                      isAr
                                          ? 'العلوم والتقنيات'
                                          : 'STE / STM',
                                      style: const TextStyle(fontSize: 11.5))),
                              DropdownMenuItem(
                                  value: 'bac_pro',
                                  child: Text(
                                      isAr
                                          ? 'البكالوريا المهنية'
                                          : 'Bac Pro',
                                      style: const TextStyle(fontSize: 11.5))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _simBranch = val);
                                _runSimulation();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Carte 2 : Note National (75%)
                  SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? '2. الامتحان الوطني (75%)'
                                : '2. Note National (75%)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 2),
                          TextFormField(
                            controller: _nationalController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'ex: 14.50',
                              contentPadding: EdgeInsets.symmetric(vertical: 2),
                              border: InputBorder.none,
                              suffixText: '/20',
                              suffixStyle:
                                  TextStyle(fontSize: 10.5, color: Colors.grey),
                            ),
                            onChanged: (_) => _runSimulation(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Carte 3 : Note Régional (25%)
                  SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? '3. الامتحان الجهوي (25%)'
                                : '3. Note Régional (25%)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 2),
                          TextFormField(
                            controller: _regionalController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'ex: 14.00',
                              contentPadding: EdgeInsets.symmetric(vertical: 2),
                              border: InputBorder.none,
                              suffixText: '/20',
                              suffixStyle:
                                  TextStyle(fontSize: 10.5, color: Colors.grey),
                            ),
                            onChanged: (_) => _runSimulation(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Carte 4 : Résultat du calcul de la Moyenne CursusSup
                  SizedBox(
                    width: itemWidth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F5132).withValues(alpha: 0.15),
                            const Color(0xFF10B981).withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isAr
                                    ? '4. معدل CursusSup'
                                    : '4. Moyenne CursusSup',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F5132),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.stars_rounded,
                                  size: 13, color: Color(0xFF10B981)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                scoreCursusSup.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F5132),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                '/ 20',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          if (_simResults != null && _simResults!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'النتائج التقديرية بناءً على عتبات السنوات السابقة :'
                  : 'Estimation indicative basée sur les seuils antérieurs :',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ..._simResults!.map((r) => _buildSimResultRow(r, isDark, isAr)),
          ],
        ],
      ),
    );
  }

  Widget _buildSimResultRow(SimulationResult r, bool isDark, bool isAr) {
    Color badgeColor;
    switch (r.statut) {
      case 'admissible':
        badgeColor = const Color(0xFF10B981);
        break;
      case 'chance_reelle':
        badgeColor = const Color(0xFF0284C7);
        break;
      case 'liste_attente':
        badgeColor = const Color(0xFFF59E0B);
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? r.schoolNameAr : r.schoolName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  r.details,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor, width: 1),
            ),
            child: Text(
              isAr ? r.statutLabelAr : r.statutLabelFr,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, bool isAr) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: isAr
            ? 'ابحث عن مدرسة، تخصص، أو ديبلوم...'
            : 'Rechercher une école, un diplôme, un métier...',
        hintStyle: TextStyle(
          fontSize: 12.5,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (val) => setState(() => _searchQuery = val),
    );
  }

  /// Sélecteur de catégories compact
  Widget _buildCategoryChips(
      OrientationService orientationService, bool isDark, bool isAr) {
    final categories = orientationService.categories;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSingleCategoryChip(
            id: 'toutes',
            label: isAr ? 'الكل' : 'Toutes',
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF0F5132),
            isSelected: _selectedCategory == 'toutes',
            isDark: isDark,
          ),
          ...categories.map((c) {
            final catColor = _resolveCategoryColor(c.id);
            final catIcon = _resolveCategoryIcon(c.id);
            final isSel = _selectedCategory == c.id;

            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _buildSingleCategoryChip(
                id: c.id,
                label: isAr ? c.nomAr : c.nomFr,
                icon: catIcon,
                color: catColor,
                isSelected: isSel,
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSingleCategoryChip({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () => setState(() => _selectedCategory = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected
                ? color
                : color.withValues(alpha: isDark ? 0.35 : 0.22),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _resolveCategoryColor(String id) {
    switch (id) {
      case 'ingenierie_technologie':
        return const Color(0xFF0284C7);
      case 'commerce_gestion':
        return const Color(0xFF7C3AED);
      case 'medecine_sante':
        return const Color(0xFF0D9488);
      case 'architecture_agriculture':
        return const Color(0xFF15803D);
      case 'sciences_sport':
        return const Color(0xFFE11D48);
      case 'guides_et_seuils':
        return const Color(0xFF0F5132);
      default:
        return const Color(0xFF0F5132);
    }
  }

  IconData _resolveCategoryIcon(String id) {
    switch (id) {
      case 'ingenierie_technologie':
        return Icons.precision_manufacturing_rounded;
      case 'commerce_gestion':
        return Icons.trending_up_rounded;
      case 'medecine_sante':
        return Icons.medical_services_rounded;
      case 'architecture_agriculture':
        return Icons.architecture_rounded;
      case 'sciences_sport':
        return Icons.fitness_center_rounded;
      case 'guides_et_seuils':
        return Icons.account_balance_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}

// -------------------------------------------------------------
// Résolution Thématique & Carte Compacte d'Établissement
// -------------------------------------------------------------

class SchoolVisualTheme {
  final Color primaryColor;
  final IconData icon;
  final String categoryLabelFr;
  final String categoryLabelAr;

  const SchoolVisualTheme({
    required this.primaryColor,
    required this.icon,
    required this.categoryLabelFr,
    required this.categoryLabelAr,
  });
}

SchoolVisualTheme _resolveSchoolTheme(SchoolSummary s) {
  final id = s.id.toLowerCase();
  final type = s.type.toLowerCase();

  // 1. Médecine, Pharmacie & Santé
  if (id.contains('medecine') ||
      id.contains('fmp') ||
      type.contains('santé') ||
      type.contains('médic')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFF0D9488), // Sarcelle Médical
      icon: Icons.medical_services_rounded,
      categoryLabelFr: 'Santé & Médecine',
      categoryLabelAr: 'الطب والصحة',
    );
  }
  // 2. Commerce & Gestion
  if (id.contains('encg') ||
      id.contains('iscae') ||
      type.contains('commerce') ||
      type.contains('management') ||
      type.contains('finance')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFF7C3AED), // Indigo / Violet
      icon: Icons.trending_up_rounded,
      categoryLabelFr: 'Commerce & Gestion',
      categoryLabelAr: 'التجارة والتسيير',
    );
  }
  // 3. ENSAM / Arts & Métiers
  if (id.contains('ensam') ||
      type.contains('arts et métiers') ||
      type.contains('mécanique')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFF2563EB), // Bleu Royal
      icon: Icons.engineering_rounded,
      categoryLabelFr: 'Arts & Métiers',
      categoryLabelAr: 'الفنون والمهن',
    );
  }
  // 4. ENSA / Ingénierie
  if (id.contains('ensa') || type.contains('ingénierie')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFF0284C7), // Bleu Océan
      icon: Icons.precision_manufacturing_rounded,
      categoryLabelFr: 'Ingénierie',
      categoryLabelAr: 'الهندسة التطبيقية',
    );
  }
  // 5. Architecture & Urbanisme
  if (id.contains('architecture') ||
      id.contains('ena') ||
      id.contains('iftsau') ||
      type.contains('architecture') ||
      type.contains('urbanisme')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFFD97706), // Ambre Doré
      icon: Icons.architecture_rounded,
      categoryLabelFr: 'Architecture',
      categoryLabelAr: 'الهندسة المعمارية',
    );
  }
  // 6. Agronomie & Vétérinaire
  if (id.contains('agronomie') ||
      id.contains('iav') ||
      id.contains('enam') ||
      id.contains('itsmaer') ||
      type.contains('agron') ||
      type.contains('agricole')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFF16A34A), // Vert Nature
      icon: Icons.agriculture_rounded,
      categoryLabelFr: 'Agronomie',
      categoryLabelAr: 'الفلاحة والبيطرة',
    );
  }
  // 7. Sciences & FST
  if (id.contains('fst') ||
      type.contains('techniques') ||
      type.contains('sciences et techniques')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFF0891B2), // Cyan Saphir
      icon: Icons.biotech_rounded,
      categoryLabelFr: 'FST Sciences',
      categoryLabelAr: 'العلوم والتقنيات',
    );
  }
  // 8. EST / Technologie / DUT
  if (id.contains('est') ||
      id.contains('bts') ||
      type.contains('technologie') ||
      type.contains('dut')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFF059669), // Vert Émeraude
      icon: Icons.devices_other_rounded,
      categoryLabelFr: 'DUT Tech',
      categoryLabelAr: 'التكنولوجيا التطبيقية',
    );
  }
  // 9. Éducation & Enseignement
  if (id.contains('education') ||
      id.contains('ens_') ||
      id.contains('esef') ||
      type.contains('éducation') ||
      type.contains('enseignement')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFF9333EA), // Pourpre Pédagogique
      icon: Icons.school_rounded,
      categoryLabelFr: 'Éducation',
      categoryLabelAr: 'علوم التربية والتعليم',
    );
  }
  // 10. Sport & Métiers du Sport
  if (id.contains('sport') || type.contains('sport')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFFE11D48), // Rose Dynamique
      icon: Icons.fitness_center_rounded,
      categoryLabelFr: 'Sport',
      categoryLabelAr: 'علوم ومهن الرياضة',
    );
  }
  // 11. CPGE
  if (id.contains('cpge') || type.contains('préparatoire')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFF1D4ED8), // Bleu Indigo
      icon: Icons.auto_stories_rounded,
      categoryLabelFr: 'CPGE Prépa',
      categoryLabelAr: 'الأقسام التحضيرية CPGE',
    );
  }
  // 12. Universités Publiques & Sectorisation
  if (id.contains('universite') ||
      type.contains('faculté') ||
      type.contains('géographique')) {
    return const SchoolVisualTheme(
      primaryColor: Color(0xFF0F5132), // Vert Institutionnel
      icon: Icons.account_balance_rounded,
      categoryLabelFr: 'Universités',
      categoryLabelAr: 'الجامعات العمومية',
    );
  }

  // Fallback
  return const SchoolVisualTheme(
    primaryColor: Color(0xFF0F5132),
    icon: Icons.school_rounded,
    categoryLabelFr: 'Supérieur',
    categoryLabelAr: 'التعليم العالي',
  );
}

/// Carte d'établissement compacte et ultra-ergonomique avec hauteur réduite (~92px)
class _OrientationSchoolCard extends StatefulWidget {
  final SchoolSummary school;
  final bool isDark;
  final bool isAr;

  const _OrientationSchoolCard({
    required this.school,
    required this.isDark,
    required this.isAr,
  });

  @override
  State<_OrientationSchoolCard> createState() => _OrientationSchoolCardState();
}

class _OrientationSchoolCardState extends State<_OrientationSchoolCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.school;
    final isDark = widget.isDark;
    final isAr = widget.isAr;
    final theme = _resolveSchoolTheme(s);
    final color = theme.primaryColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.014 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      _isHovered
                          ? const Color(0xFF1E2D47)
                          : const Color(0xFF1E293B),
                      Color.alphaBlend(
                        color.withValues(alpha: _isHovered ? 0.18 : 0.06),
                        const Color(0xFF0F172A),
                      ),
                    ]
                  : [
                      Colors.white,
                      Color.alphaBlend(
                        color.withValues(alpha: _isHovered ? 0.08 : 0.02),
                        Colors.white,
                      ),
                    ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? color
                  : (isDark
                      ? const Color(0xFF334155)
                      : color.withValues(alpha: 0.20)),
              width: _isHovered ? 1.6 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(
                  alpha: _isHovered
                      ? (isDark ? 0.25 : 0.12)
                      : (isDark ? 0.06 : 0.025),
                ),
                blurRadius: _isHovered ? 12 : 5,
                offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              splashColor: color.withValues(alpha: 0.10),
              highlightColor: color.withValues(alpha: 0.05),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    settings: RouteSettings(name: '/orientation/${s.id}'),
                    builder: (_) => SchoolDetailScreen(school: s),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Boîtier d'icône compact (42x42px)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.22 : 0.11),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: color.withValues(alpha: _isHovered ? 0.40 : 0.20),
                          width: 1.0,
                        ),
                        boxShadow: _isHovered
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        theme.icon,
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Contenu textuel et badges en flux vertical unique et serré
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ligne 1 : Nom de l'école + Tag de domaine + Nombre de villes
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isAr ? s.nomAr : s.nom,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: isDark ? 0.22 : 0.09),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: color.withValues(alpha: isDark ? 0.30 : 0.20),
                                    width: 0.7,
                                  ),
                                ),
                                child: Text(
                                  isAr
                                      ? theme.categoryLabelAr
                                      : theme.categoryLabelFr,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                              if (s.villesCount != null) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: isDark ? 0.16 : 0.07),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: color.withValues(alpha: isDark ? 0.25 : 0.16),
                                      width: 0.7,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on_rounded,
                                          size: 10, color: color),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${s.villesCount} ${isAr ? 'مدن' : 'villes'}',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 3),

                          // Ligne 2 : Diplôme / Spécialité
                          Text(
                            s.diplome,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 5),

                          // Ligne 3 : Durée + Concours
                          Row(
                            children: [
                              _buildSubtleBadge(
                                icon: Icons.timer_outlined,
                                label: s.duree,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 6),
                              if (s.concours != null)
                                Flexible(
                                  child: _buildSubtleBadge(
                                    icon: Icons.how_to_reg_outlined,
                                    label: s.concours!,
                                    isDark: isDark,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Flèche réactive au survol
                    Icon(
                      isAr
                          ? Icons.arrow_back_ios_new_rounded
                          : Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: _isHovered
                          ? color
                          : (isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtleBadge({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
