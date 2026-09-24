import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/curriculum_models.dart';
import 'app_language_service.dart';
import 'curriculum_service.dart';
import 'focus_timer_service.dart';
import 'user_profile_service.dart';
import '../screens/orientation_screen.dart';
import '../screens/subject_detail_screen.dart';
import '../screens/focus_mode_screen.dart';

enum BannerType {
  contentSuggestion,
  orientation,
  ninePoints,
  focusDomain,
  myPocket,
  windowsApp,
  androidAppPreview,
  adSenseTest,
  upcomingAppTeaser,
}

class SmartBannerItem {
  final String id;
  final BannerType type;
  final String title;
  final String titleAr;
  final String subtitle;
  final String subtitleAr;
  final String description;
  final String descriptionAr;
  final String buttonLabel;
  final String buttonLabelAr;
  final String badgeText;
  final String badgeTextAr;
  final Color badgeColor;
  final Color primaryColor;
  final IconData? icon;
  final String? assetImagePath;
  final VoidCallback onTap;
  final double score;
  final String? targetCategory;

  const SmartBannerItem({
    required this.id,
    required this.type,
    required this.title,
    required this.titleAr,
    required this.subtitle,
    required this.subtitleAr,
    required this.description,
    required this.descriptionAr,
    required this.buttonLabel,
    required this.buttonLabelAr,
    required this.badgeText,
    required this.badgeTextAr,
    required this.badgeColor,
    required this.primaryColor,
    this.icon,
    this.assetImagePath,
    required this.onTap,
    this.score = 0.0,
    this.targetCategory,
  });
}

class SmartBannerService {
  static const String myPocketPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.badr.mypocket&hl=fr';
  static const String ninePointsPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ninepoints.damee&hl=fr';
  static const String focusDomainYouTubeUrl =
      'https://www.youtube.com/channel/UCx_51Vr3-E_MZPQY49UUCRw';

