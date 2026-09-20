import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/curriculum_models.dart';
import '../services/app_language_service.dart';
import '../services/user_profile_service.dart';
import 'branch_selection_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final bool isChangingGrade;

  const LevelSelectionScreen({super.key, this.isChangingGrade = false});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  String _selectedLevelId = '2eme-bac';

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileService>();
    if (profile.hasSelectedGrade) {
      _selectedLevelId = profile.savedLevelId;
    }
  }

  void _navigateToBranch(LevelOption lvl) {
    setState(() {
      _selectedLevelId = lvl.id;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BranchSelectionScreen(
          level: lvl,
          isChangingGrade: widget.isChangingGrade,
        ),
      ),
    );
  }

  IconData _getLevelIcon(String id) {
    switch (id) {
      case '3eme-annee-college':
        return Icons.auto_stories_rounded;
      case 'tronc-commun':
        return Icons.foundation_rounded;
      case '1ere-bac':
        return Icons.looks_one_rounded;
      case '2eme-bac':
        return Icons.looks_two_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langService = context.watch<AppLanguageService>();
    final currentLang = langService.currentLanguageCode;
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      appBar: widget.isChangingGrade
          ? AppBar(
              title: Text(
                langService.tr('change_grade_title'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 18 : 12,
            vertical: isDesktop ? 20 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isChangingGrade) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: isDesktop ? 78 : 70,
                    height: isDesktop ? 78 : 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F5132).withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    langService.tr('app_title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isDesktop ? 25 : 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    langService.tr('app_subtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isDesktop ? 14.5 : 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F5132),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            langService.tr('app_disclaimer_badge'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isDesktop ? 12 : 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    langService.tr('level_selection_desc'),
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 13,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Title: Choix du Niveau
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  langService.tr('level_selection_title'),
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Responsive: 2 items per line on Desktop, 1 on Mobile
              Expanded(
                child: isDesktop
                    ? GridView.builder(
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        itemCount: LevelOption.allLevels.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          mainAxisExtent: 112,
                        ),
                        itemBuilder: (context, index) {
                          final lvl = LevelOption.allLevels[index];
                          final isSelected = lvl.id == _selectedLevelId;
                          return _LevelCardItem(
                            level: lvl,
                            isSelected: isSelected,
                            isDark: isDark,
                            currentLang: currentLang,
                            icon: _getLevelIcon(lvl.id),
                            onTap: () => _navigateToBranch(lvl),
                          );
                        },
                      )
                    : ListView.builder(
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        itemCount: LevelOption.allLevels.length,
                        itemBuilder: (context, index) {
                          final lvl = LevelOption.allLevels[index];
                          final isSelected = lvl.id == _selectedLevelId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LevelCardItem(
                              level: lvl,
                              isSelected: isSelected,
                              isDark: isDark,
                              currentLang: currentLang,
                              icon: _getLevelIcon(lvl.id),
                              onTap: () => _navigateToBranch(lvl),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCardItem extends StatefulWidget {
  final LevelOption level;
  final bool isSelected;
  final bool isDark;
  final String currentLang;
  final IconData icon;
  final VoidCallback onTap;

  const _LevelCardItem({
    required this.level,
    required this.isSelected,
    required this.isDark,
    required this.currentLang,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_LevelCardItem> createState() => _LevelCardItemState();
}

class _LevelCardItemState extends State<_LevelCardItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.018 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF0F5132).withValues(alpha: widget.isDark ? 0.28 : 0.09)
                : (_isHovered
                    ? const Color(0xFF0F5132).withValues(alpha: widget.isDark ? 0.16 : 0.05)
                    : (widget.isDark ? const Color(0xFF162032) : Colors.white)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? const Color(0xFF0F5132)
                  : (widget.isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0)),
              width: active ? 2.2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? const Color(0xFF0F5132).withValues(alpha: widget.isDark ? 0.3 : 0.12)
                    : Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.03),
                blurRadius: active ? 16 : 8,
                offset: active ? const Offset(0, 6) : const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF0F5132)
                            : (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F5132).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        widget.icon,
                        color: active ? Colors.white : Colors.grey.shade600,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.level.localizedName(widget.currentLang),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.currentLang != 'ar' ? widget.level.nameAr : widget.level.nameFr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? const Color(0xFF0F5132)
                                  : (widget.isDark ? Colors.white60 : Colors.black54),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF0F5132).withValues(alpha: 0.12)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: active
                            ? const Color(0xFF0F5132)
                            : (widget.isDark ? Colors.white38 : Colors.grey.shade400),
                        size: 19,
                      ),
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
