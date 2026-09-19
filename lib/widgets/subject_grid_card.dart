import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/curriculum_models.dart';
import '../services/app_language_service.dart';
import '../services/user_profile_service.dart';
import '../screens/subject_detail_screen.dart';

class SubjectGridCard extends StatefulWidget {
  final SubjectItem subject;

  const SubjectGridCard({super.key, required this.subject});

  @override
  State<SubjectGridCard> createState() => _SubjectGridCardState();
}

class _SubjectGridCardState extends State<SubjectGridCard> {
  bool _isHovered = false;

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
    final color = Color(widget.subject.colorHex);

    final isArabic = currentLang == 'ar';
    final primaryTitle = isArabic
        ? widget.subject.nameAr
        : widget.subject.meta.localizedName(currentLang);
    final secondaryTitle =
        isArabic ? widget.subject.nameFr : widget.subject.nameAr;

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.025 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      _isHovered ? const Color(0xFF1E2D47) : const Color(0xFF192438),
                      Color.alphaBlend(
                        color.withValues(alpha: _isHovered ? 0.22 : 0.12),
                        const Color(0xFF101726),
                      ),
                    ]
                  : [
                      Colors.white,
                      Color.alphaBlend(
                        color.withValues(alpha: _isHovered ? 0.12 : 0.05),
                        Colors.white,
                      ),
                    ],
            ),
            borderRadius: BorderRadius.circular(isDesktop ? 15 : 18),
            border: Border.all(
              color: _isHovered
                  ? color
                  : color.withValues(alpha: isDark ? 0.35 : 0.22),
              width: _isHovered ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: _isHovered ? (isDark ? 0.35 : 0.18) : (isDark ? 0.12 : 0.05)),
                blurRadius: _isHovered ? 16 : 9,
                offset: _isHovered ? const Offset(0, 5) : const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(isDesktop ? 15 : 18),
              splashColor: color.withValues(alpha: 0.18),
              highlightColor: color.withValues(alpha: 0.08),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SubjectDetailScreen(
                      subject: widget.subject,
                      levelId: context.read<UserProfileService>().savedLevelId,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 18,
                  vertical: isDesktop ? 13 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top row: Icon + Count Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: isDesktop ? 42 : 48,
                          height: isDesktop ? 42 : 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isDark ? 0.28 : 0.14),
                            borderRadius: BorderRadius.circular(isDesktop ? 12 : 14),
                            boxShadow: _isHovered
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _resolveIcon(widget.subject.meta.iconCode),
                            color: color,
                            size: isDesktop ? 22 : 26,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 9 : 10,
                            vertical: isDesktop ? 4 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isDark ? 0.22 : 0.10),
                            borderRadius: BorderRadius.circular(isDesktop ? 9 : 10),
                            border: Border.all(
                              color: color.withValues(alpha: _isHovered ? 0.5 : 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${widget.subject.totalCount} ${isArabic ? "ملف" : "docs"}',
                            style: TextStyle(
                              fontSize: isDesktop ? 12.0 : 12.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Titles
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          primaryTitle,
                          style: TextStyle(
                            fontSize: isDesktop ? 16.5 : 17.5,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isDesktop ? 3 : 4),
                        Text(
                          secondaryTitle,
                          style: TextStyle(
                            fontSize: isDesktop ? 12.8 : 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
}
