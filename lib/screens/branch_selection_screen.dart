import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/curriculum_models.dart';
import '../services/app_language_service.dart';
import '../services/curriculum_service.dart';
import '../services/download_service.dart';
import '../services/smart_prefetch_service.dart';
import '../services/user_profile_service.dart';
import 'home_screen.dart';

class BranchSelectionScreen extends StatefulWidget {
  final LevelOption level;
  final bool isChangingGrade;

  const BranchSelectionScreen({
    super.key,
    required this.level,
    this.isChangingGrade = false,
  });

  @override
  State<BranchSelectionScreen> createState() => _BranchSelectionScreenState();
}

class _BranchSelectionScreenState extends State<BranchSelectionScreen> {
  late String _selectedBranchId;

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileService>();
    if (profile.hasSelectedGrade &&
        widget.level.branches.any((b) => b.id == profile.savedBranchId)) {
      _selectedBranchId = profile.savedBranchId;
    } else {
      _selectedBranchId = widget.level.branches.first.id;
    }
  }

  Future<void> _onSelectBranch(BranchOption branch) async {
    setState(() {
      _selectedBranchId = branch.id;
    });
    await _submitSelection(branch.id);
  }

  Future<void> _submitSelection([String? branchId]) async {
    final targetBranchId = branchId ?? _selectedBranchId;
    final profile = context.read<UserProfileService>();
    final curriculum = context.read<CurriculumService>();

    await profile.saveGrade(
      levelId: widget.level.id,
      branchId: targetBranchId,
    );

    await curriculum.selectLevelAndBranch(
      widget.level.id,
      targetBranchId,
    );

    if (!mounted) return;

    final subjects = curriculum.getCurrentSubjects();
    context.read<SmartPrefetchService>().prefetchHomeScreenInitial(
          subjects: subjects,
          userProfile: profile,
          downloadService: context.read<DownloadService>(),
        );

    if (widget.isChangingGrade) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  IconData _getBranchIcon(String id) {
    switch (id) {
      case 'sciences':
        return Icons.biotech_rounded;
      case 'sciences-experimentales':
        return Icons.science_rounded;
      case 'sciences-maths':
        return Icons.functions_rounded;
      case 'sciences-maths-b':
        return Icons.calculate_rounded;
      case 'sciences-physiques':
        return Icons.bolt_rounded;
      case 'sciences-svt':
        return Icons.eco_rounded;
      case 'sciences-economiques':
      case 'sciences-economiques-et-gestion':
        return Icons.trending_up_rounded;
      case 'sciences-gestion-comptable':
        return Icons.account_balance_rounded;
      case 'lettres':
        return Icons.import_contacts_rounded;
      case 'sciences-humaines':
        return Icons.public_rounded;
      case 'lettres-et-sciences-humaines':
        return Icons.menu_book_rounded;
      case 'technologie':
        return Icons.settings_suggest_rounded;
      case 'sciences-technologies-electriques':
        return Icons.electrical_services_rounded;
      case 'sciences-technologies-mecaniques':
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
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isChangingGrade
              ? langService.tr('change_branch_title')
              : widget.level.localizedName(currentLang),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 18 : 12,
            vertical: isDesktop ? 20 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title: Choix de la filière
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langService.tr('branch_selection_title'),
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      langService.tr('branch_selection_desc'),
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 13,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Responsive: 2 items per line on Desktop, 1 on Mobile
              Expanded(
                child: isDesktop
                    ? GridView.builder(
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        itemCount: widget.level.branches.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          mainAxisExtent: 108,
                        ),
                        itemBuilder: (context, index) {
                          final branch = widget.level.branches[index];
                          final isSelected = branch.id == _selectedBranchId;
                          return _BranchCardItem(
                            branch: branch,
                            isSelected: isSelected,
                            isDark: isDark,
                            currentLang: currentLang,
                            icon: _getBranchIcon(branch.id),
                            onTap: () => _onSelectBranch(branch),
                          );
                        },
                      )
                    : ListView.builder(
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        itemCount: widget.level.branches.length,
                        itemBuilder: (context, index) {
                          final branch = widget.level.branches[index];
                          final isSelected = branch.id == _selectedBranchId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BranchCardItem(
                              branch: branch,
                              isSelected: isSelected,
                              isDark: isDark,
                              currentLang: currentLang,
                              icon: _getBranchIcon(branch.id),
                              onTap: () => _onSelectBranch(branch),
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

class _BranchCardItem extends StatefulWidget {
  final BranchOption branch;
  final bool isSelected;
  final bool isDark;
  final String currentLang;
  final IconData icon;
  final VoidCallback onTap;

  const _BranchCardItem({
    required this.branch,
    required this.isSelected,
    required this.isDark,
    required this.currentLang,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_BranchCardItem> createState() => _BranchCardItemState();
}

class _BranchCardItemState extends State<_BranchCardItem> {
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
            borderRadius: BorderRadius.circular(18),
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
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF0F5132)
                            : (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(15),
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
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.branch.localizedName(widget.currentLang),
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.currentLang != 'ar' ? widget.branch.nameAr : widget.branch.nameFr,
                            style: TextStyle(
                              fontSize: 13,
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
                        size: 18,
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
