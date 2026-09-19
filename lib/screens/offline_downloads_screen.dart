import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/curriculum_models.dart';
import '../services/download_service.dart';
import 'pdf_viewer_screen.dart';

class OfflineDownloadsScreen extends StatelessWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloadService = context.watch<DownloadService>();
    final downloads = downloadService.allDownloads;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Cours Hors-ligne'),
        actions: [
          if (downloads.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    downloadService.formattedTotalSize,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: downloads.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F5132)
                            .withValues(alpha: isDark ? 0.2 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_download_outlined,
                        size: 40,
                        color: Color(0xFF0F5132),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Aucun document téléchargé',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Téléchargez vos cours, exercices et examens pour pouvoir les consulter à tout moment, même sans connexion Internet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final record = downloads[index];

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF162032) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1F2E45)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444)
                            .withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Color(0xFFEF4444),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      record.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            record.subjectName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F5132),
                            ),
                          ),
                          const Text(' • '),
                          Text(
                            record.formattedSize,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.red),
                          tooltip: 'Supprimer',
                          onPressed: () {
                            _showDeleteDialog(context, downloadService, record);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      final dummyDoc = DocumentItem(
                        id: record.fileId,
                        name: record.fileName,
                        title: record.title,
                        category: record.category,
                        semester: 'general',
                        isCorrige: false,
                        size: record.size,
                        driveUrl: '',
                      );

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(
                            document: dummyDoc,
                            subjectName: record.subjectName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showDeleteDialog(BuildContext context, DownloadService service,
      DownloadRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce document ?'),
        content: Text(
            'Voulez-vous supprimer "${record.title}" de votre stockage hors-ligne ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.deleteDownload(record.fileId);
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
