import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_language_service.dart';
import '../services/curriculum_service.dart';
import 'level_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langService = context.watch<AppLanguageService>();
    final curriculum = context.watch<CurriculumService>();
    final currentLang = langService.currentLanguageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          langService.tr('settings_title'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
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
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: const Color(0xFF0F5132),
              ),
              value: isDarkMode,
              activeThumbColor: const Color(0xFF0F5132),
              onChanged: onToggleTheme != null ? (_) => onToggleTheme!() : null,
            ),
          ),

          const SizedBox(height: 28),

          // 4. About App
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
}
