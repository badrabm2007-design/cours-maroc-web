import 'package:flutter/material.dart';

class CompactStickyNoteCard extends StatefulWidget {
  final int pageNumber;
  final ValueChanged<String> onSave;
  final VoidCallback onClose;
  final String initialText;
  final Color initialColor;

  const CompactStickyNoteCard({
    super.key,
    required this.pageNumber,
    required this.onSave,
    required this.onClose,
    this.initialText = '',
    this.initialColor = const Color(0xFFFEF08A),
  });

  static const List<Color> noteColors = [
    Color(0xFFFEF08A), // Soft Yellow
    Color(0xFFBBF7D0), // Soft Mint
    Color(0xFFBAE6FD), // Soft Sky
    Color(0xFFFED7AA), // Soft Peach
    Color(0xFFFBCFE8), // Soft Pink
  ];

  @override
  State<CompactStickyNoteCard> createState() => _CompactStickyNoteCardState();
}

class _CompactStickyNoteCardState extends State<CompactStickyNoteCard> {
  late final TextEditingController _controller;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSave(text);
    } else {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedColor.withValues(alpha: 0.8),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedColor.withValues(alpha: isDark ? 0.35 : 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sticky_note_2_rounded,
                    size: 18,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.pageNumber > 0
                          ? 'Note • Page '
                          : 'Ajouter une note',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  // Color picker dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: CompactStickyNoteCard.noteColors.map((color) {
                      final isSelected = color.toARGB32() == _selectedColor.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black87 : Colors.black26,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Text Input Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 2,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre note ou calcul ici...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : _selectedColor.withValues(alpha: 0.15),
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFB45309),
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 10),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.onClose,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: isDark ? Colors.white60 : Colors.black54,
                        ),
                        child: const Text('Annuler', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 15),
                        label: const Text(
                          'Épingler',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFF0F5132),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
