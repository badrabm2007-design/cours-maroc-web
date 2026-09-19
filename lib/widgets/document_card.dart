import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/curriculum_models.dart';
import '../services/app_language_service.dart';
import '../services/download_service.dart';
import '../services/favorites_service.dart';
import '../services/smart_prefetch_service.dart';
import '../services/user_profile_service.dart';
import '../screens/pdf_viewer_screen.dart';

class DocumentCard extends StatelessWidget {
  final DocumentItem document;
  final String subjectName;
  final Color accentColor;
  final List<DocumentItem>? categoryDocuments;
  final int? documentIndex;

  const DocumentCard({
    super.key,
    required this.document,
    required this.subjectName,
    this.accentColor = const Color(0xFF0F5132),
    this.categoryDocuments,
    this.documentIndex,
  });

  void _openDocument(BuildContext context) {
    context
        .read<UserProfileService>()
        .recordDocumentView(document, subjectName);

    // Predictive neighbor pre-caching: prefetch 2 before and 2 after with highest priority
    if (categoryDocuments != null && documentIndex != null) {
      context.read<SmartPrefetchService>().prefetchSurroundingNeighbors(
            documents: categoryDocuments!,
            currentIndex: documentIndex!,
            downloadService: context.read<DownloadService>(),
            radius: 2,
          );
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          document: document,
          subjectName: subjectName,
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final downloadService = context.read<DownloadService>();
    final isDownloaded = downloadService.isDownloaded(document.id);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.chrome_reader_mode_rounded,
                      color: Color(0xFF0F5132)),
                  title: const Text('Lire le document'),
                  subtitle: const Text('Affichage immédiat dans l\'application'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openDocument(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    isDownloaded
                        ? Icons.offline_pin_rounded
                        : Icons.download_rounded,
                    color: const Color(0xFF10B981),
                  ),
                  title: Text(isDownloaded
                      ? 'Document enregistré hors-ligne'
                      : 'Enregistrer hors-ligne'),
                  subtitle: Text(isDownloaded
                      ? 'Disponible sans connexion Internet'
                      : 'Conserver sur l\'appareil pour réviser hors-ligne'),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (!isDownloaded) {
                      downloadService.downloadDocument(
                        document: document,
                        subjectName: subjectName,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'cours':
        return const Color(0xFF2563EB); // Blue
      case 'exercices':
        return const Color(0xFF0D9488); // Teal
      case 'controles':
        return const Color(0xFF7C3AED); // Violet
      case 'examens':
        return const Color(0xFFDC2626); // Red
      case 'resumes':
        return const Color(0xFFD97706); // Amber
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget? _buildExamSessionBadge(bool isDark, bool isArabic) {
    if (document.category != 'examens') return null;
    final t = '${document.title} ${document.name}'.toLowerCase();
    final isRatt = t.contains('rattrapage') ||
        t.contains('ratt') ||
        t.contains('استدراكية') ||
        t.contains('الاستدراكية') ||
        t.contains('-sr') ||
        t.contains('_sr');
    final isNorm = t.contains('normale') ||
        t.contains('normal') ||
        t.contains('عادية') ||
        t.contains('العادية') ||
        t.contains('-sn') ||
        t.contains('_sn');

    if (!isRatt && !isNorm) return null;

    final label = isRatt
        ? (isArabic ? 'استدراكية' : 'Rattrapage')
        : (isArabic ? 'عادية' : 'Normale');
    final color = isRatt ? const Color(0xFFD97706) : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget? _buildExamYearBadge(bool isDark) {
    if (document.category != 'examens' || document.examYear <= 0) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${document.examYear}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloadService = context.watch<DownloadService>();
    final favoritesService = context.watch<FavoritesService>();
    final langService = context.watch<AppLanguageService>();

    final isDownloaded = downloadService.isDownloaded(document.id);
    final isDownloading = downloadService.isDownloading(document.id);
    final downloadProgress = downloadService.getProgress(document.id);
    final isFav = favoritesService.isFavorite(document.id);
    final catColor = _getCategoryColor(document.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDownloaded
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : (isDark ? const Color(0xFF1F2E45) : const Color(0xFFE2E8F0)),
          width: isDownloaded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.025),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDocument(context),
          onLongPress: () => _showContextMenu(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                // Compact Category / PDF Icon Badge
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: isDark ? 0.22 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        document.category == 'cours'
                            ? Icons.menu_book_rounded
                            : (document.category == 'exercices'
                                ? Icons.edit_note_rounded
                                : (document.category == 'controles'
                                    ? Icons.assignment_rounded
                                    : (document.category == 'examens'
                                        ? Icons.military_tech_rounded
                                        : Icons.picture_as_pdf_rounded))),
                        color: catColor,
                        size: 21,
                      ),
                    ),
                    if (isDownloaded)
                      Container(
                        width: 13,
                        height: 13,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 9,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 11),

                // Center Title & Compact Info Line
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        document.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 5,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Semester Tag
                          if (document.semester == 'semestre-1')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? Colors.white10
                                        : const Color(0xFFE2E8F0))
                                    .withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'S1',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            )
                          else if (document.semester == 'semestre-2')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? Colors.white10
                                        : const Color(0xFFE2E8F0))
                                    .withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'S2',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),

                          // Exam Year Badge
                          if (document.category == 'examens')
                            Builder(
                              builder: (_) {
                                final yr = _buildExamYearBadge(isDark);
                                return yr ?? const SizedBox.shrink();
                              },
                            ),

                          // Exam Session Badge
                          if (document.category == 'examens')
                            Builder(
                              builder: (_) {
                                final sess = _buildExamSessionBadge(
                                    isDark, langService.isArabic);
                                return sess ?? const SizedBox.shrink();
                              },
                            ),

                          // Corrigé Badge (Compact pill)
                          if (document.isCorrige)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5.5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: isDark ? 0.22 : 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                langService.isArabic
                                    ? 'مع التصحيح'
                                    : 'Corrigé',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),

                          // File Size Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4.5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              document.formattedSize.isNotEmpty
                                  ? document.formattedSize
                                  : 'PDF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Download Button (Offline save)
                if (isDownloading)
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        value: downloadProgress > 0.05 ? downloadProgress : null,
                        strokeWidth: 2.2,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  )
                else if (isDownloaded)
                  IconButton(
                    icon: const Icon(
                      Icons.offline_pin_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    tooltip: 'Enregistré hors-ligne',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ce document est déjà enregistré hors-ligne.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  )
                else
                  IconButton(
                    icon: Icon(
                      Icons.download_rounded,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      size: 20,
                    ),
                    tooltip: langService.tr('btn_download'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Téléchargement de "${document.title}"...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      final result = await downloadService.downloadDocument(
                        document: document,
                        subjectName: subjectName,
                      );
                      if (context.mounted && result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(langService.tr('pdf_offline_ready')),
                            backgroundColor: const Color(0xFF10B981),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),

                // Favorite Button
                IconButton(
                  icon: Icon(
                    isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFav ? const Color(0xFFF59E0B) : (isDark ? Colors.white38 : Colors.grey.shade400),
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  onPressed: () {
                    favoritesService.toggleFavorite(
                      document: document,
                      subjectName: subjectName,
                    );
                  },
                ),
                const SizedBox(width: 4),

                // Compact "Lire" Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                    foregroundColor: isDark ? Colors.white : accentColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    minimumSize: const Size(50, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => _openDocument(context),
                  child: Text(langService.tr('btn_read')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
