import 'package:flutter/material.dart';

class PdfTextSelectionContextMenu extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback onTranslate;
  final VoidCallback onHighlight;
  final VoidCallback onUnderline;
  final VoidCallback onStrikethrough;
  final VoidCallback onSquiggly;
  final Color highlighterColor;

  const PdfTextSelectionContextMenu({
    super.key,
    required this.onCopy,
    required this.onTranslate,
    required this.onHighlight,
    required this.onUnderline,
    required this.onStrikethrough,
    required this.onSquiggly,
    this.highlighterColor = const Color(0xFFEAB308),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Matching the Material 3 surfaceContainerHighest / light purplish tone from Syncfusion
    final bgColor = isDark
        ? const Color.fromRGBO(48, 45, 56, 1)
        : const Color.fromRGBO(238, 232, 244, 1);

    final textColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF49454F);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 195,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMenuItem(
                  icon: Icons.copy_rounded,
                  label: 'Copier',
                  iconColor: iconColor,
                  textColor: textColor,
                  onTap: onCopy,
                ),
                _buildMenuItem(
                  icon: Icons.g_translate_rounded,
                  label: 'Traduire',
                  iconColor: const Color(0xFF2563EB),
                  textColor: const Color(0xFF2563EB),
                  isBold: true,
                  trailingBadge: 'IA',
                  onTap: onTranslate,
                ),
                Divider(
                  height: 6,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                _buildMenuItem(
                  icon: Icons.highlight_rounded,
                  label: 'Surligner',
                  iconColor: highlighterColor,
                  textColor: textColor,
                  onTap: onHighlight,
                ),
                _buildMenuItem(
                  icon: Icons.format_underlined_rounded,
                  label: 'Souligner',
                  iconColor: iconColor,
                  textColor: textColor,
                  onTap: onUnderline,
                ),
                _buildMenuItem(
                  icon: Icons.format_strikethrough_rounded,
                  label: 'Barrer',
                  iconColor: iconColor,
                  textColor: textColor,
                  onTap: onStrikethrough,
                ),
                _buildMenuItem(
                  icon: Icons.waves_rounded,
                  label: 'Onduler',
                  iconColor: iconColor,
                  textColor: textColor,
                  onTap: onSquiggly,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
    bool isBold = false,
    String? trailingBadge,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
        child: Row(
          children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (trailingBadge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trailingBadge,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
