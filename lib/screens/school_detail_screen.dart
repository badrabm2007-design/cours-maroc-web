import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/orientation_service.dart';
import '../services/app_language_service.dart';

class SchoolDetailScreen extends StatefulWidget {
  final SchoolSummary school;

  const SchoolDetailScreen({
    super.key,
    required this.school,
  });

  @override
  State<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends State<SchoolDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _selectedProvince;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final orientationService = context.read<OrientationService>();
    final result =
        await orientationService.getSchoolDetails(widget.school.fichier);
    if (mounted) {
      setState(() {
        _data = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langService = context.watch<AppLanguageService>();
    final isAr = langService.isArabic;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final isUniversitesCard = widget.school.id == 'universites_secteurs_maroc' ||
        (_data != null && _data!.containsKey('universites'));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAr ? widget.school.nomAr : widget.school.nom,
          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F5132)),
            )
          : _data == null
              ? Center(
                  child: Text(
                    isAr
                        ? 'تعذر تحميل بيانات هذه المؤسسة'
                        : 'Impossible de charger la fiche.',
                  ),
                )
              : isUniversitesCard
                  ? _buildUniversitesView(isDark, isAr, isDesktop)
                  : _buildContent(isDark, isAr, isDesktop),
    );
  }

  /// Vue spécifique pour la cartographie des 13 universités publiques et facultés ouvertes
  Widget _buildUniversitesView(bool isDark, bool isAr, bool isDesktop) {
    final primaryGreen = const Color(0xFF0F5132);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final universites = (_data!['universites'] as List<dynamic>?) ?? [];
    final noteOfficielle = _data!['note_officielle']?.toString() ??
        'L\'inscription dans les facultés à accès ouvert (FS, FSJES, FLSH) dépend directement de la province d\'obtention de votre baccalauréat.';

    // Extraire toutes les provinces uniques
    final allProvincesSet = <String>{};
    for (final u in universites) {
      if (u is Map && u['provinces_et_prefectures'] is List) {
        for (final p in u['provinces_et_prefectures']) {
          final cleanP = p.toString().trim();
          if (cleanP.isNotEmpty && !cleanP.startsWith('Territoire')) {
            allProvincesSet.add(cleanP);
          }
        }
      }
    }
    final allProvinces = allProvincesSet.toList()..sort();

    // Trouver l'université correspondante à la province sélectionnée
    Map<String, dynamic>? matchedUni;
    if (_selectedProvince != null && _selectedProvince!.isNotEmpty) {
      for (final u in universites) {
        if (u is Map && u['provinces_et_prefectures'] is List) {
          final list = u['provinces_et_prefectures'] as List;
          if (list.any((p) =>
              p.toString().toLowerCase().contains(_selectedProvince!.toLowerCase()))) {
            matchedUni = Map<String, dynamic>.from(u);
            break;
          }
        }
      }
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 20,
          ),
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F5132), const Color(0xFF064E3B)]
                      : [const Color(0xFF0F5132), const Color(0xFF15803D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F5132).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAr
                              ? '13 جامعة عمومية مغربية'
                              : '13 Universités Publiques',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAr ? 'ولوج مفتوح بدون مباراة' : 'Accès Ouvert Direct',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr
                        ? 'الخريطة الجامعية وروافد الكليات ذات الاستقطاب المفتوح'
                        : 'Cartographie & Sectorisation des Universités',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'توزيع حاملي البكالوريا على كليات العلوم (FS)، الحقوق والاقتصاد (FSJES)، والآداب (FLSH) حسب عمالة وإقليم الحصول على الشهادة.'
                        : 'Sectorisation officielle pour l\'accès aux Facultés des Sciences (FS), Droit & Économie (FSJES), et Lettres (FLSH).',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Note officielle d'explication
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF0284C7),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'ملاحظة قانونية : التسجيل في الكليات ذات الاستقطاب المفتوح (FS, FSJES, FLSH) يخضع حصراً للتوزيع الجغرافي حسب إقليم البكالوريا، ولا يتطلب أي عتبة انتقاء أو مباراة.'
                          : noteOfficielle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Outil interactif : Trouver son université de rattachement
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.pin_drop_rounded,
                            color: primaryGreen, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'ابحث عن جامعتك التابعة لإقليم البكالوريا'
                                  : 'Trouvez votre université selon votre province',
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isAr
                                  ? 'اختر أو اكتب إقليم نيل شهادة البكالوريا لمعرفة الكليات المتاحة لك مباشرة'
                                  : 'Sélectionnez votre province de Bac pour voir les facultés de votre secteur',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sélecteur rapide de province
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedProvince,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: isAr
                                ? 'اختر إقليم البكالوريا...'
                                : 'Sélectionnez votre province...',
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          ),
                          items: allProvinces.map((prov) {
                            return DropdownMenuItem<String>(
                              value: prov,
                              child: Text(prov, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedProvince = val;
                            });
                          },
                        ),
                      ),
                      if (_selectedProvince != null) ...[
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: isAr ? 'إلغاء التحديد' : 'Réinitialiser',
                          onPressed: () {
                            setState(() {
                              _selectedProvince = null;
                            });
                          },
                        ),
                      ],
                    ],
                  ),

                  // Quick chips pour les principales villes
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'Casablanca',
                      'Rabat',
                      'Marrakech',
                      'Fès',
                      'Tanger',
                      'Agadir',
                      'Oujda',
                      'Meknès',
                      'Kénitra',
                      'Settat',
                      'Béni Mellal',
                      'Tétouan',
                    ].map((city) {
                      final isSelected = _selectedProvince == city;
                      return ChoiceChip(
                        label: Text(city, style: const TextStyle(fontSize: 11.5)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedProvince = selected ? city : null;
                          });
                        },
                        selectedColor: primaryGreen.withValues(alpha: 0.15),
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          color: isSelected ? primaryGreen : (isDark ? Colors.white70 : const Color(0xFF334155)),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),

                  // Affichage immédiat du résultat de rattachement
                  if (matchedUni != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  matchedUni['code'] ?? 'UNI',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  matchedUni['nom'] ?? '',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isAr
                                ? 'الكليات ذات الاستقطاب المفتوح المتاحة لإقليم $_selectedProvince :'
                                : 'Établissements ouverts de votre secteur pour $_selectedProvince :',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (matchedUni['etablissements_ouverts'] is List)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: (matchedUni['etablissements_ouverts'] as List)
                                  .map((fac) {
                                return Chip(
                                  avatar: const Icon(Icons.school_rounded,
                                      size: 14, color: Color(0xFF0F5132)),
                                  label: Text(
                                    fac.toString(),
                                    style: const TextStyle(
                                        fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Titre de la liste des 13 universités
            Row(
              children: [
                const Icon(Icons.account_balance_rounded,
                    color: Color(0xFF0F5132), size: 20),
                const SizedBox(width: 8),
                Text(
                  isAr
                      ? 'دليل الجامعات العمومية الـ 13 ومناطق روافدها'
                      : 'Répertoire complet des 13 universités publiques',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Grille responsive des 13 universités
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 750 ? 2 : 1;
                final spacing = 14.0;
                final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                    crossAxisCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: universites.map((u) {
                    final uniMap = u as Map<String, dynamic>;
                    final code = uniMap['code'] ?? '';
                    final nom = uniMap['nom'] ?? '';
                    final ville = uniMap['ville'] ?? '';
                    final provinces = (uniMap['provinces_et_prefectures'] as List<dynamic>?) ?? [];
                    final facs = (uniMap['etablissements_ouverts'] as List<dynamic>?) ?? [];

                    return SizedBox(
                      width: itemWidth,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête de la carte
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryGreen,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    code,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nom,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_city_rounded,
                                              size: 13, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            ville,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFEEF2F6)),
                            const SizedBox(height: 10),

                            // Provinces couvertes
                            Text(
                              isAr ? 'الأقاليم والعمالات التابعة :' : 'Provinces et préfectures d\'affectation :',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: provinces.map((p) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 12),

                            // Facultés ouvertes
                            Text(
                              isAr ? 'الكليات ذات الاستقطاب المفتوح :' : 'Facultés à accès ouvert (FS, FSJES, FLSH) :',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : const Color(0xFF0F5132),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: facs.map((f) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_rounded,
                                          size: 14, color: Color(0xFF0F5132)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          f.toString(),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            height: 1.35,
                                            color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Vue standard pour les écoles supérieures et instituts régulés
  Widget _buildContent(bool isDark, bool isAr, bool isDesktop) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final nomFr = _data!['nom_fr'] ?? widget.school.nom;
    final nomAr = _data!['nom_ar'] ?? widget.school.nomAr;
    final typeEtablissement = _data!['type_etablissement'] ?? widget.school.type;
    final duree = _data!['duree_etudes'] ?? widget.school.duree;
    final seuils = _data!['seuils_historiques_preselection'] as Map<String, dynamic>?;
    final conseils = _data!['conseils_candidats'] as List<dynamic>?;
    final debouches = _data!['debouches_professionnels'] as List<dynamic>?;
    final villes = _data!['villes'] as List<dynamic>?;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 20,
          ),
          children: [
            // Header Banner Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F5132), const Color(0xFF064E3B)]
                      : [const Color(0xFF0F5132), const Color(0xFF198754)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F5132).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeEtablissement.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.school.villesCount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_city_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.school.villesCount} ${isAr ? 'مدن' : 'villes'}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isAr ? nomAr : nomFr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr ? nomFr : nomAr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.school_outlined,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.school.diplome.isNotEmpty
                              ? widget.school.diplome
                              : 'Diplôme reconnu par l\'État',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Quick Facts Row
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.timer_rounded,
                    title: isAr ? 'مدة الدراسة' : 'Durée',
                    value: duree,
                    color: const Color(0xFF0284C7),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoTile(
                    icon: Icons.how_to_reg_rounded,
                    title: isAr ? 'طريقة القبول' : 'Concours',
                    value: widget.school.concours ?? 'Sélection',
                    color: const Color(0xFFD97706),
                    isDark: isDark,
                  ),
                ),
              ],
            ),



            const SizedBox(height: 20),

            // Section: Seuils Historiques avec disposition en grille 2 à 3 colonnes sur PC
            if (seuils != null && seuils.isNotEmpty)
              _buildSectionCard(
                title: isAr
                    ? 'عتبات الانتقاء الأولي السابقة'
                    : 'Seuils de présélection historiques',
                icon: Icons.analytics_rounded,
                iconColor: const Color(0xFF8B5CF6),
                cardBg: cardBg,
                isDark: isDark,
                child: _buildSeuilsTable(seuils, isAr),
              ),

            const SizedBox(height: 16),

            // Section: Villes / Campus
            if (villes != null && villes.isNotEmpty)
              _buildSectionCard(
                title: isAr ? 'مواقع ومدن المؤسسة' : 'Réseau et Campus',
                icon: Icons.map_rounded,
                iconColor: const Color(0xFF10B981),
                cardBg: cardBg,
                isDark: isDark,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: villes.map((v) {
                    final villeName =
                        v is Map ? (v['ville'] ?? '') : v.toString();
                    return Chip(
                      avatar: const Icon(Icons.location_on_outlined,
                          size: 14, color: Color(0xFF0F5132)),
                      label: Text(villeName,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 16),

            // Section: Débouchés
            if (debouches != null && debouches.isNotEmpty)
              _buildSectionCard(
                title: isAr
                    ? 'الآفاق المهنية وفرص العمل'
                    : 'Débouchés professionnels',
                icon: Icons.work_outline_rounded,
                iconColor: const Color(0xFF059669),
                cardBg: cardBg,
                isDark: isDark,
                child: Column(
                  children: debouches.map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 16),

            // Section: Conseils Clés
            if (conseils != null && conseils.isNotEmpty)
              _buildSectionCard(
                title: isAr
                    ? 'نصائح وتوجيهات للترشيح'
                    : 'Conseils stratégiques pour candidater',
                icon: Icons.lightbulb_outline_rounded,
                iconColor: const Color(0xFFF59E0B),
                cardBg: cardBg,
                isDark: isDark,
                child: Column(
                  children: conseils.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.tips_and_updates_rounded,
                              size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  /// Grille responsive des seuils historiques (2 à 3 sessions par ligne sur PC)
  Widget _buildSeuilsTable(Map<String, dynamic> seuils, bool isAr) {
    final entries = seuils.entries.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 950
            ? 3
            : (constraints.maxWidth >= 550 ? 2 : 1);
        final spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: entries.map((entry) {
            final rawKey =
                entry.key.replaceAll('annee_', '').replaceAll('_', ' ');
            final val = entry.value;

            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5132).withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0F5132).withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F5132),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Session $rawKey',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (val is Map)
                      ...val.entries.map((sub) {
                        final label = sub.key.replaceAll('_', ' ');
                        final score = '${sub.value}';
                        final isRemark = label.toLowerCase().contains('remarque') ||
                            label.toLowerCase().contains('note');
                        if (isRemark) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              score,
                              style: const TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F5132)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  score.contains('/') ? score : '$score/20',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                    color: Color(0xFF0F5132),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr ? 'عتبة الانتقاء' : 'Seuil officiel',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F5132)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$val',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: Color(0xFF0F5132),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
