import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_language_service.dart';

class OrientationFaqScreen extends StatefulWidget {
  const OrientationFaqScreen({super.key});

  @override
  State<OrientationFaqScreen> createState() => _OrientationFaqScreenState();
}

class _OrientationFaqScreenState extends State<OrientationFaqScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _faqs = [
    {
      'question_fr': 'Comment est calculée la note de présélection CursusSup ?',
      'question_ar': 'كيف يتم احتساب معدل الانتقاء الأولي على منصة CursusSup ؟',
      'reponse_fr':
          'La note de présélection officielle repose sur la formule ministérielle unifiée : 75% pour l\'Examen National du Baccalauréat et 25% pour l\'Examen Régional. Les notes du contrôle continu ne sont pas prises en compte pour les grandes écoles régulées (ENSA, ENCG, FMP, etc.).',
      'reponse_ar':
          'يتم احتساب معدل الانتقاء الأولي وفق الصيغة الوزارية الرسمية الموحدة : 75% لنقطة الامتحان الوطني للبكالوريا و 25% لنقطة الامتحان الجهوي. ولا تحتسب نقط المراقبة المستمرة في انتقاء المدارس العليا المنظمة (ENSA، ENCG، كليات الطب...).',
      'tag': 'CursusSup & Seuils',
    },
    {
      'question_fr': 'Peut-on postuler à la fois aux FMP, ENSA, ENCG, ENSAM et CPGE ?',
      'question_ar': 'هل يمكن الترشح لعدة مدارس في نفس الوقت (الطب، ENSA، ENCG، الأقسام التحضيرية) ؟',
      'reponse_fr':
          'Oui, absolument. Les candidatures aux différents réseaux d\'écoles sont indépendantes. Vous pouvez postuler à toutes les écoles ouvertes à votre filière de Baccalauréat sans aucune pénalité de priorité.',
      'reponse_ar':
          'نعم بالتأكيد. الترشيحات لمختلف شبكات المدارس مستقلة تماماً. يمكنك الترشح لجميع المدارس المتاحة لشعبتك في البكالوريا دون أي تعارض في الأولويات.',
      'tag': 'Candidatures',
    },
    {
      'question_fr': 'Comment fonctionnent les listes d\'attente et la cascade de désistements ?',
      'question_ar': 'كيف تعمل لوائح الانتظار وتوالي التعويضات ؟',
      'reponse_fr':
          'Les admissions se font par vagues successives. Dès qu\'un candidat admis choisit une autre école (ex: FMP plutôt qu\'ENSA), sa place se libère automatiquement pour le premier de la liste d\'attente. Il est impératif de confirmer votre maintien de candidature sur la plateforme à chaque phase.',
      'reponse_ar':
          'يتم القبول عبر مراحل متتالية. بمجرد أن يختار تلميذ مقبول مدرسة أخرى، يُمنح مقعده فوراً للمترشح التالي في لائحة الانتظار. من الضروري جداً تأكيد الرغبة في التباري والبقاء في لوائح الانتظار في كل مرحلة على المنصة.',
      'tag': 'Listes d\'attente',
    },
    {
      'question_fr': 'Quelles sont les épreuves du concours unifié de Médecine et Pharmacie (FMP/FMD) ?',
      'question_ar': 'ما هي مكونات المباراة المشتركة لكليات الطب والصيدلة وطب الأسنان ؟',
      'reponse_fr':
          'Le concours comporte 4 épreuves écrites sous forme de QCM (45 minutes par composante) : SVT/Biologie, Sciences Physiques, Chimie et Mathématiques, avec un seuil national d\'admissibilité fixé au préalable.',
      'reponse_ar':
          'تتضمن المباراة 4 اختبارات كتابية على شكل أسئلة متعددة الاختيارات QCM (مدة كل اختبار 45 دقيقة) : علوم الحياة والأرض، الفيزياء، الكيمياء، والرياضيات، وفق عتبة وطنية موحدة.',
      'tag': 'Médecine & Santé',
    },
    {
      'question_fr': 'Qu\'est-ce que le test TAFEM pour l\'accès aux ENCG ?',
      'question_ar': 'ما هو اختبار TAFEM لولوج المدارس الوطنية للتجارة والتسيير (ENCG) ؟',
      'reponse_fr':
          'Le TAFEM (Test d\'Aptitude à la Formation En Management) est une épreuve écrite de 4 sous-tests : Mémorisation et compréhension, Raisonnement mathématique, Culture générale et Anglais. Attention : le barème comporte des points négatifs (-1 par mauvaise réponse, +3 par bonne réponse).',
      'reponse_ar':
          'اختبار TAFEM هو رائز انتقاء كتابي يتكون من 4 أجزاء : مهارات الاستيعاب واللغة، الاستدلال المنطقي والرياضيات، الثقافة العامة واللغة الإنجليزية. تنبيه : التصحيح يعتمد نظام الجزاءات (-1 لكل جواب خاطئ، و +3 لكل جواب صحيح).',
      'tag': 'Commerce',
    },
    {
      'question_fr': 'Quelle est la valeur du DUT (EST) et quelles sont les passerelles ingénieurs ?',
      'question_ar': 'ما هي آفاق الدبلوم الجامعي للتكنولوجيا (EST / DUT) وإمكانية ولوج مدارس المهندسين ؟',
      'reponse_fr':
          'Le DUT en 2 ans offre un excellent tremplin professionnel et académique. Les étudiants classés parmi les majors de promotion peuvent intégrer en passerelle directe les écoles d\'ingénieurs (ENSA, FST, EMI, ENSEM) ou des licences professionnelles et masters.',
      'reponse_ar':
          'دبلوم DUT يفتح آفاقاً واعدة سواء للاندماج المهني المباشر أو استكمال الدراسة. المتفوقون في الدفعة يمكنهم اجتياز جسور الولوج المباشر للسنة الثالثة بمدارس المهندسين (ENSA، FST، EMI...) أو إجازات التميز والماستر.',
      'tag': 'Technologique',
    },
    {
      'question_fr': 'Comment postuler à la bourse d\'études Minhaty ?',
      'question_ar': 'كيف يتم الترشيح لمنحة التعليم العالي (منحتي) ؟',
      'reponse_fr':
          'Le dépôt de candidature s\'effectue exclusivement en ligne sur le portail minhaty.ma avant la proclamation des résultats du Bac. L\'attribution est liée au Registre Social Unifié (RSU) et à la situation socio-économique du foyer.',
      'reponse_ar':
          'يتم إيداع طلب الاستفادة من المنحة الجامعية حصرياً عبر البوابة الرقمية minhaty.ma قبل إعلان نتائج البكالوريا، ويتم البت في الاستحقاق بالاعتماد على مؤشر السجل الاجتماعي الموحد (RSU).',
      'tag': 'Bourses',
    },
    {
      'question_fr': 'Que faire si mes notes sont inférieures aux seuils des grandes écoles ?',
      'question_ar': 'ما هي البدائل إذا كانت النقط أقل من عتبات المدارس الكبرى ؟',
      'reponse_fr':
          'Les universités publiques à accès ouvert (Facultés des Sciences FS, FSJES, FLSH) vous accueillent sans sélection préalable selon la sectorisation de votre province. Vous pouvez y réaliser un parcours d\'excellence et intégrer les grandes écoles via les passerelles après la 2ème ou 3ème année.',
      'reponse_ar':
          'الكليات ذات الاستقطاب المفتوح (كليات العلوم، الحقوق والاقتصاد، الآداب) تستقبلكم بدون انتقاء مسبق حسب رافد إقليمكم. يمكنكم التفوق فيها واجتياز مباريات الجسور والماستر لولوج مدارس المهندسين والتجارة لاحقاً.',
      'tag': 'Orientation',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langService = context.watch<AppLanguageService>();
    final isAr = langService.isArabic;

    final filtered = _faqs.where((f) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final qFr = (f['question_fr'] as String).toLowerCase();
      final qAr = (f['question_ar'] as String).toLowerCase();
      final rFr = (f['reponse_fr'] as String).toLowerCase();
      final rAr = (f['reponse_ar'] as String).toLowerCase();
      return qFr.contains(q) || qAr.contains(q) || rFr.contains(q) || rAr.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Text(
          isAr ? 'الأسئلة الشائعة والأجوبة (FAQ)' : 'Questions & Réponses (FAQ)',
          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFF0F5132), const Color(0xFF15803D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F5132).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'إجابات رسمية ومبسطة لأبرز التساؤلات' : 'Toutes les réponses à vos questions d\'orientation',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isAr
                                ? 'دليل شامل يجيب على استفسارات تلاميذ البكالوريا وأولياء الأمور'
                                : 'Guide interactif conçu pour éclairer les lycéens et les familles marocaines.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Search Filter
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: isAr ? 'ابحث في الأسئلة الشائعة...' : 'Rechercher une question ou un thème...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),

              const SizedBox(height: 14),

              Text(
                isAr ? 'الأسئلة المتكررة (${filtered.length})' : 'Questions fréquentes (${filtered.length})',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      isAr ? 'لا توجد نتائج مطابقة لبحثك' : 'Aucune question ne correspond à votre recherche.',
                      style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                    ),
                  ),
                )
              else
                ...filtered.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F5132).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.help_outline_rounded, color: Color(0xFF0F5132), size: 18),
                        ),
                        title: Text(
                          isAr ? item['question_ar'] : item['question_fr'],
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item['tag'],
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF0F5132),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              isAr ? item['reponse_ar'] : item['reponse_fr'],
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
