import 'package:flutter/material.dart';

enum PdfTool {
  none,
  pen,
  highlighter,
  eraser,
  textNote,
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isHighlighter;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.isHighlighter,
  });
}

class TextNote {
  final Offset position;
  final String text;
  final Color color;

  TextNote({
    required this.position,
    required this.text,
    this.color = const Color(0xFFFEF08A), // soft yellow
  });
}

class PdfDrawingCanvas extends StatefulWidget {
  final PdfTool activeTool;
  final Color penColor;
  final double penWidth;
  final Color highlighterColor;
  final double highlighterWidth;
  final List<DrawingStroke> strokes;
  final List<TextNote> notes;
  final VoidCallback onStateChanged;
  final ValueChanged<Offset>? onRequestAddNote;

  const PdfDrawingCanvas({
    super.key,
    required this.activeTool,
    required this.penColor,
    required this.penWidth,
    required this.highlighterColor,
    required this.highlighterWidth,
    required this.strokes,
    required this.notes,
    required this.onStateChanged,
    this.onRequestAddNote,
  });

  @override
  State<PdfDrawingCanvas> createState() => _PdfDrawingCanvasState();
}

class _PdfDrawingCanvasState extends State<PdfDrawingCanvas> {
  DrawingStroke? _currentStroke;

  void _onPanStart(DragStartDetails details) {
    if (widget.activeTool == PdfTool.pen) {
      setState(() {
        _currentStroke = DrawingStroke(
          points: [details.localPosition],
          color: widget.penColor,
          strokeWidth: widget.penWidth,
          isHighlighter: false,
        );
      });
    } else if (widget.activeTool == PdfTool.highlighter) {
      setState(() {
        _currentStroke = DrawingStroke(
          points: [details.localPosition],
          color: widget.highlighterColor,
          strokeWidth: widget.highlighterWidth,
          isHighlighter: true,
        );
      });
    } else if (widget.activeTool == PdfTool.eraser) {
      _eraseNear(details.localPosition);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke != null) {
      setState(() {
        _currentStroke!.points.add(details.localPosition);
      });
    } else if (widget.activeTool == PdfTool.eraser) {
      _eraseNear(details.localPosition);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null && _currentStroke!.points.isNotEmpty) {
      setState(() {
        widget.strokes.add(_currentStroke!);
        _currentStroke = null;
      });
      widget.onStateChanged();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.activeTool == PdfTool.textNote) {
      if (widget.onRequestAddNote != null) {
        widget.onRequestAddNote!(details.localPosition);
      } else {
        _showAddNoteDialog(details.localPosition);
      }
    } else if (widget.activeTool == PdfTool.eraser) {
      _eraseNear(details.localPosition);
    }
  }

  void _eraseNear(Offset pos) {
    const double radius = 18.0;
    bool modified = false;

    // Erase strokes
    widget.strokes.removeWhere((stroke) {
      for (final p in stroke.points) {
        if ((p - pos).distance <= radius + (stroke.strokeWidth / 2)) {
          modified = true;
          return true;
        }
      }
      return false;
    });

    // Erase notes
    widget.notes.removeWhere((note) {
      if ((note.position - pos).distance <= 35.0) {
        modified = true;
        return true;
      }
      return false;
    });

    if (modified) {
      setState(() {});
      widget.onStateChanged();
    }
  }

  Future<void> _showAddNoteDialog(Offset position) async {
    final controller = TextEditingController();
    final noteText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Color(0xFF0F5132)),
            SizedBox(width: 8),
            Text('Ajouter une note', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Écrivez votre note ou calcul ici...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F5132),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (noteText != null && noteText.isNotEmpty) {
      setState(() {
        widget.notes.add(
          TextNote(
            position: position,
            text: noteText,
          ),
        );
      });
      widget.onStateChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteracting = widget.activeTool != PdfTool.none;

    final canvasWidget = CustomPaint(
      painter: _DrawingPainter(
        strokes: widget.strokes,
        currentStroke: _currentStroke,
        notes: widget.notes,
      ),
      size: Size.infinite,
    );

    if (!isInteracting) {
      return IgnorePointer(
        ignoring: true,
        child: canvasWidget,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTapUp: _onTapUp,
      child: canvasWidget,
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final List<TextNote> notes;

  _DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.notes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Completed Strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // 2. Draw Active Stroke
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }

    // 3. Draw Text Notes
    for (final note in notes) {
      _drawTextNote(canvas, note);
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke;

    if (stroke.isHighlighter) {
      paint.color = stroke.color.withValues(alpha: 0.38);
    } else {
      paint.color = stroke.color;
    }

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint);
      return;
    }

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawTextNote(Canvas canvas, TextNote note) {
    final textSpan = TextSpan(
      text: note.text,
      style: const TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 220);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        note.position.dx,
        note.position.dy,
        textPainter.width + 16,
        textPainter.height + 12,
      ),
      const Radius.circular(8),
    );

    // Note shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rect.shift(const Offset(0, 2)), shadowPaint);

    // Note background
    final bgPaint = Paint()..color = note.color;
    canvas.drawRRect(rect, bgPaint);

    // Note border
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rect, borderPaint);

    // Pin icon hint
    final pinPaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawCircle(
      Offset(note.position.dx + 6, note.position.dy + 6),
      2.5,
      pinPaint,
    );

    // Note text
    textPainter.paint(
      canvas,
      Offset(note.position.dx + 8, note.position.dy + 6),
    );
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
