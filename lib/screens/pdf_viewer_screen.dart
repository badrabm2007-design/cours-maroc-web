import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/curriculum_models.dart';
import '../services/app_language_service.dart';
import '../services/download_service.dart';
import '../services/favorites_service.dart';
import '../services/focus_timer_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/compact_sticky_note_card.dart';
import '../widgets/compact_translation_card.dart';
import '../widgets/draggable_sticky_note_widget.dart';
import '../widgets/pdf_annotation_toolbar.dart';
import '../widgets/pdf_drawing_canvas.dart';
import '../widgets/pdf_text_selection_menu.dart';

class PdfViewerScreen extends StatefulWidget {
  final DocumentItem document;
  final String subjectName;

  const PdfViewerScreen({
    super.key,
    required this.document,
    required this.subjectName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 1;
  late final PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  bool _hasLoadError = false;
  bool _useDirectDriveUrl = false;

  PdfTool _activeTool = PdfTool.none;
  Color _penColor = const Color(0xFF0F172A);
  double _penWidth = 3.0;
  Color _highlighterColor = const Color(0xFFFACC15);
  double _highlighterWidth = 18.0;
  final List<DrawingStroke> _strokes = [];
  final List<TextNote> _notes = [];
  final List<DraggableNote> _draggableNotes = [];
  String? _selectedText;
  Offset? _contextMenuOffset;

  bool _isToolbarDocked = true;

  bool _showTranslationCard = false;
  Offset _translationCardPosition = const Offset(100, 100);
  String _translationCardText = '';

  bool _showStickyNoteCard = false;
  Offset _stickyNoteCardPosition = const Offset(150, 150);

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FocusTimerService>().pushDockingScreen(ActiveDockingScreen.pdfViewer);
        context.read<UserProfileService>().recordDocumentView(
              widget.document,
              widget.subjectName,
            );
      }
    });
  }

  @override
  void dispose() {
    try {
      context.read<FocusTimerService>().popDockingScreen(ActiveDockingScreen.pdfViewer);
    } catch (_) {}
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _handleToolSelected(
    PdfTool tool, {
    double? toolbarX,
    double? toolbarY,
    bool isMobile = false,
  }) {
    setState(() {
      _activeTool = tool;
      if (tool == PdfTool.highlighter) {
        final lines = _pdfViewerKey.currentState?.getSelectedTextLines() ?? [];
        if (lines.isNotEmpty) {
          final annotation =
              HighlightAnnotation(textBoundsCollection: lines)
                ..color = _highlighterColor;
          _pdfViewerController.addAnnotation(annotation);
          _pdfViewerController.clearSelection();
          _contextMenuOffset = null;
          _selectedText = null;
        }
      } else if (tool == PdfTool.textNote) {
        final screenW = MediaQuery.of(context).size.width;
        final screenH = MediaQuery.of(context).size.height;
        if (toolbarX != null && toolbarY != null) {
          _stickyNoteCardPosition = Offset(
            toolbarX.clamp(10.0, (screenW - 310.0).clamp(10.0, double.infinity)),
            isMobile
                ? 20.0
                : (toolbarY + 45.0).clamp(10.0, (screenH - 260.0).clamp(10.0, double.infinity)),
          );
        } else {
          _stickyNoteCardPosition = Offset(
            ((screenW - 300) / 2).clamp(10.0, double.infinity),
            screenH * 0.22,
          );
        }
        _showStickyNoteCard = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favService = context.watch<FavoritesService>();
    final downloadService = context.watch<DownloadService>();
    final langService = context.watch<AppLanguageService>();
    final isFav = favService.isFavorite(widget.document.id);
    final isDownloaded = downloadService.isDownloaded(widget.document.id);

    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 700;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
            height: 1.0,
          ),
        ),
        title: isMobile
                ? Row(
                    children: [
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.document.title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${widget.subjectName} • ${widget.document.categoryDisplayName}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isDownloaded
                              ? Icons.check_circle_rounded
                              : Icons.download_rounded,
                          color: isDownloaded ? const Color(0xFF10B981) : null,
                        ),
                        tooltip: isDownloaded
                            ? langService.tr('pdf_offline_badge')
                            : 'Télécharger le PDF',
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          await downloadService.downloadDocument(
                            document: widget.document,
                            subjectName: widget.subjectName,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Téléchargement lancé dans votre navigateur.'),
                                backgroundColor: Color(0xFF10B981),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isFav ? const Color(0xFFF59E0B) : null,
                        ),
                        tooltip: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          favService.toggleFavorite(
                            document: widget.document,
                            subjectName: widget.subjectName,
                          );
                        },
                      ),
                      if (_totalPages > 0)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_currentPage/$_totalPages',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Left side: Back button & Document details
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: (screenW * 0.28).clamp(100.0, 320.0),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.document.title,
                                    style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${widget.subjectName} • ${widget.document.categoryDisplayName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Exact True Center: Docked Toolbar
                      if (_isToolbarDocked)
                        Center(
                          child: PdfAnnotationToolbar(
                            activeTool: _activeTool,
                            onToolChanged: (tool) => _handleToolSelected(tool),
                            penColor: _penColor,
                            onPenColorChanged: (c) =>
                                setState(() => _penColor = c),
                            penWidth: _penWidth,
                            onPenWidthChanged: (w) =>
                                setState(() => _penWidth = w),
                            highlighterColor: _highlighterColor,
                            onHighlighterColorChanged: (c) =>
                                setState(() => _highlighterColor = c),
                            highlighterWidth: _highlighterWidth,
                            onHighlighterWidthChanged: (w) =>
                                setState(() => _highlighterWidth = w),
                            hasAnnotations: _strokes.isNotEmpty ||
                                _notes.isNotEmpty ||
                                _draggableNotes.isNotEmpty,
                            isDockedInAppBar: true,
                            onDetach: () {
                              setState(() {
                                _isToolbarDocked = false;
                              });
                            },
                            onClearAll: () => setState(() {
                              _strokes.clear();
                              _notes.clear();
                              _draggableNotes.clear();
                            }),
                            onZoomIn: () => _pdfViewerController.zoomLevel =
                                (_pdfViewerController.zoomLevel + 0.25)
                                    .clamp(1.0, 4.0),
                            onZoomOut: () => _pdfViewerController.zoomLevel =
                                (_pdfViewerController.zoomLevel - 0.25)
                                    .clamp(1.0, 4.0),
                            onTranslate: () {
                              setState(() {
                                _translationCardText = _selectedText ?? '';
                                _translationCardPosition = Offset(
                                  ((screenW - 320) / 2)
                                      .clamp(10.0, double.infinity),
                                  10.0,
                                );
                                _showTranslationCard = true;
                              });
                            },
                          ),
                        ),

                      // 3. Right side: Action buttons
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isDownloaded
                                    ? Icons.check_circle_rounded
                                    : Icons.download_rounded,
                                color: isDownloaded
                                    ? const Color(0xFF10B981)
                                    : null,
                              ),
                              tooltip: isDownloaded
                                  ? langService.tr('pdf_offline_badge')
                                  : 'Télécharger le PDF',
                              onPressed: () async {
                                await downloadService.downloadDocument(
                                  document: widget.document,
                                  subjectName: widget.subjectName,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Téléchargement lancé dans votre navigateur.'),
                                      backgroundColor: Color(0xFF10B981),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.g_translate_rounded),
                              tooltip: 'Traduction / ترجمة',
                              onPressed: () {
                                setState(() {
                                  _translationCardText = _selectedText ?? '';
                                  _translationCardPosition = Offset(
                                    (screenW - 325)
                                        .clamp(10.0, double.infinity),
                                    55,
                                  );
                                  _showTranslationCard = true;
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                isFav
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: isFav ? const Color(0xFFF59E0B) : null,
                              ),
                              tooltip: isFav
                                  ? 'Retirer des favoris'
                                  : 'Ajouter aux favoris',
                              onPressed: () {
                                favService.toggleFavorite(
                                  document: widget.document,
                                  subjectName: widget.subjectName,
                                );
                              },
                            ),
                            if (_totalPages > 0) ...[
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_currentPage / $_totalPages',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_hasLoadError) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.orange),
              const SizedBox(height: 14),
              const Text(
                'Impossible de charger le document',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Une erreur est survenue lors de la récupération du fichier.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                    onPressed: () {
                      setState(() {
                        _hasLoadError = false;
                        _useDirectDriveUrl = false;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Ouvrir Drive'),
                    onPressed: () {
                      final url = 'https://drive.google.com/file/d/${widget.document.id}/view';
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final String pdfUrl = _useDirectDriveUrl
        ? 'https://drive.usercontent.google.com/download?id=${widget.document.id}&export=download&confirm=t'
        : (kIsWeb
            ? Uri.base.resolve('/api/pdf?id=${widget.document.id}').toString()
            : 'https://drive.usercontent.google.com/download?id=${widget.document.id}&export=download&confirm=t');

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenW = constraints.maxWidth;
        final double screenH = constraints.maxHeight;
        final bool isMobile = screenW < 700;

        return Stack(
          key: _stackKey,
          children: [
            // 1. Native High-Performance PDF Viewer for Web
            SfPdfViewer.network(
              pdfUrl,
              key: _pdfViewerKey,
              controller: _pdfViewerController,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              canShowPaginationDialog: true,
              canShowTextSelectionMenu: false, // Custom menu with Translation!
              enableDoubleTapZooming: _activeTool == PdfTool.none,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                if (mounted) {
                  setState(() {
                    _totalPages = details.document.pages.count;
                  });
                }
              },
              onPageChanged: (PdfPageChangedDetails details) {
                if (mounted) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                }
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                debugPrint('PDF load failed (${_useDirectDriveUrl ? "direct" : "proxy"}): ${details.error} - ${details.description}');
                if (mounted) {
                  if (!_useDirectDriveUrl) {
                    setState(() {
                      _useDirectDriveUrl = true;
                    });
                  } else {
                    setState(() {
                      _hasLoadError = true;
                    });
                  }
                }
              },
              onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                final text = details.selectedText?.trim();
                if (mounted) {
                  if (text != null &&
                      text.isNotEmpty &&
                      details.globalSelectedRegion != null) {
                    final RenderBox? box = _stackKey.currentContext
                        ?.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final globalRegion = details.globalSelectedRegion!;
                      final localTopLeft =
                          box.globalToLocal(globalRegion.topLeft);
                      final localBottomRight =
                          box.globalToLocal(globalRegion.bottomRight);
                      final selectionRect =
                          Rect.fromPoints(localTopLeft, localBottomRight);

                      const double menuWidth = 195.0;
                      const double menuHeight = 245.0;

                      double left = selectionRect.center.dx - (menuWidth / 2);
                      left = left.clamp(
                        10.0,
                        (box.size.width - menuWidth - 10.0)
                            .clamp(10.0, double.infinity),
                      );

                      double top = selectionRect.top - menuHeight - 8.0;
                      if (top < 10.0) {
                        top = selectionRect.bottom + 8.0;
                        if (top + menuHeight > box.size.height - 10.0) {
                          top = ((box.size.height - menuHeight) / 2)
                              .clamp(10.0, double.infinity);
                        }
                      }

                      setState(() {
                        _selectedText = text;
                        _contextMenuOffset = Offset(left, top);
                      });
                    } else {
                      setState(() {
                        _selectedText = text;
                        _contextMenuOffset = const Offset(100, 100);
                      });
                    }
                  } else {
                    setState(() {
                      _selectedText = null;
                      _contextMenuOffset = null;
                    });
                  }
                }
              },
            ),

            // 2. Drawing / Annotations Layer
            Positioned.fill(
              child: PdfDrawingCanvas(
                activeTool: _activeTool,
                penColor: _penColor,
                penWidth: _penWidth,
                highlighterColor: _highlighterColor,
                highlighterWidth: _highlighterWidth,
                strokes: _strokes,
                notes: _notes,
                onRequestAddNote: (pos) {
                  setState(() {
                    _stickyNoteCardPosition = pos;
                    _showStickyNoteCard = true;
                  });
                },
                onStateChanged: () {
                  setState(() {});
                },
              ),
            ),

            // 3. Custom Text Selection Context Menu (Copier, Traduire, Surligner...)
            if (_contextMenuOffset != null &&
                _selectedText != null &&
                _selectedText!.isNotEmpty)
              Positioned(
                left: _contextMenuOffset!.dx,
                top: _contextMenuOffset!.dy,
                child: PdfTextSelectionContextMenu(
                  highlighterColor: _highlighterColor,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: _selectedText!));
                    _pdfViewerController.clearSelection();
                    setState(() {
                      _contextMenuOffset = null;
                      _selectedText = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Texte copié dans le presse-papiers'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  onTranslate: () {
                    final text = _selectedText!;
                    final pos = _contextMenuOffset ?? const Offset(100, 100);
                    _pdfViewerController.clearSelection();
                    setState(() {
                      _contextMenuOffset = null;
                      _translationCardText = text;
                      _translationCardPosition = Offset(
                        pos.dx.clamp(10.0,
                            (screenW - 325.0).clamp(10.0, double.infinity)),
                        pos.dy.clamp(10.0,
                            (screenH - 240.0).clamp(10.0, double.infinity)),
                      );
                      _showTranslationCard = true;
                    });
                  },
                  onHighlight: () {
                    final lines = _pdfViewerKey.currentState
                            ?.getSelectedTextLines() ??
                        [];
                    _pdfViewerController.clearSelection();
                    setState(() {
                      _contextMenuOffset = null;
                      _selectedText = null;
                    });
                    if (lines.isNotEmpty) {
                      final annotation =
                          HighlightAnnotation(textBoundsCollection: lines)
                            ..color = _highlighterColor;
                      _pdfViewerController.addAnnotation(annotation);
                    }
                  },
                  onUnderline: () {
                    final lines = _pdfViewerKey.currentState
                            ?.getSelectedTextLines() ??
                        [];
                    _pdfViewerController.clearSelection();
                    setState(() {
                      _contextMenuOffset = null;
                    });
                    if (lines.isNotEmpty) {
                      _pdfViewerController.addAnnotation(
                        UnderlineAnnotation(textBoundsCollection: lines),
                      );
                    }
                  },
                  onStrikethrough: () {
                    final lines = _pdfViewerKey.currentState
                            ?.getSelectedTextLines() ??
                        [];
                    _pdfViewerController.clearSelection();
                    setState(() {
                      _contextMenuOffset = null;
                    });
                    if (lines.isNotEmpty) {
                      _pdfViewerController.addAnnotation(
                        StrikethroughAnnotation(textBoundsCollection: lines),
                      );
                    }
                  },
                  onSquiggly: () {
                    final lines = _pdfViewerKey.currentState
                            ?.getSelectedTextLines() ??
                        [];
                    _pdfViewerController.clearSelection();
                    setState(() {
                      _contextMenuOffset = null;
                    });
                    if (lines.isNotEmpty) {
                      _pdfViewerController.addAnnotation(
                        SquigglyAnnotation(textBoundsCollection: lines),
                      );
                    }
                  },
                ),
              ),

            // 4. Draggable Floating Annotation Toolbar (when detached or on mobile)
            if (!_isToolbarDocked || isMobile)
              _FloatingDraggableToolbar(
                screenW: screenW,
                screenH: screenH,
                isMobile: isMobile,
                activeTool: _activeTool,
                onToolChanged: (tool, tx, ty) => _handleToolSelected(
                  tool,
                  toolbarX: tx,
                  toolbarY: ty,
                  isMobile: isMobile,
                ),
                penColor: _penColor,
                onPenColorChanged: (c) => setState(() => _penColor = c),
                penWidth: _penWidth,
                onPenWidthChanged: (w) => setState(() => _penWidth = w),
                highlighterColor: _highlighterColor,
                onHighlighterColorChanged: (c) =>
                    setState(() => _highlighterColor = c),
                highlighterWidth: _highlighterWidth,
                onHighlighterWidthChanged: (w) =>
                    setState(() => _highlighterWidth = w),
                hasAnnotations: _strokes.isNotEmpty ||
                    _notes.isNotEmpty ||
                    _draggableNotes.isNotEmpty,
                onClearAll: () {
                  setState(() {
                    _strokes.clear();
                    _notes.clear();
                    _draggableNotes.clear();
                  });
                },
                onZoomIn: () {
                  _pdfViewerController.zoomLevel =
                      (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 4.0);
                },
                onZoomOut: () {
                  _pdfViewerController.zoomLevel =
                      (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 4.0);
                },
                onTranslate: (tx, ty) {
                  setState(() {
                    _translationCardText = _selectedText ?? '';
                    _translationCardPosition = Offset(
                      tx.clamp(10.0,
                          (screenW - 325.0).clamp(10.0, double.infinity)),
                      isMobile
                          ? 20.0
                          : (ty + 45.0).clamp(10.0,
                              (screenH - 240.0).clamp(10.0, double.infinity)),
                    );
                    _showTranslationCard = true;
                  });
                },
                onDockInAppBar: () {
                  setState(() {
                    _isToolbarDocked = true;
                  });
                },
              ),

            // 5. Translucent barrier to dismiss translation card on tap outside
            if (_showTranslationCard)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    setState(() {
                      _showTranslationCard = false;
                    });
                  },
                ),
              ),

            // 6. Compact Non-Blocking Floating Translation Card
            if (_showTranslationCard)
              Positioned(
                left: _translationCardPosition.dx,
                top: _translationCardPosition.dy,
                child: CompactTranslationCard(
                  initialText: _translationCardText,
                  subjectName: widget.subjectName,
                  onClose: () {
                    setState(() {
                      _showTranslationCard = false;
                    });
                  },
                ),
              ),

            // 7. Translucent barrier to dismiss sticky note card on tap outside
            if (_showStickyNoteCard)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    setState(() {
                      _showStickyNoteCard = false;
                      if (_activeTool == PdfTool.textNote) {
                        _activeTool = PdfTool.none;
                      }
                    });
                  },
                ),
              ),

            // 8. Compact Non-Blocking Floating Sticky Note Card
            if (_showStickyNoteCard)
              Positioned(
                left: _stickyNoteCardPosition.dx.clamp(
                    10.0, (screenW - 310.0).clamp(10.0, double.infinity)),
                top: _stickyNoteCardPosition.dy.clamp(
                    10.0, (screenH - 260.0).clamp(10.0, double.infinity)),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _stickyNoteCardPosition += details.delta;
                    });
                  },
                  child: CompactStickyNoteCard(
                    pageNumber: _currentPage > 0 ? _currentPage : 1,
                    onClose: () {
                      setState(() {
                        _showStickyNoteCard = false;
                        if (_activeTool == PdfTool.textNote) {
                          _activeTool = PdfTool.none;
                        }
                      });
                    },
                    onSave: (noteText) {
                      setState(() {
                        _draggableNotes.add(
                          DraggableNote(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                            position: _stickyNoteCardPosition,
                            text: noteText,
                          ),
                        );
                        _showStickyNoteCard = false;
                        _activeTool = PdfTool.none;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Note épinglée sur le document !'),
                          backgroundColor: Color(0xFF0F5132),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // 9. Interactive Draggable Sticky Notes Layer
            for (final note in _draggableNotes)
              DraggableStickyNoteWidget(
                key: ValueKey(note.id),
                note: note,
                screenConstraints: constraints,
                onPositionChanged: (newPos) =>
                    setState(() => note.position = newPos),
                onTextChanged: (newText) => setState(() => note.text = newText),
                onColorChanged: (newColor) =>
                    setState(() => note.color = newColor),
                onDelete: () => setState(() => _draggableNotes.remove(note)),
              ),
          ],
        );
      },
    );
  }
}

