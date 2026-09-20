class DocumentItem {
  final String id;
  final String name;
  final String title;
  final String category; // 'cours', 'exercices', 'examens', 'resumes'
  final String semester; // 'semestre-1', 'semestre-2', 'nationaux', 'general'
  final bool isCorrige;
  final int size;
  final String driveUrl;

  final String? region;

  DocumentItem({
    required this.id,
    required this.name,
    required this.title,
    required this.category,
    required this.semester,
    required this.isCorrige,
    required this.size,
    required this.driveUrl,
    this.region,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'cours',
      semester: json['semester'] as String? ?? 'general',
      isCorrige: json['isCorrige'] as bool? ?? false,
      size: (json['size'] as num?)?.toInt() ?? 0,
      driveUrl: json['driveUrl'] as String? ?? '',
      region: json['region'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'category': category,
      'semester': semester,
      'isCorrige': isCorrige,
      'size': size,
      'driveUrl': driveUrl,
      if (region != null) 'region': region,
    };
  }

  int get examYear {
    final match = RegExp(r'(20\d\d|19\d\d)').firstMatch(title);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  String get formattedSize {
    if (size <= 0) return '';
    if (size < 1024 * 1024) {
      final kb = (size / 1024).toStringAsFixed(0);
      return '$kb Ko';
    }
    final mb = (size / (1024 * 1024)).toStringAsFixed(1);
    return '$mb Mo';
  }

  String get categoryDisplayName {
    switch (category) {
      case 'cours':
        return 'Cours';
      case 'exercices':
        return 'Exercices';
      case 'controles':
        return 'Contrôles continus';
      case 'examens':
        return 'Examens';
      case 'resumes':
        return 'Résumés';
      default:
        return category.toUpperCase();
    }
  }

  String get semesterDisplayName {
    switch (semester) {
      case 'semestre-1':
        return 'Semestre 1';
      case 'semestre-2':
        return 'Semestre 2';
      case 'nationaux':
        return 'Examens Nationaux';
      case 'regionaux':
        return 'Examens Régionaux';
      default:
        return 'Général';
    }
  }
}

class MoroccanRegion {
  final String id;
  final String nameFr;
  final String nameAr;
  final String shortName;

  const MoroccanRegion({
    required this.id,
    required this.nameFr,
    required this.nameAr,
    required this.shortName,
  });

  String localizedName(String lang) {
    if (lang == 'ar') return nameAr;
    return nameFr;
  }

  static const List<MoroccanRegion> all = [
    MoroccanRegion(
      id: 'casablanca-settat',
      nameFr: 'Casablanca - Settat',
      nameAr: 'الدار البيضاء سطات',
      shortName: 'Casablanca',
    ),
    MoroccanRegion(
      id: 'rabat-sale-kenitra',
      nameFr: 'Rabat - Salé - Kénitra',
      nameAr: 'الرباط سلا القنيطرة',
      shortName: 'Rabat',
    ),
    MoroccanRegion(
      id: 'fes-meknes',
      nameFr: 'Fès - Meknès',
      nameAr: 'فاس مكناس',
      shortName: 'Fès',
    ),
    MoroccanRegion(
      id: 'marrakech-safi',
      nameFr: 'Marrakech - Safi',
      nameAr: 'مراكش آسفي',
      shortName: 'Marrakech',
    ),
    MoroccanRegion(
      id: 'tanger-tetouan-al-hoceima',
      nameFr: 'Tanger - Tétouan - Al Hoceïma',
      nameAr: 'طنجة تطوان الحسيمة',
      shortName: 'Tanger',
    ),
    MoroccanRegion(
      id: 'souss-massa',
      nameFr: 'Souss - Massa',
      nameAr: 'سوس ماسة',
      shortName: 'Souss',
    ),
    MoroccanRegion(
      id: 'beni-mellal-khenifra',
      nameFr: 'Béni Mellal - Khénifra',
      nameAr: 'بني ملال خنيفرة',
      shortName: 'Béni Mellal',
    ),
    MoroccanRegion(
      id: 'oriental',
      nameFr: "L'Oriental",
      nameAr: 'الشرق',
      shortName: 'Oriental',
    ),
    MoroccanRegion(
      id: 'draa-tafilalet',
      nameFr: 'Drâa - Tafilalet',
      nameAr: 'درعة تافيلالت',
      shortName: 'Drâa',
    ),
    MoroccanRegion(
      id: 'guelmim-oued-noun',
      nameFr: 'Guelmim - Oued Noun',
      nameAr: 'كلميم واد نون',
      shortName: 'Guelmim',
    ),
    MoroccanRegion(
      id: 'laayoune-sakia-el-hamra',
      nameFr: 'Laâyoune - Sakia El Hamra',
      nameAr: 'العيون الساقية الحمراء',
      shortName: 'Laâyoune',
    ),
    MoroccanRegion(
      id: 'dakhla-oued-ed-dahab',
      nameFr: 'Dakhla - Oued Ed-Dahab',
      nameAr: 'الداخلة وادي الذهب',
      shortName: 'Dakhla',
    ),
  ];
}

class SubjectMeta {
  final String id;
  final String nameFr;
  final String nameAr;
  final String? nameEn;
  final int colorHex;
  final String iconCode;

  const SubjectMeta({
    required this.id,
    required this.nameFr,
    required this.nameAr,
    this.nameEn,
    required this.colorHex,
    required this.iconCode,
  });

  String localizedName(String lang) {
    if (lang == 'ar') return nameAr;
    if (lang == 'en' && nameEn != null && nameEn!.isNotEmpty) return nameEn!;
    return nameFr;
  }

  static const Map<String, SubjectMeta> subjects = {
    'mathematiques': SubjectMeta(
      id: 'mathematiques',
      nameFr: 'Mathématiques',
      nameAr: 'الرياضيات',
      nameEn: 'Mathematics',
      colorHex: 0xFF2563EB, // Royal Blue
      iconCode: 'functions',
    ),
    'physique-chimie': SubjectMeta(
      id: 'physique-chimie',
      nameFr: 'Physique - Chimie',
      nameAr: 'الفيزياء والكيمياء',
      nameEn: 'Physics - Chemistry',
      colorHex: 0xFF0D9488, // Deep Teal
      iconCode: 'science',
    ),
    'svt': SubjectMeta(
      id: 'svt',
      nameFr: 'SVT',
      nameAr: 'علوم الحياة والأرض',
      nameEn: 'SVT (Life & Earth Sciences)',
      colorHex: 0xFF16A34A, // Forest Green
      iconCode: 'biotech',
    ),
    'philosophie': SubjectMeta(
      id: 'philosophie',
      nameFr: 'Philosophie',
      nameAr: 'الفلسفة',
      nameEn: 'Philosophy',
      colorHex: 0xFFD97706, // Amber
      iconCode: 'psychology',
    ),
    'arabe': SubjectMeta(
      id: 'arabe',
      nameFr: 'Langue Arabe',
      nameAr: 'اللغة العربية',
      nameEn: 'Arabic Language',
      colorHex: 0xFF059669, // Emerald
      iconCode: 'menu_book',
    ),
    'francais': SubjectMeta(
      id: 'francais',
      nameFr: 'Français',
      nameAr: 'اللغة الفرنسية',
      nameEn: 'French',
      colorHex: 0xFF7C3AED, // Violet
      iconCode: 'auto_stories',
    ),
    'anglais': SubjectMeta(
      id: 'anglais',
      nameFr: 'Anglais',
      nameAr: 'اللغة الإنجليزية',
      nameEn: 'English',
      colorHex: 0xFF0284C7, // Sky
      iconCode: 'language',
    ),
    'histoire-geographie': SubjectMeta(
      id: 'histoire-geographie',
      nameFr: 'Histoire - Géographie',
      nameAr: 'التاريخ والجغرافيا',
      nameEn: 'History - Geography',
      colorHex: 0xFFEA580C, // Coral / Orange
      iconCode: 'public',
    ),
    'education-islamique': SubjectMeta(
      id: 'education-islamique',
      nameFr: 'Éducation Islamique',
      nameAr: 'التربية الإسلامية',
      nameEn: 'Islamic Studies',
      colorHex: 0xFF047857, // Islamic Green
      iconCode: 'mosque',
    ),
    'informatique': SubjectMeta(
      id: 'informatique',
      nameFr: 'Informatique',
      nameAr: 'الإعلاميات',
      nameEn: 'Computer Science',
      colorHex: 0xFF4F46E5, // Indigo
      iconCode: 'computer',
    ),
    'sciences-ingenieur': SubjectMeta(
      id: 'sciences-ingenieur',
      nameFr: "Sciences de l'Ingénieur",
      nameAr: 'علوم المهندس',
      nameEn: 'Engineering Sciences',
      colorHex: 0xFF0284C7, // Sky Blue
      iconCode: 'engineering',
    ),
    'informatique-gestion': SubjectMeta(
      id: 'informatique-gestion',
      nameFr: 'Informatique de Gestion',
      nameAr: 'إعلاميات التدبير',
      nameEn: 'Management Computing',
      colorHex: 0xFF4F46E5, // Indigo
      iconCode: 'computer',
    ),
    'economie-generale': SubjectMeta(
      id: 'economie-generale',
      nameFr: 'Économie Générale & Statistiques',
      nameAr: 'الاقتصاد العام والإحصاء',
      nameEn: 'General Economics & Statistics',
      colorHex: 0xFF0891B2, // Cyan / Teal
      iconCode: 'trending_up',
    ),
    'comptabilite': SubjectMeta(
      id: 'comptabilite',
      nameFr: 'Comptabilité & Maths Financières',
      nameAr: 'المحاسبة والرياضيات المالية',
      nameEn: 'Accounting & Financial Maths',
      colorHex: 0xFF0F766E, // Deep Emerald Teal
      iconCode: 'account_balance',
    ),
    'organisation-entreprises': SubjectMeta(
      id: 'organisation-entreprises',
      nameFr: 'Organisation des Entreprises (EOAE)',
      nameAr: 'الاقتصاد والتنظيم الإداري للمقاولات',
      nameEn: 'Business Organization (EOAE)',
      colorHex: 0xFF9333EA, // Purple
      iconCode: 'business',
    ),
    'droit': SubjectMeta(
      id: 'droit',
      nameFr: 'Droit',
      nameAr: 'القانون',
      nameEn: 'Law',
      colorHex: 0xFFDC2626, // Crimson Red
      iconCode: 'gavel',
    ),
  };

  static SubjectMeta get(String key) {
    final normalized = key.toLowerCase().trim();
    return subjects[normalized] ??
        SubjectMeta(
          id: normalized,
          nameFr: normalized.replaceAll('-', ' ').toUpperCase(),
          nameAr: normalized,
          nameEn: normalized.replaceAll('-', ' ').toUpperCase(),
          colorHex: 0xFF475569,
          iconCode: 'folder',
        );
  }
}

class SubjectItem {
  final SubjectMeta meta;
  final List<DocumentItem> documents;

  SubjectItem({
    required this.meta,
    required this.documents,
  });

  String get id => meta.id;
  String get nameFr => meta.nameFr;
  String get nameAr => meta.nameAr;
  int get colorHex => meta.colorHex;

  int get totalCount => documents.length;

  int countForCategory(String category) {
    return documents.where((d) => d.category == category).length;
  }
}

class BranchOption {
  final String id;
  final String nameFr;
  final String nameAr;
  final String? nameEn;
  final String levelId;

  const BranchOption({
    required this.id,
    required this.nameFr,
    required this.nameAr,
    this.nameEn,
    required this.levelId,
  });

  String localizedName(String lang) {
    if (lang == 'ar') return nameAr;
    if (lang == 'en' && nameEn != null && nameEn!.isNotEmpty) return nameEn!;
    return nameFr;
  }
}

class LevelOption {
  final String id;
  final String nameFr;
  final String shortName;
  final String nameAr;
  final String? nameEn;
  final List<BranchOption> branches;

  const LevelOption({
    required this.id,
    required this.nameFr,
    required this.shortName,
    required this.nameAr,
    this.nameEn,
    required this.branches,
  });

  String localizedName(String lang) {
    if (lang == 'ar') return nameAr;
    if (lang == 'en' && nameEn != null && nameEn!.isNotEmpty) return nameEn!;
    return nameFr;
  }

  static const List<LevelOption> allLevels = [
    LevelOption(
      id: '3eme-annee-college',
      nameFr: '3ème Année Collège',
      shortName: '3ème Collège',
      nameAr: 'الثالثة إعدادي',
      nameEn: '3rd Year Middle School',
      branches: [
        BranchOption(
          id: 'biof',
          nameFr: 'Parcours International (BIOF)',
          nameAr: 'المسلك الدولي (خيار فرنسية)',
          nameEn: 'International Track (BIOF)',
          levelId: '3eme-annee-college',
        ),
        BranchOption(
          id: 'general',
          nameFr: 'Parcours Général',
          nameAr: 'المسلك العام',
          nameEn: 'General Track',
          levelId: '3eme-annee-college',
        ),
      ],
    ),
    LevelOption(
      id: 'tronc-commun',
      nameFr: 'Tronc Commun',
      shortName: 'Tronc Commun',
      nameAr: 'الجذع المشترك',
      nameEn: 'Common Core',
      branches: [
        BranchOption(
          id: 'sciences',
          nameFr: 'Sciences (BIOF)',
          nameAr: 'علوم (مسلك دولي)',
          nameEn: 'Sciences (International Track)',
          levelId: 'tronc-commun',
        ),
        BranchOption(
          id: 'lettres-et-sciences-humaines',
          nameFr: 'Lettres et Sciences Humaines',
          nameAr: 'الآداب والعلوم الإنسانية',
          nameEn: 'Letters & Human Sciences',
          levelId: 'tronc-commun',
        ),
        BranchOption(
          id: 'technologie',
          nameFr: 'Technologique',
          nameAr: 'تكنولوجي',
          nameEn: 'Technology',
          levelId: 'tronc-commun',
        ),
      ],
    ),
    LevelOption(
      id: '1ere-bac',
      nameFr: '1ère Année Bac',
      shortName: '1ère Bac',
      nameAr: 'الأولى باكالوريا',
      nameEn: '1st Year Baccalaureate',
      branches: [
        BranchOption(
          id: 'sciences-experimentales',
          nameFr: 'Sciences Expérimentales',
          nameAr: 'العلوم التجريبية',
          nameEn: 'Experimental Sciences',
          levelId: '1ere-bac',
        ),
        BranchOption(
          id: 'sciences-maths',
          nameFr: 'Sciences Mathématiques',
          nameAr: 'العلوم الرياضية',
          nameEn: 'Mathematical Sciences',
          levelId: '1ere-bac',
        ),
        BranchOption(
          id: 'sciences-economiques-et-gestion',
          nameFr: 'Sciences Économiques et Gestion',
          nameAr: 'العلوم الاقتصادية والتدبير',
          nameEn: 'Economics & Management Sciences',
          levelId: '1ere-bac',
        ),
        BranchOption(
          id: 'lettres-et-sciences-humaines',
          nameFr: 'Lettres et Sciences Humaines',
          nameAr: 'الآداب والعلوم الإنسانية',
          nameEn: 'Letters and Human Sciences',
          levelId: '1ere-bac',
        ),
        BranchOption(
          id: 'sciences-technologies-electriques',
          nameFr: 'Sciences et Technologies Électriques (STE)',
          nameAr: 'العلوم والتكنولوجيات الكهربائية',
          nameEn: 'Electrical Science & Technologies',
          levelId: '1ere-bac',
        ),
        BranchOption(
          id: 'sciences-technologies-mecaniques',
          nameFr: 'Sciences et Technologies Mécaniques (STM)',
          nameAr: 'العلوم والتكنولوجيات الميكانيكية',
          nameEn: 'Mechanical Science & Technologies',
          levelId: '1ere-bac',
        ),
      ],
    ),
    LevelOption(
      id: '2eme-bac',
      nameFr: '2ème Année Bac',
      shortName: '2ème Bac',
      nameAr: 'الثانية باكالوريا',
      nameEn: '2nd Year Baccalaureate',
      branches: [
        BranchOption(
          id: 'sciences-physiques',
          nameFr: 'Sciences Physiques (PC)',
          nameAr: 'العلوم الفيزيائية',
          nameEn: 'Physical Sciences (PC)',
          levelId: '2eme-bac',
        ),
        BranchOption(
          id: 'sciences-svt',
          nameFr: 'Sciences SVT',
          nameAr: 'علوم الحياة والأرض',
          nameEn: 'Life & Earth Sciences (SVT)',
          levelId: '2eme-bac',
        ),
        BranchOption(
          id: 'sciences-maths',
          nameFr: 'Sciences Mathématiques A (SM-A)',
          nameAr: 'العلوم الرياضية أ',
          nameEn: 'Mathematical Sciences A (SM-A)',
          levelId: '2eme-bac',
        ),
        BranchOption(
          id: 'sciences-maths-b',
          nameFr: 'Sciences Mathématiques B (SM-B)',
          nameAr: 'العلوم الرياضية ب',
          nameEn: 'Mathematical Sciences B (SM-B)',
          levelId: '2eme-bac',
        ),
        BranchOption(
          id: 'sciences-economiques',
          nameFr: 'Sciences Économiques',
          nameAr: 'العلوم الاقتصادية',
          nameEn: 'Economic Sciences',
          levelId: '2eme-bac',
        ),
        BranchOption(
          id: 'sciences-gestion-comptable',
          nameFr: 'Sciences de Gestion Comptable (SGC)',
          nameAr: 'علوم التدبير المحاسباتي',
          nameEn: 'Accounting & Management Sciences (SGC)',
          levelId: '2eme-bac',
        ),
        BranchOption(
          id: 'lettres',
          nameFr: 'Lettres',
          nameAr: 'الآداب',
          nameEn: 'Letters',
          levelId: '2eme-bac',
        ),
        BranchOption(
          id: 'sciences-humaines',
          nameFr: 'Sciences Humaines',
          nameAr: 'العلوم الإنسانية',
          nameEn: 'Human Sciences',
          levelId: '2eme-bac',
        ),
        BranchOption(
          id: 'sciences-technologies-electriques',
          nameFr: 'Sciences et Technologies Électriques (STE)',
          nameAr: 'العلوم والتكنولوجيات الكهربائية',
          nameEn: 'Electrical Science & Technologies (STE)',
          levelId: '2eme-bac',
        ),
        BranchOption(
          id: 'sciences-technologies-mecaniques',
          nameFr: 'Sciences et Technologies Mécaniques (STM)',
          nameAr: 'العلوم والتكنولوجيات الميكانيكية',
          nameEn: 'Mechanical Science & Technologies (STM)',
          levelId: '2eme-bac',
        ),
      ],
    ),
  ];
}