  // Matrice officielle marocaine des matières majeures par niveau et filière
  static const Map<String, List<String>> _branchCoreSubjects = {
    // Tronc Commun
    'tronc-commun/lettres': ['arabe', 'francais', 'philosophie', 'histoire-geographie', 'education-islamique'],
    'tronc-commun/lettres-sciences-humaines': ['arabe', 'francais', 'philosophie', 'histoire-geographie', 'education-islamique'],
    'tronc-commun/sciences': ['mathematiques', 'physique-chimie', 'svt', 'informatique'],
    'tronc-commun/sciences-biof': ['mathematiques', 'physique-chimie', 'svt', 'informatique'],
    'tronc-commun/technologie': ['sciences-ingenieur', 'mathematiques', 'physique-chimie'],

    // 1ère Bac (Épreuves régionales + matières de base)
    '1ere-bac/lettres-sciences-humaines': ['arabe', 'histoire-geographie', 'philosophie', 'francais', 'education-islamique', 'mathematiques'],
    '1ere-bac/sciences-experimentales': ['francais', 'arabe', 'education-islamique', 'histoire-geographie', 'mathematiques', 'physique-chimie', 'svt'],
    '1ere-bac/sciences-experimentales-biof': ['francais', 'arabe', 'education-islamique', 'histoire-geographie', 'mathematiques', 'physique-chimie', 'svt'],
    '1ere-bac/sciences-mathematiques': ['francais', 'arabe', 'education-islamique', 'histoire-geographie', 'mathematiques', 'physique-chimie'],
    '1ere-bac/sciences-mathematiques-biof': ['francais', 'arabe', 'education-islamique', 'histoire-geographie', 'mathematiques', 'physique-chimie'],
    '1ere-bac/sciences-economiques-gestion': ['economie-generale', 'comptabilite', 'francais', 'mathematiques', 'histoire-geographie', 'education-islamique'],
    '1ere-bac/sciences-technologies-electrique': ['sciences-ingenieur', 'mathematiques', 'physique-chimie', 'francais', 'arabe'],
    '1ere-bac/sciences-technologies-mecanique': ['sciences-ingenieur', 'mathematiques', 'physique-chimie', 'francais', 'arabe'],

    // 2ème Bac (Épreuves nationales obligatoires)
    '2eme-bac/lettres': ['arabe', 'philosophie', 'histoire-geographie', 'anglais', 'francais'],
    '2eme-bac/sciences-humaines': ['histoire-geographie', 'philosophie', 'arabe', 'anglais', 'francais'],
    '2eme-bac/sciences-physiques': ['physique-chimie', 'mathematiques', 'svt', 'philosophie', 'anglais'],
    '2eme-bac/sciences-physiques-biof': ['physique-chimie', 'mathematiques', 'svt', 'philosophie', 'anglais'],
    '2eme-bac/sciences-vie-terre': ['svt', 'physique-chimie', 'mathematiques', 'philosophie', 'anglais'],
    '2eme-bac/sciences-vie-terre-biof': ['svt', 'physique-chimie', 'mathematiques', 'philosophie', 'anglais'],
    '2eme-bac/sciences-maths-a': ['mathematiques', 'physique-chimie', 'svt', 'philosophie', 'anglais'],
    '2eme-bac/sciences-maths-b': ['mathematiques', 'physique-chimie', 'sciences-ingenieur', 'philosophie', 'anglais'],
    '2eme-bac/sciences-economiques': ['economie-generale', 'comptabilite', 'organisation-entreprises', 'mathematiques', 'philosophie', 'anglais'],
    '2eme-bac/sciences-gestion-comptable': ['comptabilite', 'economie-generale', 'organisation-entreprises', 'droit', 'mathematiques', 'philosophie', 'anglais'],
    '2eme-bac/sciences-technologies-electrique': ['sciences-ingenieur', 'physique-chimie', 'mathematiques', 'philosophie', 'anglais'],
    '2eme-bac/sciences-technologies-mecanique': ['sciences-ingenieur', 'physique-chimie', 'mathematiques', 'philosophie', 'anglais'],

    // 3ème Collège (Examen normalisé 3AC)
    '3eme-annee-college/biof': ['mathematiques', 'physique-chimie', 'svt', 'francais', 'arabe', 'education-islamique'],
    '3eme-annee-college/general': ['mathematiques', 'physique-chimie', 'svt', 'francais', 'arabe', 'education-islamique'],
  };

  static Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  /// Retourne les identifiants des matières prioritaires pour le niveau et la filière
  static List<String> _getCoreSubjectIds(String levelId, String branchId) {
    final branchKey = '$levelId/$branchId';
    if (_branchCoreSubjects.containsKey(branchKey)) {
      return _branchCoreSubjects[branchKey]!;
    }

    final b = branchId.toLowerCase();
    if (b.contains('lettre') || b.contains('humaine') || b.contains('adab')) {
      return ['arabe', 'philosophie', 'histoire-geographie', 'francais', 'anglais', 'education-islamique'];
    }
    if (b.contains('eco') || b.contains('gestion') || b.contains('compt')) {
      return ['economie-generale', 'comptabilite', 'organisation-entreprises', 'mathematiques', 'droit', 'philosophie', 'anglais'];
    }
    if (b.contains('electrique') || b.contains('mecanique') || b.contains('techno')) {
      return ['sciences-ingenieur', 'mathematiques', 'physique-chimie', 'philosophie', 'anglais'];
    }
    return ['mathematiques', 'physique-chimie', 'svt', 'philosophie', 'anglais'];
  }

  /// Vérifie strictement les catégories qui contiennent réellement des documents pour cette matière
  static List<String> _getAvailableCategories(SubjectItem subject) {
    const checkOrder = ['resumes', 'exercices', 'controles', 'examens', 'cours'];
    final available = <String>[];
    for (final cat in checkOrder) {
      if (subject.documents.any((d) => d.category == cat)) {
        available.add(cat);
      }
    }
    return available;
  }