class _FloatingDraggableToolbar extends StatefulWidget {
  final double screenW;
  final double screenH;
  final bool isMobile;
  final PdfTool activeTool;
  final void Function(PdfTool tool, double toolbarX, double toolbarY) onToolChanged;
  final Color penColor;
  final ValueChanged<Color> onPenColorChanged;
  final double penWidth;
  final ValueChanged<double> onPenWidthChanged;
  final Color highlighterColor;
  final ValueChanged<Color> onHighlighterColorChanged;
  final double highlighterWidth;
  final ValueChanged<double> onHighlighterWidthChanged;
  final bool hasAnnotations;
  final VoidCallback onClearAll;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final void Function(double toolbarX, double toolbarY) onTranslate;
  final VoidCallback onDockInAppBar;

  const _FloatingDraggableToolbar({
    required this.screenW,
    required this.screenH,
    required this.isMobile,
    required this.activeTool,
    required this.onToolChanged,
    required this.penColor,
    required this.onPenColorChanged,
    required this.penWidth,
    required this.onPenWidthChanged,
    required this.highlighterColor,
    required this.onHighlighterColorChanged,
    required this.highlighterWidth,
    required this.onHighlighterWidthChanged,
    required this.hasAnnotations,
    required this.onClearAll,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onTranslate,
    required this.onDockInAppBar,
  });

