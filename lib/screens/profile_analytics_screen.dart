import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/user_profile_service.dart';
import '../services/curriculum_service.dart';
import '../services/download_service.dart';
import '../services/app_language_service.dart';
import 'level_selection_screen.dart';

class _DayActivity {
  final DateTime date;
  final String label;
  final int count;
  final bool isToday;

  const _DayActivity({
    required this.date,
    required this.label,
    required this.count,
    required this.isToday,
  });
}

class ProfileAnalyticsScreen extends StatelessWidget {
  const ProfileAnalyticsScreen({super.key});

  int _calculateStreak(List<HistoryEntry> history) {
    if (history.isEmpty) return 0;
    final Set<String> activeDates = {};
    for (final h in history) {
      activeDates.add(DateFormat('yyyy-MM-dd').format(h.viewedAt));
    }

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    DateTime checkDate;
    if (activeDates.contains(todayStr)) {
      checkDate = now;
    } else if (activeDates.contains(yesterdayStr)) {
      checkDate = now.subtract(const Duration(days: 1));
    } else {
      return 0;
    }

    int streak = 0;
    while (activeDates.contains(DateFormat('yyyy-MM-dd').format(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<_DayActivity> _getWeeklyActivity(
      List<HistoryEntry> history, bool isArabic) {
    final now = DateTime.now();
    final List<_DayActivity> result = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final count = history
          .where((h) => DateFormat('yyyy-MM-dd').format(h.viewedAt) == dateStr)
          .length;

      final label = i == 0
          ? (isArabic ? 'اليوم' : 'Auj.')
          : _getDayShortName(date.weekday, isArabic);

      result.add(_DayActivity(
        date: date,
        label: label,
        count: count,
        isToday: i == 0,
      ));
    }
    return result;
  }

  String _getDayShortName(int weekday, bool isArabic) {
    if (isArabic) {
      switch (weekday) {
        case DateTime.monday:
          return 'اثن';
        case DateTime.tuesday:
          return 'ثلا';
        case DateTime.wednesday:
          return 'أرب';
        case DateTime.thursday:
          return 'خمي';
        case DateTime.friday:
          return 'جمع';
        case DateTime.saturday:
          return 'سبت';
        case DateTime.sunday:
          return 'أحد';
        default:
          return '';
      }
    } else {
      switch (weekday) {
        case DateTime.monday:
          return 'Lun';
        case DateTime.tuesday:
          return 'Mar';
        case DateTime.wednesday:
          return 'Mer';
        case DateTime.thursday:
          return 'Jeu';
        case DateTime.friday:
          return 'Ven';
        case DateTime.saturday:
          return 'Sam';
        case DateTime.sunday:
          return 'Dim';
        default:
          return '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = context.watch<UserProfileService>();
    final curriculum = context.watch<CurriculumService>();
    final downloadService = context.watch<DownloadService>();
    final langService = context.watch<AppLanguageService>();
    final isArabic = langService.isArabic;
    final currentLang = langService.currentLanguageCode;

    final stats = profile.subjectStats;
    final history = profile.history;
    final streak = _calculateStreak(history);
    final weeklyDays = _getWeeklyActivity(history, isArabic);

    final levelName = curriculum.currentLevel.localizedName(currentLang);
    final branchName = curriculum.currentBranch.localizedName(currentLang);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'فضاء التلميذ والإحصائيات' : 'Espace Élève & Statistiques',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
          // 1. Student Profile Card with Streak
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F5132), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F5132).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 2),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'تلميذ(ة) بالثانوي' : 'Élève Lycéen(ne)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$levelName • $branchName',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Streak Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFBBF24),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          streak > 0
                              ? (isArabic
                                  ? 'سلسلة مراجعة نشطة: $streak يوم متتالي!'
                                  : 'Série active : $streak jour${streak > 1 ? 's' : ''} consécutif${streak > 1 ? 's' : ''} !')
                              : (isArabic
                                  ? 'ابدأ سلسلة مراجعتك اليوم!'
                                  : 'Commencez votre série de révision aujourd\'hui !'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),

                // 3 Core Counters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      isArabic ? 'مراجعات' : 'Consultations',
                      '${profile.totalConsultations}',
                    ),
                    Container(width: 1, height: 28, color: Colors.white24),
                    _buildStatItem(
                      isArabic ? 'بدون إنترنت' : 'Hors-ligne',
                      '${downloadService.allDownloads.length}',
                    ),
                    Container(width: 1, height: 28, color: Colors.white24),
                    _buildStatItem(
                      isArabic ? 'المساحة' : 'Taille',
                      downloadService.formattedTotalSize,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Change Grade Button
          OutlinedButton.icon(
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(
              isArabic
                  ? 'تغيير المستوى الدراسي أو المسلك'
                  : 'Changer de Niveau ou de Filière',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F5132),
              side: const BorderSide(color: Color(0xFF0F5132), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LevelSelectionScreen(isChangingGrade: true),
                ),
              );
            },
          ),

          const SizedBox(height: 22),

          // 2. Weekly Activity Chart (Animated Bar Chart)
          _buildWeeklyChart(
            days: weeklyDays,
            isDark: isDark,
            isArabic: isArabic,
          ),

          const SizedBox(height: 24),

