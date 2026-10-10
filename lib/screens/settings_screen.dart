import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../services/app_language_service.dart';
import '../services/auth_service.dart';
import '../services/curriculum_service.dart';
import '../services/user_profile_service.dart';
import '../services/favorites_service.dart';
import '../services/focus_timer_service.dart';
import '../services/user_sync_service.dart';
import 'focus_mode_screen.dart';
import 'level_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langService = context.watch<AppLanguageService>();
    final curriculum = context.watch<CurriculumService>();
    final currentLang = langService.currentLanguageCode;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? const BackButton()
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: langService.isArabic ? 'رجوع' : 'Retour',
                onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
              ),
        title: Text(
          langService.tr('settings_title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 0. Account & Cloud Sync Section
          _buildSectionHeader(
            context: context,
            title: langService.tr('auth_section_title'),
            icon: Icons.account_circle_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildAccountCard(context, isDark, langService),
          const SizedBox(height: 24),

          // 1. Language Section
          _buildSectionHeader(
            context: context,
            title: langService.tr('settings_language'),
            icon: Icons.translate_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162032) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: AppLanguageService.supportedLanguages.map((option) {
                final isSelected = currentLang == option.code;
                final isFirst = option == AppLanguageService.supportedLanguages.first;
                final isLast = option == AppLanguageService.supportedLanguages.last;

                return InkWell(
                  borderRadius: BorderRadius.vertical(
                    top: isFirst ? const Radius.circular(18) : Radius.zero,
                    bottom: isLast ? const Radius.circular(18) : Radius.zero,
                  ),
                  onTap: () => langService.setLanguage(option.code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: !isLast
                          ? Border(
                              bottom: BorderSide(
                                color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFF1F5F9),
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Text(
                          option.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.nativeLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF0F5132)
                                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ),
                              if (option.code != 'fr') ...[
                                const SizedBox(height: 2),
                                Text(
                                  option.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F5132),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        else
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),

          // 2. Academic Level & Branch
          _buildSectionHeader(
            context: context,
            title: langService.tr('settings_academic'),
            icon: Icons.school_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162032) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F5132).withValues(alpha: isDark ? 0.3 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school_rounded, color: Color(0xFF0F5132), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            curriculum.currentLevel.localizedName(currentLang),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            curriculum.currentBranch.localizedName(currentLang),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: Text(langService.tr('settings_change_grade')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F5132),
                      side: const BorderSide(color: Color(0xFF0F5132)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: '/niveaux'),
                          builder: (_) => const LevelSelectionScreen(isChangingGrade: true),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 3. Theme Section
          _buildSectionHeader(
            context: context,
            title: langService.tr('settings_theme'),
            icon: Icons.palette_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162032) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                langService.tr('settings_dark_mode'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                langService.tr('settings_dark_mode_desc'),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              secondary: Icon(
                widget.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: const Color(0xFF0F5132),
              ),
              value: widget.isDarkMode,
              activeThumbColor: const Color(0xFF0F5132),
              onChanged: widget.onToggleTheme != null ? (_) => widget.onToggleTheme!() : null,
            ),
          ),

          const SizedBox(height: 28),

          // 3b. Mode Concentration (Focus Mode)
          _buildSectionHeader(
            context: context,
            title: langService.isArabic ? 'وضع التركيز (Focus Mode)' : 'Mode Concentration',
            icon: Icons.self_improvement_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162032) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    langService.isArabic
                        ? 'أيقونة التركيز في الشاشة الرئيسية'
                        : 'Afficher le mode concentration à l\'accueil',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    langService.isArabic
                        ? 'إظهار زر الوصول السريع لتقنيات بومودورو وفلو تايم في الشريط العلوي'
                        : 'Affiche l\'icône de concentration dans la barre supérieure de l\'accueil',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  secondary: const Icon(
                    Icons.self_improvement_rounded,
                    color: Color(0xFF0F5132),
                  ),
                  value: context.watch<FocusTimerService>().showHomeIcon,
                  activeThumbColor: const Color(0xFF0F5132),
                  onChanged: (val) => context.read<FocusTimerService>().setShowHomeIcon(val),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const Icon(Icons.timer_outlined, color: Color(0xFF0F5132)),
                  title: Text(
                    langService.isArabic
                        ? 'فتح مساحة التركيز الآن'
                        : 'Ouvrir l\'espace concentration',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    langService.isArabic
                        ? '5 تقنيات مراجعة، أهداف الحصة، ومؤثرات صوتية هادئة'
                        : '5 techniques (Pomodoro, Flowtime), to-do list & ambiances sonores',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: '/concentration'),
                        builder: (_) => const FocusModeScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 4. Feedback & Support Section
          _buildSectionHeader(
            context: context,
            title: langService.tr('feedback_section_title'),
            icon: Icons.rate_review_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildFeedbackCard(context, isDark, langService, curriculum),
          const SizedBox(height: 28),

          // 5. About App
          _buildSectionHeader(
            context: context,
            title: langService.tr('settings_about'),
            icon: Icons.info_outline_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162032) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F5132).withValues(alpha: isDark ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_rounded, color: Color(0xFF0F5132), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        langService.tr('app_title'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        langService.tr('settings_version'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. Clause de non-affiliation gouvernementale (Disclaimer officiel)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        langService.tr('disclaimer_title'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  langService.tr('disclaimer_text'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse('https://www.men.gov.ma');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF0F5132)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            langService.tr('official_source_label'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F5132),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse('https://qrayti.online/privacy/');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.privacy_tip_outlined, size: 14, color: Color(0xFF0F5132)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            langService.tr('feedback_privacy_link'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F5132),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F5132)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    bool isDark,
    AppLanguageService langService,
  ) {
    final auth = context.watch<AuthService>();
    final isAr = langService.isArabic;

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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: auth.isAuthenticated
          ? Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF0F5132),
                  backgroundImage: auth.currentUser!.photoUrl != null
                      ? NetworkImage(auth.currentUser!.photoUrl!)
                      : null,
                  child: auth.currentUser!.photoUrl == null
                      ? Text(
                          auth.currentUser!.displayName.isNotEmpty
                              ? auth.currentUser!.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              auth.currentUser!.displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAr ? 'متصل' : 'Connecté',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        auth.currentUser!.email,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  tooltip: langService.tr('auth_sign_out'),
                  onPressed: () => auth.signOut(),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr
                      ? 'سجل دخولك لحفظ المفضلة والملاحظات ومزامنة تقدمك الدراسي عبر جميع أجهزتك.'
                      : 'Connectez-vous pour sauvegarder vos favoris, annotations et synchroniser votre progression.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: auth.isSigningIn
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(color: Color(0xFF0F5132)),
                          ),
                        )
                      : FilledButton.icon(
                          icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                          label: Text(
                            langService.tr('auth_google_signin'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0F5132),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final syncService = context.read<UserSyncService>();
                            final profileService = context.read<UserProfileService>();
                            final favService = context.read<FavoritesService>();
                            final curriculumService = context.read<CurriculumService>();

                            final success = await auth.signInWithGoogle();
                            if (context.mounted && success && auth.currentUser != null) {
                              final token = await auth.getIdToken();
                              if (token != null) {
                                final res = await syncService.syncOnLogin(
                                  userId: auth.currentUser!.id,
                                  idToken: token,
                                  profileService: profileService,
                                  favService: favService,
                                  platform: 'android',
                                );
                                if (res.hasSelectedGrade) {
                                  await curriculumService.selectLevelAndBranch(
                                    profileService.savedLevelId,
                                    profileService.savedBranchId,
                                  );
                                }
                              }
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? langService.tr('auth_sync_active')
                                        : (isAr ? 'تعذر تسجيل الدخول' : 'Connexion annulée ou échouée'),
                                  ),
                                  backgroundColor: success ? const Color(0xFF0F5132) : Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeedbackCard(
    BuildContext context,
    bool isDark,
    AppLanguageService langService,
    CurriculumService curriculum,
  ) {
    final isAr = langService.isArabic;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F5132), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.rate_review_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langService.tr('feedback_card_title'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isAr
                          ? 'استفسار عن درس • طلب وثيقة • تقييم المنصة'
                          : 'Question de cours • Demande de doc • Avis & Note',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            langService.tr('feedback_card_desc'),
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          // Primary Action: Open modal to compose and send directly in-app
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(
                langService.tr('feedback_btn_open'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
              ),
              onPressed: () => _openFeedbackModal(context, langService, curriculum),
            ),
          ),
          const SizedBox(height: 14),
          // Direct Personal Contact Bar (WhatsApp & Email pills)
          Row(
            children: [
              Text(
                langService.tr('feedback_direct_contact'),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // WhatsApp pill
              InkWell(
                onTap: () async {
                  final uri = Uri.parse('https://wa.me/212700769996');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.18 : 0.1),
                    border: Border.all(
                      color: const Color(0xFF25D366).withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_rounded, size: 15, color: Color(0xFF25D366)),
                      const SizedBox(width: 6),
                      Text(
                        isAr ? 'واتساب : 0700-769996' : 'WhatsApp : +212 700-769996',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF25D366),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Email pill
              InkWell(
                onTap: () async {
                  final uri = Uri.parse('mailto:qrayticontact@gmail.com');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : const Color(0xFF0F5132)).withValues(alpha: 0.08),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 15,
                        color: isDark ? Colors.white70 : const Color(0xFF0F5132),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'qrayticontact@gmail.com',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF0F5132),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openFeedbackModal(
    BuildContext context,
    AppLanguageService langService,
    CurriculumService curriculum,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = langService.isArabic;
    final auth = context.read<AuthService>();

    int selectedRating = 5;
    String selectedType = 'review';
    bool isSubmitting = false;
    bool isSuccess = false;
    String? errorMessage;

    final nameController = TextEditingController(
      text: auth.currentUser?.displayName ?? '',
    );
    final emailController = TextEditingController(
      text: auth.currentUser?.email ?? '',
    );
    final messageController = TextEditingController();

    final List<Map<String, dynamic>> typeOptions = [
      {
        'key': 'review',
        'icon': Icons.star_rounded,
        'title': langService.tr('feedback_type_review'),
        'desc': langService.tr('feedback_type_review_sub'),
      },
      {
        'key': 'question',
        'icon': Icons.help_outline_rounded,
        'title': langService.tr('feedback_type_question'),
        'desc': langService.tr('feedback_type_question_sub'),
      },
      {
        'key': 'request',
        'icon': Icons.library_books_rounded,
        'title': langService.tr('feedback_type_request'),
        'desc': langService.tr('feedback_type_request_sub'),
      },
      {
        'key': 'suggestion',
        'icon': Icons.lightbulb_outline_rounded,
        'title': langService.tr('feedback_type_suggestion'),
        'desc': langService.tr('feedback_type_suggestion_sub'),
      },
      {
        'key': 'bug',
        'icon': Icons.bug_report_outlined,
        'title': langService.tr('feedback_type_bug'),
        'desc': langService.tr('feedback_type_bug_sub'),
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            String getRatingDescription(int rating) {
              if (isAr) {
                switch (rating) {
                  case 5:
                    return 'ممتاز !';
                  case 4:
                    return 'جيد جداً';
                  case 3:
                    return 'متوسط';
                  case 2:
                    return 'يحتاج تحسين';
                  default:
                    return 'ضعيف';
                }
              } else {
                switch (rating) {
                  case 5:
                    return 'Excellent !';
                  case 4:
                    return 'Très bien';
                  case 3:
                    return 'Moyen';
                  case 2:
                    return 'À améliorer';
                  default:
                    return 'Décevant';
                }
              }
            }

            Future<void> sendAutoFeedback() async {
              final msg = messageController.text.trim();
              if (msg.isEmpty) {
                setModalState(() {
                  errorMessage = langService.tr('feedback_message_required');
                });
                return;
              }

              setModalState(() {
                isSubmitting = true;
                errorMessage = null;
              });

              final name = nameController.text.trim().isEmpty
                  ? (isAr ? 'تلميذ في قرايتي' : 'Élève Qrayti')
                  : nameController.text.trim();
              final email = emailController.text.trim();
              final level = curriculum.shortLevelAndBranchCode;

              String typeLabel;
              switch (selectedType) {
                case 'review':
                  typeLabel = 'Avis ($selectedRating/5 ⭐)';
                  break;
                case 'question':
                  typeLabel = 'Question de cours';
                  break;
                case 'request':
                  typeLabel = 'Demande de document';
                  break;
                case 'suggestion':
                  typeLabel = 'Suggestion d\'idée';
                  break;
                case 'bug':
                  typeLabel = 'Signalement de problème';
                  break;
                default:
                  typeLabel = 'Message';
              }

              try {
                final dio = Dio(
                  BaseOptions(
                    connectTimeout: const Duration(seconds: 12),
                    receiveTimeout: const Duration(seconds: 12),
                  ),
                );

                final payload = {
                  'name': name,
                  'email': email.isNotEmpty ? email : 'noreply@qrayti.online',
                  '_subject': '[Qrayti - $typeLabel] $name ($level)',
                  'type': typeLabel,
                  'level': level,
                  'rating': selectedType == 'review' ? '$selectedRating / 5' : 'N/A',
                  'message': msg,
                  '_template': 'table',
                };

                final response = await dio.post(
                  'https://formsubmit.co/ajax/qrayticontact@gmail.com',
                  data: payload,
                  options: Options(
                    headers: {
                      'Accept': 'application/json',
                      'Content-Type': 'application/json',
                    },
                  ),
                );

                if (response.statusCode == 200) {
                  setModalState(() {
                    isSubmitting = false;
                    isSuccess = true;
                  });
                } else {
                  setModalState(() {
                    isSubmitting = false;
                    errorMessage = langService.tr('feedback_error_desc');
                  });
                }
              } catch (e) {
                setModalState(() {
                  isSubmitting = false;
                  errorMessage = langService.tr('feedback_error_desc');
                });
              }
            }

            Future<void> sendViaWhatsApp() async {
              final name = nameController.text.trim().isEmpty
                  ? (isAr ? 'تلميذ في قرايتي' : 'Élève Qrayti')
                  : nameController.text.trim();
              final level = curriculum.shortLevelAndBranchCode;
              final msg = messageController.text.trim();

              String typeLabel;
              switch (selectedType) {
                case 'review':
                  typeLabel = 'Avis ($selectedRating/5 ⭐)';
                  break;
                case 'question':
                  typeLabel = 'Question de cours';
                  break;
                case 'request':
                  typeLabel = 'Demande de document';
                  break;
                case 'suggestion':
                  typeLabel = 'Suggestion d\'idée';
                  break;
                case 'bug':
                  typeLabel = 'Signalement de problème';
                  break;
                default:
                  typeLabel = 'Message';
              }

              final text = '🎓 *Message Qrayti Online*\n'
                  '━━━━━━━━━━━━━━━━━━━━\n'
                  '📌 *Objet* : $typeLabel\n'
                  '👤 *De* : $name\n'
                  '📚 *Niveau* : $level\n'
                  '${selectedType == 'review' ? '⭐ *Note* : $selectedRating / 5\n' : ''}'
                  '━━━━━━━━━━━━━━━━━━━━\n'
                  '📝 *Message* :\n$msg';

              final url = 'https://wa.me/212700769996?text=${Uri.encodeComponent(text)}';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }

            Future<void> sendViaEmail() async {
              final name = nameController.text.trim().isEmpty
                  ? (isAr ? 'تلميذ في قرايتي' : 'Élève Qrayti')
                  : nameController.text.trim();
              final level = curriculum.shortLevelAndBranchCode;
              final msg = messageController.text.trim();

              String typeLabel;
              switch (selectedType) {
                case 'review':
                  typeLabel = 'Avis ($selectedRating/5 étoiles)';
                  break;
                case 'question':
                  typeLabel = 'Question de cours';
                  break;
                case 'request':
                  typeLabel = 'Demande de document';
                  break;
                case 'suggestion':
                  typeLabel = 'Suggestion d\'idée';
                  break;
                case 'bug':
                  typeLabel = 'Signalement de problème';
                  break;
                default:
                  typeLabel = 'Message';
              }

              final subject = '[Qrayti - $typeLabel] $name ($level)';
              final body = 'Bonjour l\'équipe Qrayti,\n\n'
                  'Objet : $typeLabel\n'
                  'Élève : $name\n'
                  'Niveau : $level\n'
                  '${selectedType == 'review' ? 'Évaluation : $selectedRating / 5 étoiles\n' : ''}\n'
                  'Message :\n$msg\n\n'
                  '---\nEnvoyé depuis Qrayti Online (qrayti.online)';

              final uri = Uri.parse('mailto:qrayticontact@gmail.com?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }

            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                margin: const EdgeInsets.only(top: 40),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: isSuccess
                    ? _buildSuccessView(sheetContext, isDark, langService)
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Handle bar
                            Center(
                              child: Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white24 : Colors.black12,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Header
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F5132).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.forum_outlined,
                                    color: Color(0xFF0F5132),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        langService.tr('feedback_dialog_title'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isAr
                                            ? 'فريق قرايتي يجيب على جميع رسائلكم'
                                            : 'L\'équipe Qrayti vous répond sous 24h',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  onPressed: () => Navigator.of(sheetContext).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Message Type Selector (2 columns structured grid)
                            Text(
                              langService.tr('feedback_type_label'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),

                            _buildTypeSelectorGrid(
                              typeOptions: typeOptions,
                              selectedType: selectedType,
                              onSelect: (val) => setModalState(() => selectedType = val),
                              isDark: isDark,
                            ),

                            // Star rating if 'review' selected
                            if (selectedType == 'review') ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      langService.tr('feedback_rating_label'),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      getRatingDescription(selectedRating),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: List.generate(5, (index) {
                                        final star = index + 1;
                                        return InkWell(
                                          onTap: () => setModalState(() => selectedRating = star),
                                          borderRadius: BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: Icon(
                                              star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                                              color: const Color(0xFFF59E0B),
                                              size: 26,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            // Name field
                            TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: langService.tr('feedback_name_label'),
                                hintText: langService.tr('feedback_name_hint'),
                                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Email field
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: langService.tr('feedback_email_field'),
                                hintText: langService.tr('feedback_email_hint'),
                                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Message field
                            TextFormField(
                              controller: messageController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: langService.tr('feedback_message_label'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),

                            // Error banner if any
                            if (errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: const TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Primary Action: Automated Direct Send
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send_rounded, size: 18),
                                label: Text(
                                  isSubmitting
                                      ? langService.tr('feedback_btn_sending')
                                      : langService.tr('feedback_btn_send_auto'),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F5132),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: isSubmitting ? null : sendAutoFeedback,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Secondary: Personal Apps Fallback
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    langService.tr('feedback_or_personal_apps'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                // WhatsApp
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.chat_rounded, size: 16, color: Color(0xFF25D366)),
                                    label: Text(
                                      langService.tr('feedback_send_whatsapp'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      side: BorderSide(
                                        color: const Color(0xFF25D366).withValues(alpha: 0.5),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: sendViaWhatsApp,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Email
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: Icon(
                                      Icons.mail_outline_rounded,
                                      size: 16,
                                      color: isDark ? Colors.white70 : const Color(0xFF0F5132),
                                    ),
                                    label: Text(
                                      langService.tr('feedback_send_email'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      side: BorderSide(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: sendViaEmail,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeSelectorGrid({
    required List<Map<String, dynamic>> typeOptions,
    required String selectedType,
    required ValueChanged<String> onSelect,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTypeOptionCard(typeOptions[0], selectedType, onSelect, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildTypeOptionCard(typeOptions[1], selectedType, onSelect, isDark)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTypeOptionCard(typeOptions[2], selectedType, onSelect, isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildTypeOptionCard(typeOptions[3], selectedType, onSelect, isDark)),
          ],
        ),
        const SizedBox(height: 8),
        _buildTypeOptionCard(typeOptions[4], selectedType, onSelect, isDark),
      ],
    );
  }

  Widget _buildTypeOptionCard(
    Map<String, dynamic> item,
    String selectedType,
    ValueChanged<String> onSelect,
    bool isDark,
  ) {
    final key = item['key'] as String;
    final isSelected = key == selectedType;
    final icon = item['icon'] as IconData;
    final title = item['title'] as String;
    final desc = item['desc'] as String;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(key),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F5132)
                : (isDark ? const Color(0xFF162032) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981)
                  : (isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F5132).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : (isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF0F5132),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    bool isDark,
    AppLanguageService langService,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 46,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            langService.tr('feedback_success_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            langService.tr('feedback_success_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                langService.tr('feedback_btn_close'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
