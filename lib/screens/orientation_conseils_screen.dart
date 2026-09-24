import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_language_service.dart';

class OrientationConseilsScreen extends StatefulWidget {
  const OrientationConseilsScreen({super.key});

  @override
  State<OrientationConseilsScreen> createState() =>
      _OrientationConseilsScreenState();
}

class _OrientationConseilsScreenState extends State<OrientationConseilsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _conseilsSections = [
    {
      'id': 'listes_attente',
      'icon': Icons.hourglass_top_rounded,
      'color': const Color(0xFFF59E0B),
      'titre_fr': 'Gestion des Listes d\'Attente',
      'titre_ar': 'تدبير لوائح الانتظار وتوالي التعويضات',
      'description_fr':
          'Comment fonctionnent les désistements et maximiser ses chances d\'admission.',
      'description_ar':
          'فهم آلية التنازلات واستراتيجيات الصعود في لوائح الانتظار حتى آخر مرحلة.',
      'articles': [
        {
          'titre_fr': '1. L\'Effet Domino des Désistements',
          'titre_ar': '1. ظاهرة التنازلات المتسلسلة (توالي المقاعد)',
          'contenu_fr':
              'Chaque année, les élèves les mieux classés sont acceptés simultanément dans plusieurs réseaux (Médecine, ENSA, ENSAM, CPGE, etc.). Dès que les résultats définitifs de Médecine ou des CPGE tombent, des centaines de places se libèrent instantanément dans les écoles d\'ingénieurs et de commerce. Il est donc crucial de ne jamais paniquer si vous êtes sur liste d\'attente.',
          'contenu_ar':
              'في كل سنة، يتم قبول المتفوقين في عدة مباريات في آن واحد (الطب، الأقسام التحضيرية، المدارس الوطنية...). وبمجرد إعلان لوائح الطب والأقسام التحضيرية وتأكيد تسجيلهم، تتحرر مئات المقاعد في ENSA و ENSAM و ENCG. لذلك يجب عدم فقدان الأمل أبداً عند التواجد في لائحة الانتظار.',
        },
        {
          'titre_fr': '2. Règle d\'or : Confirmer systématiquement son maintien',
          'titre_ar': '2. القاعدة الذهبية : تأكيد الرغبة في التباري والبقاء',
          'contenu_fr':
              'Sur CursusSup et les plateformes propres aux écoles, la non-confirmation de maintien dans les délais impartis (souvent 24 à 48 heures) équivaut à un abandon pur et simple ! Connectez-vous tous les jours durant la période de juillet à septembre.',
          'contenu_ar':
              'على منصة CursusSup والمنصات الجامعية، عدم الضغط على زر تأكيد الرغبة في التباري خلال الآجال المحددة (غالباً ما بين 24 إلى 48 ساعة) يعتبر تنازلاً نهائياً ويسقط حقك تلقائياً ! احرص على تتبع حسابك يومياً من يوليوز إلى شتنبر.',
        },
        {
          'titre_fr': '3. Présence physique lors des appels de liste',
          'titre_ar': '3. الحضور الفعلي لجلسات المناداة الحضورية',
          'contenu_fr':
              'Certaines écoles organisent des séances d\'appel public physique par ordre de mérite pour combler les dernières places vacantes en septembre. Un candidat absent, même classé 1er de la liste, perd immédiatement son droit au profit du candidat présent dans l\'amphithéâtre.',
          'contenu_ar':
              'تنظم بعض المؤسسات جلسات مناداة حضورية في المدرج حسب ترتيب الاستحقاق في شتنبر لملء المقاعد المتبقية. أي مترشح يتغيب وقت النداء على اسمه يُقصى فوراً ويُمنح المقعد للمترشح الحاضر الموالي في الترتيب.',
        },
        {
          'titre_fr': '4. L\'attestation provisoire et le dépôt du Bac',
          'titre_ar': '4. شهادة البكالوريا الأصلية وإجراءات الإيداع',
          'contenu_fr':
              'Si vous êtes admis dans votre 2ème choix et en attente sur votre 1er choix : déposez votre Bac dans le 2ème choix pour sécuriser votre admission. Vous avez légalement le droit de retirer votre dossier si votre 1er choix vous appelle ultérieurement.',
          'contenu_ar':
              'إذا تم قبولك في اختيارك الثاني وما زلت في لائحة انتظار اختيارك الأول : ضع شهادة البكالوريا في الاختيار الثاني لضمان مقعدك. يحق لك قانونياً سحب ملفك فور المناداة عليك رسمياً في اختيارك الأول.',
        },
      ],
    },
    {
      'id': 'concours_ecrits',
      'icon': Icons.edit_note_rounded,
      'color': const Color(0xFF2563EB),
      'titre_fr': 'Préparation aux Concours Écrits (QCM)',
      'titre_ar': 'الاستعداد للمباريات الكتابية والرائز (QCM)',
      'description_fr':
          'Méthodologie de travail, gestion du temps et pièges du barème négatif.',
      'description_ar':
          'منهجية المراجعة، إدارة الوقت الذكية وتجنب فخاخ نظام التنقيط السلبي.',
      'articles': [
        {
          'titre_fr': '1. La stratégie du barème négatif (TAFEM / Écoles)',
          'titre_ar': '1. استراتيجية التنقيط السلبي والجزاءات (TAFEM)',
          'contenu_fr':
              'Dans les concours comme le TAFEM (ENCG) où une mauvaise réponse entraîne une pénalité (-1 pt) alors qu\'une bonne donne (+3 pts) et une omission (0 pt) : ne répondez JAMAIS au hasard ! Si vous hésitez entre 3 choix inconnus, abstenez-vous. Ne tentez le choix que si vous avez éliminé de façon sûre au moins la moitié des propositions incorrectes.',
          'contenu_ar':
              'في مباريات مثل TAFEM (ENCG) حيث يؤدي الجواب الخاطئ إلى خصم نقطة (-1) والجواب الصحيح يمنح (+3) وترك السؤال فارغاً (0) : إياك والتخمين العشوائي ! إذا كنت لا تعرف الجواب فالأفضل عدم الإجابة. لا تجازف إلا بعد استبعاد خيارين خاطئين على الأقل بيقين.',
        },
        {
          'titre_fr': '2. Gestion du temps : La méthode des 3 passages',
          'titre_ar': '2. إدارة الوقت : استراتيجية الدورات الثلاث',
          'contenu_fr':
              'Pour une épreuve de 45 minutes : \n• 1er passage (15 min) : Traitez exclusivement les questions évidentes, directes et sans calculs longs.\n• 2ème passage (20 min) : Résolvez les questions nécessitant un raisonnement méthodique ou des calculs modérés.\n• 3ème passage (10 min) : Vérifiez le report sur la grille optique et relisez attentivement vos réponses sans toucher aux questions incertaines.',
          'contenu_ar':
              'خلال اختبار مدته 45 دقيقة مثلاً : \n• الدورة الأولى (15 دقيقة) : الإجابة فقط عن الأسئلة الواضحة والمباشرة بدون حسابات معقدة.\n• الدورة الثانية (20 دقيقة) : حل المسائل التي تتطلب برهنة أو حسابات متوسطة.\n• الدورة الثالثة (10 دقائق) : التحقق من النقل الدقيق لورقة التصحيح الآلي ومراجعة الإجابات دون التخمين العشوائي.',
        },
        {
          'titre_fr': '3. Concours de Médecine (FMP/FMD) : L\'automatisation',
          'titre_ar': '3. مباراة كليات الطب والصيدلة : السرعة والتحليل',
          'contenu_fr':
              'Le concours commun de médecine comporte 4 épreuves courtes (Maths, Physique, Chimie, SVT). Les calculatrices y sont rigoureusement interdites. Entraînez-vous au calcul mental rapide, aux ordres de grandeur et à l\'analyse rapide des graphes et schémas expérimentaux.',
          'contenu_ar':
              'تضم المباراة المشتركة 4 اختبارات سريعة (رياضيات، فيزياء، كيمياء، علوم الحياة والأرض). الآلة الحاسبة ممنوعة تماماً. تدرب يومياً على الحساب الذهني التقديري السريع وتحليل المبيانات والرسوم التخطيطية البيولوجية.',
        },
        {
          'titre_fr': '4. Entraînement sur annales réelles (2020-2025)',
          'titre_ar': '4. التدريب على نماذج السنوات السابقة بالشروط الحقيقية',
          'contenu_fr':
              'Ne vous contentez pas de lire les corrigés. Imprimez les sujets officiels des 5 dernières années, lancez un chronomètre dans une pièce silencieuse, et remplissez une feuille optique dans les conditions réelles du concours.',
          'contenu_ar':
              'لا تكتفِ بقراءة الحلول الجاهزة. قم بطباعة نماذج المباريات للسنوات الخمس الأخيرة، واضبط المؤقت الزمني في غرفة هادئة، وقم بتسويد ورقة الإجابة في نفس الشروط والمدة الزمنية للمباراة.',
        },
      ],
    },
    {
      'id': 'entretiens_oraux',
      'icon': Icons.record_voice_over_rounded,
      'color': const Color(0xFF10B981),
      'titre_fr': 'Réussir les Entretiens Oraux & Pitch',
      'titre_ar': 'التفوق في المقابلات الشفوية وعرض الدقيقتين',
      'description_fr':
          'Présentation personnelle, posture professionnelle et réponses aux questions pièges.',
      'description_ar':
          'تقديم الذات الاحترافي، لغة الجسد الذكية وتجاوز الأسئلة المحرجة بثقة.',
      'articles': [
        {
          'titre_fr': '1. Le Pitch de 2 minutes : La structure infaillible',
          'titre_ar': '1. عرض الدقيقتين للتعريف بالنفس : الهيكلة الناجحة',
          'contenu_fr':
              'Structurez votre présentation en 4 points chronologiques clairs :\n1. Identité & Baccalauréat (Option, mention, vos matières fortes).\n2. Expériences & Centres d\'intérêt (Clubs scolaires, projets scientifiques, sports ou bénévolat démontrant l\'esprit d\'équipe).\n3. Pourquoi ce métier/domaine (Le déclic et votre vision d\'avenir).\n4. Pourquoi cette école précisément (Sa renommée, ses filières, sa vie associative).',
          'contenu_ar':
              'نظم عرضك في 4 نقاط زمنية واضحة :\n1. الهوية وشعبة البكالوريا (الميزة، والمواد التي تبرع فيها).\n2. الأنشطة والمشاريع الشخصية (أندية، نوادي الروبوتات، تطوع، أنشطة رياضية تعكس روح الفريق).\n3. لماذا اخترت هذا التخصص والمهنة (الدوافع والرؤية المستقبلية).\n4. لماذا هذه المدرسة بالذات (سمعتها، برامجها وآفاقها).',
        },
        {
          'titre_fr': '2. Réponses aux questions pièges classiques',
          'titre_ar': '2. التعامل الذكي مع الأسئلة الفخاخ الكلاسيكية',
          'contenu_fr':
              '• "Citez-nous un de vos défauts" : Choisissez un trait d\'amélioration réaliste accompagné de votre solution active (ex: "J\'avais du mal à déléguer, mais j\'ai appris à faire confiance grâce aux travaux de groupe").\n• "Et si vous n\'êtes pas admis ?" : Montrez votre détermination sereine ("Je rejoindrai une filière universitaire d\'excellence (FST/EST) pour tenter les passerelles l\'année suivante").',
          'contenu_ar':
              '• "اذكر لنا نقطة ضعف في شخصيتك" : اختر نقطة واقعية مع إبراز الحل الذي تعمل عليه (مثلاً: "كنت أتردد في تفويض المهام للآخرين، لكنني تعلمت العمل الجماعي والتشارك في مشاريع القسم").\n• "ماذا ستفعل إذا لم يتم قبولك اليوم ؟" : أظهر إصراراً إيجابياً واحترافياً ("سألتحق بمسلك جامعي متميز كـ FST أو EST لأعيد التباري عبر الجسور الوطنية بنجاح").',
        },
        {
          'titre_fr': '3. Communication non-verbale et posture',
          'titre_ar': '3. لغة الجسد والهندام اللائق',
          'contenu_fr':
              'Soignez votre tenue (élégante, sobre et professionnelle). Maintenez un contact visuel alterné avec tous les membres du jury, adoptez une posture droite et ouverte, et respirez calmement avant de répondre. Prendre 3 secondes de réflexion valorise votre maturité.',
          'contenu_ar':
              'احرص على هندام أنيق ومحترم. حافظ على تواصل بصري هادئ مع جميع أعضاء اللجنة، واجلس باستقامة وانفتاح، وخذ نفساً عميقاً قبل البدء. التفكير لمدة ثانيتين إلى ثلاث ثوانٍ قبل الإجابة دليل نضج واتزان.',
        },
      ],
    },
    {
      'id': 'dossier_bourse',
      'icon': Icons.folder_shared_rounded,
      'color': const Color(0xFF8B5CF6),
      'titre_fr': 'Inscriptions, Bourse Minhaty & Logement',
      'titre_ar': 'إجراءات التسجيل، منحة Minhaty والسكن',
      'description_fr':
          'Documents à préparer, calendrier des bourses et cités universitaires.',
      'description_ar':
          'الوثائق الإدارية الضرورية، مواعيد المنحة الجامعية والأحياء الجامعية.',
      'articles': [
        {
          'titre_fr': '1. Le dossier d\'inscription type à anticiper',
          'titre_ar': '1. الملف الإداري النموذجي الواجب تحضيره مسبقاً',
          'contenu_fr':
              'Préparez dès juin plusieurs copies certifiées conformes :\n• Diplôme original du Baccalauréat + plusieurs copies légalisées.\n• Relevés de notes officiels du Bac (Régional & National).\n• Copies de la Carte d\'Identité Nationale (CNIE).\n• Photos d\'identité récentes (format passeport sur fond clair).\n• Certificat médical d\'aptitude physique.\n• Extraits d\'acte de naissance récents.',
          'contenu_ar':
              'قم بتحضير نسخ مسبقة ومصادق عليها منذ شهر يونيو :\n• شهادة البكالوريا الأصلية + عدة نسخ مصادق عليها.\n• بيان النقط الرسمي للامتحانين الوطني والجهوي.\n• نسخ من بطاقة التعريف الوطنية الإلكترونية.\n• صور شمسية حديثة بخلفية فاتحة.\n• شهادة طبية تثبت القدرة البدنية.\n• عقود ازدياد حديثة العهد.',
        },
        {
          'titre_fr': '2. Bourse d\'études Minhaty (منحتي)',
          'titre_ar': '2. طلب المنحة الجامعية عبر بوابة منحتي (Minhaty.ma)',
          'contenu_fr':
              'La demande de bourse s\'effectue exclusivement en ligne sur minhaty.ma entre mai et juin avant même l\'obtention du Bac ! L\'attribution repose désormais sur le Registre Social Unifié (RSU) et le Registre National de la Population (RNP). Assurez-vous que le foyer familial y est inscrit.',
          'contenu_ar':
              'يتم طلب المنحة حصرياً عبر البوابة الوطنية minhaty.ma ما بين ماي ويونيو قبل نيل البكالوريا ! ويعتمد الاستحقاق على مؤشر السجل الاجتماعي الموحد (RSU) والسجل الوطني للسكان (RNP). احرص على تسجيل الأسرة فيهما مسبقاً.',
        },
        {
          'titre_fr': '3. Cités et résidences universitaires (ONOUSC)',
          'titre_ar': '3. السكن بالأحياء الجامعية التابعة لـ ONOUSC',
          'contenu_fr':
              'Les candidatures pour les cités universitaires publiques s\'ouvrent sur logement.onousc.ma généralement dès la fin août. Les critères tiennent compte du revenu des parents et de l\'éloignement géographique par rapport à l\'établissement d\'accueil.',
          'contenu_ar':
              'يفتح باب الترشيح للأحياء الجامعية العمومية عبر منصة logement.onousc.ma في أواخر غشت. وتعتمد المعايير على دخل الوالدين والبعد الجغرافي عن مقر المؤسسة الجامعية.',
        },
      ],
    },
    {
      'id': 'passerelles_reussite',
      'icon': Icons.alt_route_rounded,
      'color': const Color(0xFF0D9488),
      'titre_fr': 'Passerelles & Plans B d\'Excellence',
      'titre_ar': 'الجسور والمسارات البديلة نحو كبرى المدارس',
      'description_fr':
          'Comment intégrer une grande école en Bac+2 ou Bac+3 via EST, FST ou Licence.',
      'description_ar':
          'كيف تلج مدرسة مهندسين أو تجارة عليا بعد سنتين عبر EST أو FST أو الإجازة.',
      'articles': [
        {
          'titre_fr': '1. Le mythe du concours unique post-bac',
          'titre_ar': '1. كبرى المدارس تفتح أبوابها سنوياً لـ Bac+2 و Bac+3',
          'contenu_fr':
              'Ne pas réussir un concours directement après le Baccalauréat n\'est en aucun cas un frein. Plus de 30% des ingénieurs et managers diplômés de l\'EMI, l\'EHTP, l\'INSEA, l\'ENSA, l\'ENSAM ou l\'ISCAE intègrent ces écoles via les concours parallèles réservés aux titulaires de DUT (EST), DEUST (FST) ou Licence (FS/FSJES).',
          'contenu_ar':
              'عدم اجتياز مباراة معينة مباشرة بعد الباكالوريا ليس عائقاً أبداً. أكثر من 30% من خريجي كبريات المدارس (EMI, EHTP, INSEA, ENSA, ENSAM, ISCAE) يلتحقون بهذه المدارس عبر مباريات الجسور الموازية لحملة DUT أو DEUST أو الإجازة الجامعية.',
        },
        {
          'titre_fr': '2. Pourquoi choisir les EST et FST ?',
          'titre_ar': '2. ميزات المدارس العليا للتكنولوجيا (EST) وكليات العلوم والتقنيات (FST)',
          'contenu_fr':
              'Les EST offrent un cursus professionnalisant très encadré en 2 ans (DUT). Les FST offrent une rigueur scientifique remarquable avec un système modulaire adapté aux concours nationaux d\'ingénieurs (CNC pour FST ou concours internes). Major de promotion dans une EST ou FST garantit de très nombreuses opportunités.',
          'contenu_ar':
              'توفر مدارس EST تكويناً تطبيقياً وتأطيراً ممتازاً خلال سنتين (DUT). بينما توفر كليات FST تكويناً علمياً رصيناً ونظاماً نموذجياً يسهل اجتياز مباريات المدارس العليا للمهندسين. التميز ضمن المراتب الأولى في EST أو FST يفتح أبواباً واسعة جداً.',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _conseilsSections.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguageService>(context);
    final isAr = lang.isArabic;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0.5,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: Color(0xFF0D9488),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr
                          ? 'الدليل الاستراتيجي والنصائح'
                          : 'Guide Stratégique & Conseils',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isAr
                          ? 'التحضير للمباريات، المقابلات ولوائح الانتظار'
                          : 'Concours, entretiens & listes d\'attente',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xFF0D9488),
                indicatorWeight: 3,
                labelColor: const Color(0xFF0D9488),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: _conseilsSections.map((section) {
                  final title = isAr ? section['titre_ar'] : section['titre_fr'];
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(section['icon'] as IconData, size: 16),
                        const SizedBox(width: 6),
                        Text(title),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Barre de recherche
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'ابحث في النصائح والإرشادات...'
                      : 'Rechercher un conseil, concours ou astuce...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            // Contenu onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _conseilsSections.map((section) {
                  return _buildSectionView(section, isAr, isDesktop);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionView(
      Map<String, dynamic> section, bool isAr, bool isDesktop) {
    final articles = (section['articles'] as List<dynamic>).where((art) {
      if (_searchQuery.isEmpty) return true;
      final tFr = (art['titre_fr'] ?? '').toLowerCase();
      final tAr = (art['titre_ar'] ?? '').toLowerCase();
      final cFr = (art['contenu_fr'] ?? '').toLowerCase();
      final cAr = (art['contenu_ar'] ?? '').toLowerCase();
      return tFr.contains(_searchQuery) ||
          tAr.contains(_searchQuery) ||
          cFr.contains(_searchQuery) ||
          cAr.contains(_searchQuery);
    }).toList();

    if (articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                isAr
                    ? 'لا توجد نتائج مطابقة لبحثك'
                    : 'Aucun conseil ne correspond à votre recherche',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16,
        vertical: 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card du thème
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (section['color'] as Color).withValues(alpha: 0.12),
                      (section['color'] as Color).withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (section['color'] as Color).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: section['color'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        section['icon'] as IconData,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? section['titre_ar'] : section['titre_fr'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: section['color'] as Color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAr
                                ? section['description_ar']
                                : section['description_fr'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Liste des articles / astuces
              ...articles.map((art) {
                return _buildArticleCard(art, section['color'] as Color, isAr);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard(
      Map<String, dynamic> art, Color accentColor, bool isAr) {
    final title = isAr ? art['titre_ar'] : art['titre_fr'];
    final content = isAr ? art['contenu_ar'] : art['contenu_fr'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: accentColor,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEF2F6)),
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
