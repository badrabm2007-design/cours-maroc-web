import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/curriculum_models.dart';
import '../services/app_language_service.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';
import '../services/user_sync_service.dart';
import '../services/favorites_service.dart';
import '../services/curriculum_service.dart';
import 'branch_selection_screen.dart';
import 'home_screen.dart';
import 'orientation_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final bool isChangingGrade;

  const LevelSelectionScreen({super.key, this.isChangingGrade = false});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedLevelId = '2eme-bac';

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileService>();
    if (profile.hasSelectedGrade) {
      _selectedLevelId = profile.savedLevelId;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleFirstLaunchGoogleSignIn() async {
    final auth = context.read<AuthService>();
    final syncService = context.read<UserSyncService>();
    final profileService = context.read<UserProfileService>();
    final favService = context.read<FavoritesService>();
    final curriculumService = context.read<CurriculumService>();
    final langService = context.read<AppLanguageService>();

    final success = await auth.signInWithGoogle();
    if (!mounted) return;

    if (success && auth.currentUser != null) {
      final token = await auth.getIdToken();
      if (token != null) {
        final result = await syncService.syncOnLogin(
          userId: auth.currentUser!.id,
          idToken: token,
          profileService: profileService,
          favService: favService,
          platform: 'web',
        );

        if (!mounted) return;

        if (result.hasSelectedGrade) {
          await curriculumService.selectLevelAndBranch(
            profileService.savedLevelId,
            profileService.savedBranchId,
          );

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                langService.isArabic
                    ? 'مرحباً ${auth.currentUser!.displayName}! تمت مزامنة بياناتك بنجاح.'
                    : 'Bienvenue ${auth.currentUser!.displayName} ! Vos données ont été synchronisées.',
              ),
              backgroundColor: const Color(0xFF0F5132),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            langService.isArabic
                ? 'متصل كـ ${auth.currentUser!.displayName}. اختر مستواك الدراسي أدناه.'
                : 'Connecté en tant que ${auth.currentUser!.displayName}. Choisissez votre niveau ci-dessous.',
          ),
          backgroundColor: const Color(0xFF0F5132),
        ),
      );
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
                langService.isArabic
                    ? 'المستوى الدراسي والتوجيه'
                    : 'Niveau Scolaire & Orientation',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: isDesktop,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 12,
              vertical: isDesktop ? 12 : 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.isChangingGrade) ...[
                      // Top row: Compact Google Sign-in pill (placed at top-end / top-right)
                      Consumer<AuthService>(
                        builder: (context, auth, _) {
                          if (auth.isAuthenticated) return const SizedBox.shrink();
                          return Container(
                            alignment: AlignmentDirectional.centerEnd,
                            margin: const EdgeInsets.only(bottom: 6),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: auth.isSigningIn
                                    ? null
                                    : () => _handleFirstLaunchGoogleSignIn(),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F5132).withValues(
                                        alpha: isDark ? 0.22 : 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF0F5132)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.1),
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'G',
                                            style: TextStyle(
                                              color: Color(0xFF4285F4),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                              fontFamily: 'Roboto',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        langService.isArabic
                                            ? 'لديك حساب؟ '
                                            : 'Déjà un compte ? ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                      if (auth.isSigningIn)
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF0F5132),
                                          ),
                                        )
                                      else
                                        Text(
                                          langService.isArabic
                                              ? 'دخول'
                                              : 'Connexion',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F5132),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // App Logo
                      Center(
                        child: Container(
                          width: isDesktop ? 64 : 48,
                          height: isDesktop ? 64 : 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F5132)
                                    .withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // App Title
                      Center(
                        child: Text(
                          langService.tr('app_title'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 22 : 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // App Subtitle
                      Center(
                        child: Text(
                          langService.tr('app_subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isDesktop ? 13 : 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F5132),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Disclaimer Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
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
                                size: 13,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  langService.tr('app_disclaimer_badge'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isDesktop ? 11 : 10,
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
                      const SizedBox(height: 10),
                    ],

                    // Section Title: "Choisissez votre niveau ou l'orientation :"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        widget.isChangingGrade
                            ? (langService.isArabic
                                ? 'اختر مستواك الدراسي أو دليل التوجيه :'
                                : 'Choisissez votre niveau ou l\'orientation :')
                            : (langService.isArabic
                                ? '1. اختر مستواك الدراسي أو دليل التوجيه :'
                                : '1. Choisissez votre niveau ou l\'orientation :'),
                        style: TextStyle(
                          fontSize: isDesktop ? 16.5 : 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Level Cards Display (2 per row on Desktop = 3 lines total, Column on Mobile)
                    if (isDesktop) ...[
                      for (int i = 0; i < LevelOption.allLevels.length; i += 2) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _LevelCardItem(
                                level: LevelOption.allLevels[i],
                                isSelected: LevelOption.allLevels[i].id == _selectedLevelId,
                                isDark: isDark,
                                currentLang: currentLang,
                                icon: _getLevelIcon(LevelOption.allLevels[i].id),
                                onTap: () => _navigateToBranch(LevelOption.allLevels[i]),
                              ),
                            ),
                            if (i + 1 < LevelOption.allLevels.length) ...[
                              const SizedBox(width: 18),
                              Expanded(
                                child: _LevelCardItem(
                                  level: LevelOption.allLevels[i + 1],
                                  isSelected: LevelOption.allLevels[i + 1].id == _selectedLevelId,
                                  isDark: isDark,
                                  currentLang: currentLang,
                                  icon: _getLevelIcon(LevelOption.allLevels[i + 1].id),
                                  onTap: () => _navigateToBranch(LevelOption.allLevels[i + 1]),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      // 5th Card: Orientation & Post-Bac Maroc (Row 3, 2-column span)
                      Row(
                        children: [
                          Expanded(
                            child: _OrientationCardItem(
                              isDark: isDark,
                              currentLang: currentLang,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const OrientationScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ] else ...[
                      // Mobile: 5 cards in vertical column
                      for (final lvl in LevelOption.allLevels) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _LevelCardItem(
                            level: lvl,
                            isSelected: lvl.id == _selectedLevelId,
                            isDark: isDark,
                            currentLang: currentLang,
                            icon: _getLevelIcon(lvl.id),
                            onTap: () => _navigateToBranch(lvl),
                          ),
                        ),
                      ],
                      // 5th Card on Mobile
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OrientationCardItem(
                          isDark: isDark,
                          currentLang: currentLang,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const OrientationScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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

  String _getLevelTag(String id, bool isAr) {
    switch (id) {
      case '3eme-annee-college':
        return isAr
            ? 'شهادة السلك الإعدادي • جميع المواد والامتحانات'
            : 'Préparation Brevet • Toutes les matières & examens';
      case 'tronc-commun':
        return isAr
            ? 'علوم خيار فرنسية BIOF • آداب • تكنولوجي'
            : 'Sciences BIOF • Lettres • Technologies';
      case '1ere-bac':
        return isAr
            ? 'الامتحان الجهوي (25%) • جميع الشعب والمسالك'
            : 'Examens Régionaux (25%) • Toutes les filières';
      case '2eme-bac':
        return isAr
            ? 'الامتحان الوطني (75%) • PC, SVT, SMA, SMB, Éco...'
            : 'Examen National (75%) • PC, SVT, SMA, SMB, Éco...';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    final isAr = widget.currentLang == 'ar';
    final active = widget.isSelected || _isHovered;
    final tagText = _getLevelTag(widget.level.id, isAr);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
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
              width: active ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? const Color(0xFF0F5132).withValues(alpha: widget.isDark ? 0.3 : 0.12)
                    : Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.03),
                blurRadius: active ? 14 : 6,
                offset: active ? const Offset(0, 4) : const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 20 : 14,
                  vertical: isDesktop ? 18 : 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: isDesktop ? 56 : 44,
                      height: isDesktop ? 56 : 44,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF0F5132)
                            : (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F5132).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        widget.icon,
                        color: active ? Colors.white : Colors.grey.shade600,
                        size: isDesktop ? 28 : 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.level.localizedName(widget.currentLang),
                            style: TextStyle(
                              fontSize: isDesktop ? 18.5 : 15.5,
                              fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.currentLang != 'ar' ? widget.level.nameAr : widget.level.nameFr,
                            style: TextStyle(
                              fontSize: isDesktop ? 13.5 : 12,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? const Color(0xFF0F5132)
                                  : (widget.isDark ? Colors.white60 : Colors.black54),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isDesktop && tagText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF0F5132).withValues(alpha: 0.12)
                                    : (widget.isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tagText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? const Color(0xFF0F5132)
                                      : (widget.isDark ? Colors.white54 : const Color(0xFF64748B)),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(7),
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
                        size: isDesktop ? 18 : 15,
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

class _OrientationCardItem extends StatefulWidget {
  final bool isDark;
  final String currentLang;
  final VoidCallback onTap;

  const _OrientationCardItem({
    required this.isDark,
    required this.currentLang,
    required this.onTap,
  });

  @override
  State<_OrientationCardItem> createState() => _OrientationCardItemState();
}

class _OrientationCardItemState extends State<_OrientationCardItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    final isAr = widget.currentLang == 'ar';
    final active = _isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.012 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF0F5132).withValues(alpha: widget.isDark ? 0.22 : 0.08)
                : (widget.isDark ? const Color(0xFF162032) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? const Color(0xFF0F5132)
                  : (widget.isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0)),
              width: active ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? const Color(0xFF0F5132).withValues(alpha: widget.isDark ? 0.3 : 0.12)
                    : Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.03),
                blurRadius: active ? 14 : 6,
                offset: active ? const Offset(0, 4) : const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 20 : 14,
                  vertical: isDesktop ? 18 : 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: isDesktop ? 56 : 44,
                      height: isDesktop ? 56 : 44,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF0F5132)
                            : (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F5132).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.explore_rounded,
                        color: active ? Colors.white : const Color(0xFF0F5132),
                        size: isDesktop ? 28 : 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isAr
                                      ? 'دليل التوجيه بعد الباكالوريا'
                                      : 'Orientation & Post-Bac Maroc',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 19 : 16,
                                    fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                                    color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '2026',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAr
                                ? 'المدارس العليا، كليات الطب والهندسة، العتبات التاريخية ومحاكي الانتقاء'
                                : 'Grandes écoles, universités, seuils historiques & simulateur de calcul',
                            style: TextStyle(
                              fontSize: isDesktop ? 13.5 : 12,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? const Color(0xFF0F5132)
                                  : (widget.isDark ? Colors.white60 : Colors.black54),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isDesktop) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF0F5132).withValues(alpha: 0.12)
                                    : (widget.isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isAr
                                    ? '🏛️ ENSA • ENSAM • ENCG • FMP • IAV • CPGE • BTS • EST • محاكي CursusSup'
                                    : '🏛️ ENSA • ENSAM • ENCG • FMP • IAV • CPGE • BTS • EST • Simulateur CursusSup',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? const Color(0xFF0F5132)
                                      : (widget.isDark ? Colors.white54 : const Color(0xFF64748B)),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(7),
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
                        size: isDesktop ? 18 : 15,
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