  @override
  State<_FloatingDraggableToolbar> createState() =>
      _FloatingDraggableToolbarState();
}

class _FloatingDraggableToolbarState extends State<_FloatingDraggableToolbar> {
  late double _x;
  late double _y;
  bool _isVertical = false;
  bool _isDockedLeft = false;

  static const double _kHorizontalWidthEst = 300.0;
  static const double _kHorizontalHeightEst = 44.0;
  static const double _kVerticalWidthEst = 46.0;
  static const double _kVerticalHeightEst = 310.0;

  @override
  void initState() {
    super.initState();
    _resetPosition();
  }

  void _resetPosition() {
    if (widget.isMobile) {
      final double centeredX = (widget.screenW - _kHorizontalWidthEst) / 2;
      // Shift left by 22px so the right end (the X close button) has generous room and is completely visible!
      _x = (centeredX - 22.0)
          .clamp(8.0, (widget.screenW - _kHorizontalWidthEst - 16.0).clamp(8.0, double.infinity));
      _y = (widget.screenH - _kHorizontalHeightEst - 14.0)
          .clamp(8.0, double.infinity);
      _isVertical = false;
      _isDockedLeft = false;
    } else {
      _x = ((widget.screenW - 470.0) / 2).clamp(10.0, widget.screenW - 480.0);
      _y = 60.0;
      _isVertical = false;
      _isDockedLeft = false;
    }
  }