  /// Génère une suggestion pédagogique ciblée (Exploitation ou Exploration)
  static SmartBannerItem? _buildSmartContentSuggestion({
    required BuildContext context,
    required CurriculumService curriculum,
    required UserProfileService userProfile,
    required AppLanguageService langService,
    required bool isExploration,
    int saltIndex = 0,
  }) {
    final isAr = langService.isArabic;
    final levelId = curriculum.selectedLevelId;
    final branchId = curriculum.selectedBranchId;
    final allSubjects = curriculum.getCurrentSubjects();
    if (allSubjects.isEmpty) return null;

    final coreSubjectIds = _getCoreSubjectIds(levelId, branchId);

    // Filtrer pour ne garder QUE les matières pertinentes à la filière
    final relevantSubjects = allSubjects
        .where((s) => coreSubjectIds.contains(s.id))
        .toList();

    final candidatePool = relevantSubjects.isNotEmpty ? relevantSubjects : allSubjects;

    // Trier selon l'historique et les affinités
    candidatePool.sort((a, b) {
      final statA = userProfile.subjectStats[a.id] ?? 0;
      final statB = userProfile.subjectStats[b.id] ?? 0;
      if (statA != statB) return statB.compareTo(statA);
      final idxA = coreSubjectIds.indexOf(a.id);
      final idxB = coreSubjectIds.indexOf(b.id);
      return idxA.compareTo(idxB);
    });

    SubjectItem chosenSubject;
    if (!isExploration) {
      // 70% Exploitation : matière la plus consultée ou 1ère matière clé
      chosenSubject = candidatePool.first;
    } else {
      // 30% Exploration : découvrir une autre matière clé de la filière
      final int pickIndex = (1 + saltIndex) % candidatePool.length;
      chosenSubject = candidatePool[pickIndex];
    }

    // Vérifier les catégories réellement disponibles dans cette matière
    final availableCategories = _getAvailableCategories(chosenSubject);
    if (availableCategories.isEmpty) {
      return null; // Règle d'or : ne rien proposer s'il n'y a aucun document
    }

    // Choisir la catégorie cible
    String targetCat;
    if (!isExploration) {
      final userPrefCat = userProfile.getTopCategory(allowedCategories: availableCategories);
      if (availableCategories.contains(userPrefCat)) {
        targetCat = userPrefCat;
      } else if (availableCategories.contains('examens')) {
        targetCat = 'examens';
      } else if (availableCategories.contains('resumes')) {
        targetCat = 'resumes';
      } else if (availableCategories.contains('exercices')) {
        targetCat = 'exercices';
      } else {
        targetCat = availableCategories.first;
      }
    } else {
      // Exploration : proposer un type de contenu non encore testé
      final otherCats = availableCategories.where((c) => c != 'cours').toList();
      if (otherCats.isNotEmpty) {
        targetCat = otherCats[saltIndex % otherCats.length];
      } else {
        targetCat = availableCategories.first;
      }
    }

    final subjectName = isAr ? chosenSubject.nameAr : chosenSubject.nameFr;

    // Génération dynamique des accroches et A/B Testing selon la catégorie
    String title;
    String titleAr;
    String subtitle;
    String subtitleAr;
    String desc;
    String descAr;
    String buttonText;
    String buttonTextAr;
    String badge;
    String badgeAr;
    Color badgeColor;
    Color primaryColor;
    IconData icon;

    switch (targetCat) {
      case 'resumes':
        title = 'Fiches : $subjectName';
        titleAr = 'ملخصات : $subjectName';
        subtitle = 'L\'essentiel du cours en 1 page';
        subtitleAr = 'أهم القواعد في صفحة واحدة';
        desc = 'Révisez les points essentiels et formules clés de $subjectName pour mémoriser rapidement.';
        descAr = 'راجع المفاهيم الأساسية وخلاصات دروس $subjectName لتثبيت معلوماتك بسرعة.';
        buttonText = 'Consulter les fiches';
        buttonTextAr = 'مراجعة الملخصات';
        badge = 'Fiches Clés';
        badgeAr = 'ملخصات مركزة';
        badgeColor = const Color(0xFF7C3AED);
        primaryColor = const Color(0xFF6D28D9);
        icon = Icons.menu_book_rounded;
        break;

      case 'exercices':
        title = 'Exercices : $subjectName';
        titleAr = 'تمارين : $subjectName';
        subtitle = 'Séries d\'application corrigées';
        subtitleAr = 'سلاسل تطبيقية مع الحلول';
        desc = 'Entraînez-vous avec des séries d\'exercices types et leurs solutions détaillées.';
        descAr = 'تدرب على تمارين تطبيقية نموذجية في مادة $subjectName مع الحلول المفصلة.';
        buttonText = 'S\'entraîner aux exercices';
        buttonTextAr = 'حل التمارين';
        badge = 'Pratique & Corrigés';
        badgeAr = 'تمارين محلولة';
        badgeColor = const Color(0xFF059669);
        primaryColor = const Color(0xFF047857);
        icon = Icons.edit_note_rounded;
        break;

      case 'controles':
        title = 'Contrôles : $subjectName';
        titleAr = 'فروض : $subjectName';
        subtitle = 'Devoirs surveillés modèles';
        subtitleAr = 'فروض محروسة ونماذج';
        desc = 'Préparez vos devoirs surveillés de $subjectName avec des sujets réels et barèmes.';
        descAr = 'استعد للمراقبة المستمرة في $subjectName مع نماذج فروض سابقة وسلم التنقيط.';
        buttonText = 'Voir les contrôles';
        buttonTextAr = 'نماذج الفروض';
        badge = 'Contrôle Continu';
        badgeAr = 'مراقبة مستمرة';
        badgeColor = const Color(0xFFD97706);
        primaryColor = const Color(0xFFB45309);
        icon = Icons.quiz_rounded;
        break;

      case 'examens':
        final isBac2 = levelId == '2eme-bac';
        final isBac1 = levelId == '1ere-bac';
        final isCollege = levelId == '3eme-annee-college';

        if (isBac2) {
          title = 'Annales : $subjectName';
          titleAr = 'امتحانات وطنية : $subjectName';
          subtitle = 'Sujets officiels & corrigés';
          subtitleAr = 'مواضيع وعناصر الإجابة';
          desc = 'Entraînez-vous sur les épreuves du National de $subjectName avec corrigés conformes.';
          descAr = 'راجع نماذج الامتحان الوطني في $subjectName مع التصحيح المعتمد وسلم التنقيط.';
          badge = 'National Bac';
          badgeAr = 'امتحان وطني';
        } else if (isBac1) {
          title = 'Régional : $subjectName';
          titleAr = 'امتحان جهوي : $subjectName';
          subtitle = 'Préparation officielle Régional';
          subtitleAr = 'التحضير الرسمي للجهوي';
          desc = 'Sujets récents d\'examens régionaux de $subjectName pour assurer votre mention.';
          descAr = 'مواضيع الامتحانات الجهوية في مادة $subjectName لضمان أعلى نقطة.';
          badge = 'Régional 1BAC';
          badgeAr = 'امتحان جهوي';
        } else if (isCollege) {
          title = 'Brevet : $subjectName';
          titleAr = 'امتحانات 3AC : $subjectName';
          subtitle = 'Épreuves locales et régionales';
          subtitleAr = 'الموحد المحلي والجهوي';
          desc = 'Entraînez-vous sur les épreuves normalisées de $subjectName avec corrigés.';
          descAr = 'نماذج الامتحانات الموحدة في $subjectName مع الحلول المعتمدة.';
          badge = 'Brevet 3AC';
          badgeAr = 'موحد إعدادي';
        } else {
          title = 'Examens : $subjectName';
          titleAr = 'امتحانات : $subjectName';
          subtitle = 'Sujets types avec corrigés';
          subtitleAr = 'نماذج موحدة مع الحلول';
          desc = 'Épreuves et séries d\'évaluation pour valider vos acquis en $subjectName.';
          descAr = 'نماذج اختبارات لتقييم مكتسباتك والتفوق في مادة $subjectName.';
          badge = 'Examens Types';
          badgeAr = 'امتحانات نموذجية';
        }

        buttonText = 'Réviser $subjectName';
        buttonTextAr = 'مراجعة $subjectName';
        badgeColor = const Color(0xFF2563EB);
        primaryColor = const Color(0xFF1D4ED8);
        icon = Icons.assignment_turned_in_rounded;
        break;

      default: // 'cours'
        title = 'Cours : $subjectName';
        titleAr = 'درس : $subjectName';
        subtitle = 'Notions fondamentales & cours';
        subtitleAr = 'الشروحات والمفاهيم الأساسية';
        desc = 'Maîtrisez les concepts essentiels du programme de $subjectName pas à pas.';
        descAr = 'استوعب الدروس الأساسية في مادة $subjectName خطوة بخطوة بكل وضوح.';
        buttonText = 'Explorer le cours';
        buttonTextAr = 'قراءة الدرس';
        badge = 'Cours Officiel';
        badgeAr = 'درس رسمي';
        badgeColor = const Color(0xFF0F5132);
        primaryColor = const Color(0xFF0F5132);
        icon = Icons.school_rounded;
    }

    return SmartBannerItem(
      id: 'smart_sugg_${chosenSubject.id}_$targetCat',
      type: BannerType.contentSuggestion,
      score: isExploration ? 88.0 : 100.0,
      title: title,
      titleAr: titleAr,
      subtitle: subtitle,
      subtitleAr: subtitleAr,
      description: desc,
      descriptionAr: descAr,
      buttonLabel: buttonText,
      buttonLabelAr: buttonTextAr,
      badgeText: badge,
      badgeTextAr: badgeAr,
      badgeColor: badgeColor,
      primaryColor: primaryColor,
      icon: icon,
      targetCategory: targetCat,
      onTap: () {
        userProfile.recordBannerClick(
          bannerId: 'smart_sugg_${chosenSubject.id}_$targetCat',
          bannerType: 'contentSuggestion',
          category: targetCat,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SubjectDetailScreen(
              subject: chosenSubject,
              levelId: levelId,
              initialCategory: targetCat,
            ),
          ),
        );
      },
    );
  }

  /// Bannières de démonstration AdSense réalistes avec rotation de formats éducatifs
  static SmartBannerItem _buildAdSenseVariant({required int variantIndex}) {
    switch (variantIndex % 3) {
      case 0:
        return SmartBannerItem(
          id: 'adsense_demo_prepa',
          type: BannerType.adSenseTest,
          score: 45.0,
          title: 'Espace Prépa & Concours',
          titleAr: 'فضاء مباريات ما بعد الباك',
          subtitle: 'Grandes Écoles Maroc 2026',
          subtitleAr: 'مباريات المدارس العليا 2026',
          description: 'Préparez les concours d\'accès (ENCG, ENSA, FMP, ENA) avec des annales ciblées.',
          descriptionAr: 'استعد لمباريات ولوج المدارس العليا عبر نماذج مواضيع السنوات السابقة.',
          buttonLabel: 'En savoir plus',
          buttonLabelAr: 'اكتشف المزيد',
          badgeText: 'Sponsor • Démo AdSense',
          badgeTextAr: 'إعلان تجريبي',
          badgeColor: const Color(0xFF2563EB),
          primaryColor: const Color(0xFF1D4ED8),
          icon: Icons.campaign_rounded,
          onTap: () {},
        );

      case 1:
        return SmartBannerItem(
          id: 'adsense_demo_coaching',
          type: BannerType.adSenseTest,
          score: 45.0,
          title: 'Soutien Scolaire en Ligne',
          titleAr: 'حصص الدعم والمرافقة',
          subtitle: 'Plateforme Pédagogique Partenaire',
          subtitleAr: 'منصة تعليمية شريكة',
          description: 'Coaching personnalisé et séances en direct pour renforcer votre moyenne.',
          descriptionAr: 'مرافقة تربوية وحصص تفاعلية لتعزيز مستواك وضمان تفوقك الدراسي.',
          buttonLabel: 'Essayer gratuitement',
          buttonLabelAr: 'تجربة مجانية',
          badgeText: 'Annonce Sponsorisée',
          badgeTextAr: 'إعلان ممول',
          badgeColor: const Color(0xFF059669),
          primaryColor: const Color(0xFF047857),
          icon: Icons.cast_for_education_rounded,
          onTap: () {},
        );

      default:
        return SmartBannerItem(
          id: 'adsense_demo_simulator',
          type: BannerType.adSenseTest,
          score: 45.0,
          title: 'Simulateur de Notes & Seuils',
          titleAr: 'محاكي النقط والعتبات',
          subtitle: 'Outils d\'Admission Étudiante',
          subtitleAr: 'أدوات حساب معدلات القبول',
          description: 'Calculez votre moyenne pondérée et estimez vos chances d\'admission post-bac.',
          descriptionAr: 'احسب معدلك العام وتوقع حظوظك في الانتقاء الأولي للمدارس والمعاهد.',
          buttonLabel: 'Tester le simulateur',
          buttonLabelAr: 'تجربة المحاكي',
          badgeText: 'Outil Partenaire',
          badgeTextAr: 'أداة شريكة',
          badgeColor: const Color(0xFFEA580C),
          primaryColor: const Color(0xFFC2410C),
          icon: Icons.calculate_rounded,
          onTap: () {},
        );
    }
  }

  /// Évalue et retourne les bannières de la colonne gauche (Pédagogie & Examens - 2 à 3 cartes)
  static List<SmartBannerItem> getLeftBanners({
    required BuildContext context,
    required CurriculumService curriculum,
    required UserProfileService userProfile,
    required FocusTimerService focusTimer,
    required AppLanguageService langService,
    required VoidCallback onWindowsDownload,
  }) {
    final levelId = curriculum.selectedLevelId;
    final List<SmartBannerItem> items = [];

    // 1. Suggestion Pédagogique Principale (Matière clé de la filière + catégorie vérifiée)
    final primarySuggestion = _buildSmartContentSuggestion(
      context: context,
      curriculum: curriculum,
      userProfile: userProfile,
      langService: langService,
      isExploration: false,
    );
    if (primarySuggestion != null) {
      items.add(primarySuggestion);
    }

    // 2. Orientation Post-Bac 2026 (Très forte sur 2BAC, modérée sur 1BAC)
    final double orientationScore = (levelId == '2eme-bac')
        ? 95.0
        : (levelId == '1ere-bac' ? 78.0 : 20.0);

    if (levelId == '2eme-bac' || levelId == '1ere-bac') {
      items.add(SmartBannerItem(
        id: 'orientation_2026',
        type: BannerType.orientation,
        score: orientationScore,
        title: 'Orientation Post-Bac',
        titleAr: 'دليل التوجيه لما بعد الباك',
        subtitle: 'Écoles, seuils & simulateur',
        subtitleAr: 'المدارس العليا والعتبات',
        description: 'Seuils officiels (ENCG, ENSA, FMP...) et calcul de vos chances d\'admission.',
        descriptionAr: 'عتبات المدارس العليا الرسمية ومحاكي حظوظ القبول.',
        buttonLabel: 'Explorer l\'Orientation',
        buttonLabelAr: 'استكشاف التوجيه',
        badgeText: '2026',
        badgeTextAr: '2026',
        badgeColor: const Color(0xFFF59E0B),
        primaryColor: const Color(0xFF0F5132),
        icon: Icons.explore_rounded,
        onTap: () {
          userProfile.recordBannerClick(bannerId: 'orientation_2026', bannerType: 'orientation');
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OrientationScreen()),
          );
        },
      ));
    } else {
      // Pour le Tronc Commun / Collège : seconde suggestion pédagogique de découverte
      final secondarySuggestion = _buildSmartContentSuggestion(
        context: context,
        curriculum: curriculum,
        userProfile: userProfile,
        langService: langService,
        isExploration: true,
        saltIndex: 1,
      );
      if (secondarySuggestion != null) {
        items.add(secondarySuggestion);
      }
    }

    // 3. Nine Points (Jeu de réflexion sur Google Play - Idéal pour la détente)
    items.add(SmartBannerItem(
      id: 'nine_points_game',
      type: BannerType.ninePoints,
      score: (levelId == 'tronc-commun' || levelId == '3eme-annee-college') ? 85.0 : 65.0,
      title: 'Nine Points',
      titleAr: 'لعبة ناين بوينتس',
      subtitle: 'Dames & Stratégie Traditionnelle',
      subtitleAr: 'لعبة الدامة والذكاء الذهني',
      description: 'Défiez vos amis et stimulez votre esprit logique entre deux séances de cours.',
      descriptionAr: 'اختبر ذكاءك واستراتيجيتك وتحد أصدقاءك في فترات الاستراحة.',
      buttonLabel: 'Jouer sur Google Play',
      buttonLabelAr: 'تثبيت من Google Play',
      badgeText: 'Pause Détente',
      badgeTextAr: 'استراحة ذكاء',
      badgeColor: const Color(0xFFEA580C),
      primaryColor: const Color(0xFFC2410C),
      assetImagePath: 'assets/images/ninepoints_icon.jpg',
      onTap: () {
        userProfile.recordBannerClick(bannerId: 'nine_points_game', bannerType: 'ninePoints');
        _launchExternalUrl(ninePointsPlayStoreUrl);
      },
    ));

    // Si on a moins de 3 cartes, ajouter une bannière AdSense démo
    if (items.length < 3) {
      items.add(_buildAdSenseVariant(variantIndex: 0));
    }

    items.sort((a, b) => b.score.compareTo(a.score));
    return items.take(3).toList();
  }

  /// Évalue et retourne les bannières de la colonne droite (Écosystème & Apps - 2 à 3 cartes)
  static List<SmartBannerItem> getRightBanners({
    required BuildContext context,
    required CurriculumService curriculum,
    required UserProfileService userProfile,
    required FocusTimerService focusTimer,
    required AppLanguageService langService,
    required VoidCallback onWindowsDownload,
  }) {
    final levelId = curriculum.selectedLevelId;
    final List<SmartBannerItem> items = [];

    // 1. Focus Domain YouTube Channel (Priorité accrue si Pomodoro actif)
    double focusDomainScore = 70.0;
    if (focusTimer.isRunning || focusTimer.remainingSeconds < focusTimer.totalFocusSecondsInTechnique) {
      focusDomainScore += 25.0;
    }
    if (levelId == '2eme-bac' || levelId == '1ere-bac') {
      focusDomainScore += 10.0;
    }

    items.add(SmartBannerItem(
      id: 'focus_domain_youtube',
      type: BannerType.focusDomain,
      score: focusDomainScore,
      title: 'Focus Domain',
      titleAr: 'قناة فوكس دومين',
      subtitle: 'Study With Me • Ambiance Zen',
      subtitleAr: 'مذاكرة جماعية وموسيقى هادئة',
      description: 'Sessions d\'étude immersives « Study With Me » pour réviser dans le calme absolu.',
      descriptionAr: 'فيديوهات تركيز وموسيقى محفزة للمذاكرة اليومية بدون تشتت.',
      buttonLabel: 'Regarder sur YouTube',
      buttonLabelAr: 'مشاهدة على يوتيوب',
      badgeText: 'YouTube • Study',
      badgeTextAr: 'يوتيوب • تركيز',
      badgeColor: const Color(0xFFDC2626),
      primaryColor: const Color(0xFFDC2626),
      icon: Icons.play_circle_fill_rounded,
      onTap: () {
        userProfile.recordBannerClick(bannerId: 'focus_domain_youtube', bannerType: 'focusDomain');
        _launchExternalUrl(focusDomainYouTubeUrl);
      },
    ));

    // 2. MyPocket (Gestion de Budget & Épargne sur Google Play)
    final double myPocketScore = (levelId == '2eme-bac') ? 85.0 : 72.0;
    items.add(SmartBannerItem(
      id: 'mypocket_app',
      type: BannerType.myPocket,
      score: myPocketScore,
      title: 'MyPocket',
      titleAr: 'ماي بوكيت - مصاريفي',
      subtitle: 'Gestion de Budget & Épargne',
      subtitleAr: 'تنظيم المصاريف والمدخرات',
      description: 'Suivez vos dépenses quotidiennes et gérez votre budget étudiant en toute simplicité.',
      descriptionAr: 'تطبيق ذكي لتنظيم مصروفك اليومي وإدارة ميزانيتك بكل سهولة.',
      buttonLabel: 'Installer sur Google Play',
      buttonLabelAr: 'تثبيت من Google Play',
      badgeText: 'Recommandé',
      badgeTextAr: 'تطبيق موصى به',
      badgeColor: const Color(0xFF7C3AED),
      primaryColor: const Color(0xFF6D28D9),
      assetImagePath: 'assets/images/mypocket_icon.jpg',
      onTap: () {
        userProfile.recordBannerClick(bannerId: 'mypocket_app', bannerType: 'myPocket');
        _launchExternalUrl(myPocketPlayStoreUrl);
      },
    ));

    // 3. Application PC Windows (uniquement sur le Web) / Espace Concentration (sur Windows natif)
    if (kIsWeb) {
      items.add(SmartBannerItem(
        id: 'windows_app_pc',
        type: BannerType.windowsApp,
        score: 75.0,
        title: 'App PC Windows',
        titleAr: 'تطبيق ويندوز للكمبيوتر',
        subtitle: 'Cours Maroc pour Windows',
        subtitleAr: 'نسخة الكمبيوتر الرسمية',
        description: 'Installez l\'application officielle sur votre PC pour réviser 100% hors-ligne sur grand écran.',
        descriptionAr: 'استمتع بمذاكرة مريحة 100% بدون إنترنت على شاشة حاسوبك.',
        buttonLabel: 'Télécharger pour PC (.zip)',
        buttonLabelAr: 'تحميل للكمبيوتر (.zip)',
        badgeText: '100% Hors-ligne',
        badgeTextAr: 'بدون إنترنت',
        badgeColor: const Color(0xFF0F5132),
        primaryColor: const Color(0xFF0F5132),
        icon: Icons.laptop_windows_rounded,
        onTap: () {
          userProfile.recordBannerClick(bannerId: 'windows_app_pc', bannerType: 'windowsApp');
          onWindowsDownload();
        },
      ));
    } else {
      items.add(SmartBannerItem(
        id: 'pomodoro_tech_guide',
        type: BannerType.focusDomain,
        score: 75.0,
        title: 'Espace Concentration',
        titleAr: 'فضاء التركيز والدراسة',
        subtitle: 'Technique Pomodoro & Rythmes',
        subtitleAr: 'تقنية بومودورو للإنتاجية',
        description: 'Boostez votre mémorisation avec des cycles de révision et pauses structurées pour une efficacité maximale.',
        descriptionAr: 'ضاعف تركيزك وقدرتك على الاستيعاب بفترات مراجعة منتظمة واستراحات مبرمجة.',
        buttonLabel: 'Ouvrir l\'Espace Focus',
        buttonLabelAr: 'فتح فضاء التركيز',
        badgeText: 'Méthode Active',
        badgeTextAr: 'طريقة فعالة',
        badgeColor: const Color(0xFF7C3AED),
        primaryColor: const Color(0xFF7C3AED),
        icon: Icons.timer_outlined,
        onTap: () {
          userProfile.recordBannerClick(bannerId: 'pomodoro_tech_guide', bannerType: 'focusDomain');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FocusModeScreen(),
            ),
          );
        },
      ));
    }

    // 4. Bannière Test Google AdSense (Format démo rotatif pour tester la monétisation)
    final int sessionVariant = DateTime.now().minute % 3;
    items.add(_buildAdSenseVariant(variantIndex: sessionVariant));

    items.sort((a, b) => b.score.compareTo(a.score));
    return items.take(3).toList();
  }
}
