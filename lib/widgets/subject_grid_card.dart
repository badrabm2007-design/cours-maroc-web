import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/curriculum_models.dart';
import '../services/app_language_service.dart';
import '../services/user_profile_service.dart';
import '../screens/subject_detail_screen.dart';

class SubjectGridCard extends StatelessWidget {
  final SubjectItem subject;

  const SubjectGridCard({super.key, required this.subject});

  IconData _resolveIcon(String iconCode) {
    switch (iconCode) {
      case 'functions':
        return Icons.functions_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'biotech':
        return Icons.biotech_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'auto_stories':
        return Icons.auto_stories_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'public':
        return Icons.public_rounded;
      case 'mosque':
        return Icons.mosque_rounded;
      case 'terminal':
        return Icons.terminal_rounded;
      case 'computer':
        return Icons.computer_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'account_balance':
        return Icons.account_balance_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'engineering':
        return Icons.precision_manufacturing_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langService = context.watch<AppLanguageService>();
    final currentLang = langService.currentLanguageCode;
    final color = Color(subject.colorHex);

    final isArabic = currentLang == 'ar';
    final primaryTitle = isArabic ? subject.nameAr : subject.meta.localizedName(currentLang);
    final secondaryTitle = isArabic ? subject.nameFr : subject.nameAr;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF192438),
                  Color.alphaBlend(
                    color.withValues(alpha: 0.12),
                    const Color(0xFF101726),
                  ),
                ]
              : [
                  Colors.white,
                  Color.alphaBlend(
                    color.withValues(alpha: 0.05),
                    Colors.white,
                  ),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.30 : 0.20),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.10 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: color.withValues(alpha: 0.15),
          highlightColor: color.withValues(alpha: 0.06),
          onTap: () {
            final lvl = context.read<UserProfileService>().savedLevelId;
            final shortLvl = lvl == '2eme-bac'
                ? '2bac'
                : (lvl == '1ere-bac'
                    ? '1bac'
                    : (lvl == 'tronc-commun' ? 'tc' : '3ac'));
            Navigator.of(context).push(
              MaterialPageRoute(
                settings: RouteSettings(name: '/$shortLvl/${subject.id}'),
                builder: (_) => SubjectDetailScreen(
                  subject: subject,
                  levelId: lvl,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16 : 12,
              vertical: isDesktop ? 13 : 9,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top row: Icon + Count Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: isDesktop ? 46 : 36,
                      height: isDesktop ? 46 : 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(isDesktop ? 13 : 10),
                      ),
                      child: Icon(
                        _resolveIcon(subject.meta.iconCode),
                        color: color,
                        size: isDesktop ? 26 : 20,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 9 : 7,
                        vertical: isDesktop ? 4.5 : 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.20 : 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${subject.totalCount} ${isArabic ? "ملف" : "docs"}',
                        style: TextStyle(
                          fontSize: isDesktop ? 11.5 : 10.0,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 11 : 7),

                // Subject Primary Title
                Text(
                  primaryTitle,
                  style: TextStyle(
                    fontSize: isDesktop ? 17.0 : 14.5,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isDesktop ? 3.5 : 2.5),

                // Secondary Subtitle
                Text(
                  secondaryTitle,
                  style: TextStyle(
                    fontSize: isDesktop ? 12.5 : 11.0,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