          // 3. Learning Milestones & Badges
          Text(
            isArabic ? 'أهداف وشارات المذاكرة :' : 'Objectifs & Jalons d\'étude :',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 650;
              return GridView.count(
                crossAxisCount: isDesktop ? 4 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isDesktop ? 2.8 : 2.4,
                children: [
                  _buildMilestoneCard(
                    title: isArabic ? 'الخطوة الأولى' : 'Premier Pas',
                    subtitle: isArabic ? 'أول درس تم فتحه' : '1ère consultation',
                    icon: Icons.flag_rounded,
                    isUnlocked: profile.totalConsultations >= 1,
                    isDark: isDark,
                  ),
                  _buildMilestoneCard(
                    title: isArabic ? 'الانضباط' : 'Régularité',
                    subtitle: isArabic ? 'سلسلة 3 أيام أو 10 دروس' : '3j consécutifs ou 10 cours',
                    icon: Icons.local_fire_department_rounded,
                    isUnlocked: streak >= 3 || profile.totalConsultations >= 10,
                    isDark: isDark,
                  ),
                  _buildMilestoneCard(
                    title: isArabic ? 'بطل الأوفلاين' : 'Mode Hors-ligne',
                    subtitle: isArabic ? 'حفظ درس بدون نت' : 'Cours hors-ligne',
                    icon: Icons.download_done_rounded,
                    isUnlocked: downloadService.allDownloads.isNotEmpty,
                    isDark: isDark,
                  ),
                  _buildMilestoneCard(
                    title: isArabic ? 'مستعد للامتحان' : 'Grand Réviseur',
                    subtitle: isArabic ? '25+ درس تمت مراجعته' : '25+ documents étudiés',
                    icon: Icons.military_tech_rounded,
                    isUnlocked: profile.totalConsultations >= 25,
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // 4. Subjects Distribution (Animated Progress Bars)
          Text(
            isArabic ? 'المواد الأكثر مراجعة :' : 'Matières les plus consultées :',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          if (stats.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF162032) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'ستظهر المواد التي راجعتها هنا تلقائياً مع تقدمك في الدروس.'
                          : 'Vos consultations s\'afficheront ici au fur et à mesure de votre apprentissage.',
                      style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )
          else
            ...stats.entries.map((entry) {
              return _buildSubjectProgression(
                subjectName: entry.key,
                count: entry.value,
                total: profile.totalConsultations,
                isDark: isDark,
                isArabic: isArabic,
              );
            }),

          const SizedBox(height: 24),

          // 5. Recent History
          Text(
            isArabic ? 'سجل الدروس المفتوحة مؤخراً :' : 'Historique récent des cours consultés :',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF162032) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                isArabic
                    ? 'لم يتم فتح أي مستند مؤخراً.'
                    : 'Aucun document consulté récemment.',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            )
          else
            ...history.take(15).map((h) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF162032) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    h.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${h.subjectName} • ${DateFormat('dd/MM HH:mm').format(h.viewedAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildWeeklyChart({
    required List<_DayActivity> days,
    required bool isDark,
    required bool isArabic,
  }) {
    final totalWeek = days.fold<int>(0, (sum, d) => sum + d.count);
    final maxInWeek =
        days.map((d) => d.count).fold<int>(0, (m, c) => c > m ? c : m);
    final scaleMax = (maxInWeek < 4 ? 4 : maxInWeek).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F5132).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isArabic ? 'النشاط الأسبوعي' : 'Activité de la semaine',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isArabic ? '$totalWeek هذا الأسبوع' : '$totalWeek cette semaine',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 7 Interactive Animated Bars
          SizedBox(
            height: 115,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final targetFraction = (day.count / scaleMax).clamp(0.0, 1.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Count indicator above bar
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: day.count > 0 ? 1.0 : 0.0,
                      child: Text(
                        '${day.count}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: day.isToday
                              ? const Color(0xFF10B981)
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Bar Track
                    Container(
                      width: 24,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: targetFraction),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutBack,
                        builder: (context, fraction, child) {
                          final barHeight = (fraction * 72)
                              .clamp(day.count > 0 ? 10.0 : 0.0, 72.0);

                          return Container(
                            width: 24,
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: day.isToday
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF0F5132),
                                        Color(0xFF10B981)
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    )
                                  : LinearGradient(
                                      colors: day.count > 0
                                          ? [
                                              const Color(0xFF2563EB),
                                              const Color(0xFF60A5FA)
                                            ]
                                          : [
                                              Colors.transparent,
                                              Colors.transparent
                                            ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: day.isToday && day.count > 0
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Day label
                    Text(
                      day.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            day.isToday ? FontWeight.w800 : FontWeight.w500,
                        color: day.isToday
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUnlocked,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnlocked
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0)),
          width: isUnlocked ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isUnlocked
                  ? const Color(0xFF10B981)
                  : (isDark ? Colors.white38 : Colors.black38),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isUnlocked
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? Colors.white38 : Colors.black38),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isUnlocked
                        ? const Color(0xFF10B981)
                        : (isDark ? Colors.white30 : Colors.black38),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isUnlocked)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 16,
            )
          else
            Icon(
              Icons.lock_outline_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 15,
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgression({
    required String subjectName,
    required int count,
    required int total,
    required bool isDark,
    required bool isArabic,
  }) {
    final pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final pctInt = (pct * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subjectName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F5132).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$pctInt%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F5132),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isArabic
                        ? '$count فتح'
                        : '$count ouverture${count > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: pct),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor:
                      isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF0F5132)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
