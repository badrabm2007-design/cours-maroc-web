import 'package:flutter/material.dart';

class DraggableNote {
  final String id;
  Offset position;
  String text;
  Color color;
  bool isExpanded;
  bool isEditing;

  DraggableNote({
    required this.id,
    required this.position,
    required this.text,
    this.color = const Color(0xFFFEF08A),
    this.isExpanded = true,
    this.isEditing = false,
  });

  static const List<Color> pastelColors = [
    Color(0xFFFEF08A), // Soft Yellow
    Color(0xFFBBF7D0), // Soft Mint Green
    Color(0xFFBAE6FD), // Soft Sky Blue
    Color(0xFFFED7AA), // Soft Peach
    Color(0xFFFBCFE8), // Soft Pink
  ];
}

class DraggableStickyNoteWidget extends StatefulWidget {
  final DraggableNote note;
  final ValueChanged<Offset> onPositionChanged;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onDelete;
  final BoxConstraints screenConstraints;

  const DraggableStickyNoteWidget({
    super.key,
    required this.note,
    required this.onPositionChanged,
    required this.onTextChanged,
    required this.onColorChanged,
    required this.onDelete,
    required this.screenConstraints,
  });

  @override
  State<DraggableStickyNoteWidget> createState() =>
      _DraggableStickyNoteWidgetState();
}

class _DraggableStickyNoteWidgetState extends State<DraggableStickyNoteWidget> {
  late TextEditingController _editController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.note.text);
  }

  @override
  void didUpdateWidget(covariant DraggableStickyNoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.text != widget.note.text && !widget.note.isEditing) {
      _editController.text = widget.note.text;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _saveEdit() {
    final newText = _editController.text.trim();
    if (newText.isNotEmpty) {
      widget.onTextChanged(newText);
    }
    setState(() {
      widget.note.isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final maxW = widget.screenConstraints.maxWidth;
    final maxH = widget.screenConstraints.maxHeight;

    final double posX = note.position.dx.clamp(4.0, (maxW - 120.0).clamp(4.0, double.infinity));
    final double posY = note.position.dy.clamp(4.0, (maxH - 80.0).clamp(4.0, double.infinity));

    if (!note.isExpanded && !_isHovered) {
      // Collapsed chip mode
      return Positioned(
        left: posX,
        top: posY,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onPanUpdate: (details) {
              widget.onPositionChanged(Offset(
                (posX + details.delta.dx).clamp(4.0, maxW - 120.0),
                (posY + details.delta.dy).clamp(4.0, maxH - 50.0),
              ));
            },
            onTap: () {
              setState(() => note.isExpanded = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: note.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.2),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.push_pin_rounded,
                    size: 14,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      note.text.replaceAll('\n', ' '),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Expanded Post-it Note Card
    return Positioned(
      left: posX,
      top: posY,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          width: 230,
          decoration: BoxDecoration(
            color: note.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Drag Handle, Color picker, Actions
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  widget.onPositionChanged(Offset(
                    (posX + details.delta.dx).clamp(4.0, maxW - 235.0),
                    (posY + details.delta.dy).clamp(4.0, maxH - 120.0),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.move,
                        child: const Icon(
                          Icons.drag_indicator_rounded,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.push_pin_rounded,
                        size: 13,
                        color: Color(0xFFB45309),
                      ),
                      const Spacer(),
                      // Color dots popup menu
                      PopupMenuButton<Color>(
                        tooltip: 'Changer la couleur',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: note.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black45,
                              width: 1,
                            ),
                          ),
                        ),
                        onSelected: (c) => widget.onColorChanged(c),
                        itemBuilder: (ctx) => DraggableNote.pastelColors.map((c) {
                          return PopupMenuItem(
                            value: c,
                            height: 32,
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: c,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black26),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c == const Color(0xFFFEF08A)
                                      ? 'Jaune'
                                      : c == const Color(0xFFBBF7D0)
                                          ? 'Menthe'
                                          : c == const Color(0xFFBAE6FD)
                                              ? 'Bleu'
                                              : c == const Color(0xFFFED7AA)
                                                  ? 'Pêche'
                                                  : 'Rose',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(width: 4),
                      // Edit button
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () {
                          if (note.isEditing) {
                            _saveEdit();
                          } else {
                            setState(() => note.isEditing = true);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            note.isEditing
                                ? Icons.check_rounded
                                : Icons.edit_outlined,
                            size: 15,
                            color: note.isEditing
                                ? const Color(0xFF0F5132)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Collapse button
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () {
                          setState(() {
                            note.isExpanded = false;
                            _isHovered = false;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.unfold_less_rounded,
                            size: 15,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Delete button
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: widget.onDelete,
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content: Readable Text or In-place Editor
              Padding(
                padding: const EdgeInsets.all(10),
                child: note.isEditing
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _editController,
                            maxLines: 4,
                            autofocus: true,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                              height: 1.35,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.all(6),
                              border: OutlineInputBorder(),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F5132),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                minimumSize: const Size(0, 26),
                                textStyle: const TextStyle(fontSize: 11.5),
                              ),
                              onPressed: _saveEdit,
                              child: const Text('Enregistrer'),
                            ),
                          ),
                        ],
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            note.text,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