  @override
  void didUpdateWidget(covariant _FloatingDraggableToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenW != widget.screenW ||
        oldWidget.screenH != widget.screenH) {
      _clampPosition();
    }
  }

  void _clampPosition() {
    final double maxW = _isVertical
        ? _kVerticalWidthEst
        : (widget.isMobile ? _kHorizontalWidthEst : 470.0);
    final double maxH =
        _isVertical ? _kVerticalHeightEst : _kHorizontalHeightEst;
    final double safeRightMargin = (!_isVertical && widget.isMobile) ? 16.0 : 6.0;
    _x = _x.clamp(6.0, (widget.screenW - maxW - safeRightMargin).clamp(6.0, double.infinity));
    _y = _y.clamp(6.0, (widget.screenH - maxH - 8.0).clamp(6.0, double.infinity));
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _x += details.delta.dx;
      _y += details.delta.dy;

      final double currentToolbarW = _isVertical
          ? _kVerticalWidthEst
          : (widget.isMobile ? _kHorizontalWidthEst : 470.0);

      // 1. Magnetic docking to left edge -> rotates vertically
      if (!_isVertical && _x <= 20.0) {
        _isVertical = true;
        _isDockedLeft = true;
        _x = 8.0;
        // Center vertically along edge so all buttons (including X) are visible
        _y = ((widget.screenH - _kVerticalHeightEst) / 2)
            .clamp(10.0, (widget.screenH - _kVerticalHeightEst - 16.0).clamp(10.0, double.infinity));
      }
      // 2. Magnetic docking to right edge -> rotates vertically
      else if (!_isVertical && (_x + currentToolbarW >= widget.screenW - 20.0)) {
        _isVertical = true;
        _isDockedLeft = false;
        _x = (widget.screenW - _kVerticalWidthEst - 6.0)
            .clamp(8.0, double.infinity);
        // Center vertically along edge so all buttons (including X) are visible
        _y = ((widget.screenH - _kVerticalHeightEst) / 2)
            .clamp(10.0, (widget.screenH - _kVerticalHeightEst - 16.0).clamp(10.0, double.infinity));
      }
      // 3. Undocking from left edge back to horizontal
      else if (_isVertical && _isDockedLeft && _x > 55.0) {
        _isVertical = false;
        _isDockedLeft = false;
        _x = 12.0;
      }
      // 4. Undocking from right edge back to horizontal
      else if (_isVertical && !_isDockedLeft && _x < widget.screenW - 85.0) {
        _isVertical = false;
        _isDockedLeft = false;
        final double targetW =
            widget.isMobile ? _kHorizontalWidthEst : 470.0;
        _x = (widget.screenW - targetW - 24.0).clamp(8.0, double.infinity);
      }

      // 5. On desktop, dragging to top edge docks back into AppBar
      if (!widget.isMobile && details.delta.dy < -0.5 && _y <= 5.0) {
        widget.onDockInAppBar();
        return;
      }

      _clampPosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isNearBottom = !_isVertical && _y > (widget.screenH * 0.55);

    return Positioned(
      left: _x,
      top: isNearBottom ? null : _y,
      bottom: isNearBottom
          ? (widget.screenH - _y - _kHorizontalHeightEst)
              .clamp(6.0, double.infinity)
          : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: _handlePanUpdate,
        child: PdfAnnotationToolbar(
          activeTool: widget.activeTool,
          onToolChanged: (tool) => widget.onToolChanged(tool, _x, _y),
          penColor: widget.penColor,
          onPenColorChanged: widget.onPenColorChanged,
          penWidth: widget.penWidth,
          onPenWidthChanged: widget.onPenWidthChanged,
          highlighterColor: widget.highlighterColor,
          onHighlighterColorChanged: widget.onHighlighterColorChanged,
          highlighterWidth: widget.highlighterWidth,
          onHighlighterWidthChanged: widget.onHighlighterWidthChanged,
          hasAnnotations: widget.hasAnnotations,
          isVertical: _isVertical,
          isDockedLeft: _isDockedLeft,
          optionsPanelAbove: isNearBottom,
          onClearAll: widget.onClearAll,
          onClose: () {
            if (widget.isMobile) {
              setState(() {
                _resetPosition();
              });
            } else {
              widget.onDockInAppBar();
            }
          },
          onZoomIn: widget.onZoomIn,
          onZoomOut: widget.onZoomOut,
          onTranslate: () => widget.onTranslate(_x, _y),
        ),
      ),
    );
  }
}
