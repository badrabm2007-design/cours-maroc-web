import 'package:flutter/material.dart';
import 'pdf_drawing_canvas.dart';

class PdfAnnotationToolbar extends StatefulWidget {
  final PdfTool activeTool;
  final ValueChanged<PdfTool> onToolChanged;
  final Color penColor;
  final ValueChanged<Color> onPenColorChanged;
  final double penWidth;
  final ValueChanged<double> onPenWidthChanged;
  final Color highlighterColor;
  final ValueChanged<Color> onHighlighterColorChanged;
  final double highlighterWidth;
  final ValueChanged<double> onHighlighterWidthChanged;
  final VoidCallback onClearAll;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onTranslate;
  final bool hasAnnotations;
  final bool isVertical;
  final bool isDockedLeft;
  final bool isDockedInAppBar;
  final VoidCallback? onDetach;
  final VoidCallback? onClose;

  const PdfAnnotationToolbar({
    super.key,
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
    required this.onClearAll,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onTranslate,
    required this.hasAnnotations,
    this.isVertical = false,
    this.isDockedLeft = false,
    this.isDockedInAppBar = false,
    this.onDetach,
    this.onClose,
  });

  static const List<Color> penColors = [
    Color(0xFF0F172A), // Black / Dark
    Color(0xFF2563EB), // Blue
    Color(0xFFDC2626), // Red
    Color(0xFF16A34A), // Green
    Color(0xFF9333EA), // Purple
  ];

  static const List<Color> highlighterColors = [
    Color(0xFFFACC15), // Neon Yellow
    Color(0xFF4ADE80), // Neon Green
    Color(0xFF38BDF8), // Light Blue
    Color(0xFFF472B6), // Pink
    Color(0xFFFB923C), // Orange
  ];

  @override
  State<PdfAnnotationToolbar> createState() => _PdfAnnotationToolbarState();
}

class _PdfAnnotationToolbarState extends State<PdfAnnotationToolbar> {
  PdfTool? _activeOptionsTool;
  double _dockedDragDistanceY = 0.0;
  bool _isDetaching = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final containerContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isVertical ? 4 : 8,
        vertical: widget.isVertical ? 8 : (widget.isDockedInAppBar ? 3 : 4),
      ),
      decoration: BoxDecoration(
        color: widget.isDockedInAppBar
            ? (isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.75)
                : const Color(0xFFF1F5F9))
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(widget.isDockedInAppBar ? 10 : 14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
        boxShadow: widget.isDockedInAppBar
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: widget.isVertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildToolbarItems(context, isDark),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: _buildToolbarItems(context, isDark),
            ),
    );

    final toolbarBody = widget.isDockedInAppBar
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (_) {
              _dockedDragDistanceY = 0.0;
              _isDetaching = false;
            },
            onPanUpdate: (details) {
              if (_isDetaching) return;
              _dockedDragDistanceY += details.delta.dy;
              if (_dockedDragDistanceY > 0) {
                setState(() {});
                if (_dockedDragDistanceY >= 16.0) {
                  _isDetaching = true;
                  _dockedDragDistanceY = 0.0;
                  widget.onDetach?.call();
                }
              }
            },
            onPanEnd: (_) {
              if (!_isDetaching) {
                setState(() => _dockedDragDistanceY = 0.0);
              }
            },
            child: Transform.translate(
              offset: Offset(0, (_dockedDragDistanceY * 0.35).clamp(0.0, 6.0)),
              child: containerContent,
            ),
          )
        : containerContent;

    // If docked in AppBar, options are opened via floating showMenu popover!
    if (widget.isDockedInAppBar || _activeOptionsTool == null) {
      return toolbarBody;
    }

    final optionsPanel = _buildCompactOptionsPanel(isDark);

    if (widget.isVertical) {
      if (widget.isDockedLeft) {
        // Toolbar on the left, options to the right
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            toolbarBody,
            const SizedBox(width: 8),
            optionsPanel,
          ],
        );
      } else {
        // Toolbar on the right, options to the left
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            optionsPanel,
            const SizedBox(width: 8),
            toolbarBody,
          ],
        );
      }
    } else {
      // Horizontal toolbar, options attached underneath
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          toolbarBody,
          const SizedBox(height: 8),
          optionsPanel,
        ],
      );
    }
  }

  List<Widget> _buildToolbarItems(BuildContext context, bool isDark) {
    return [
      // Drag Handle / Detach button
      if (widget.isDockedInAppBar) ...[
        GestureDetector(
          onPanStart: (_) {
            _dockedDragDistanceY = 0.0;
            _isDetaching = false;
          },
          onPanUpdate: (details) {
            if (_isDetaching) return;
            _dockedDragDistanceY += details.delta.dy;
            if (_dockedDragDistanceY > 0) {
              setState(() {});
              if (_dockedDragDistanceY >= 16.0) {
                _isDetaching = true;
                _dockedDragDistanceY = 0.0;
                widget.onDetach?.call();
              }
            }
          },
          onPanEnd: (_) {
            if (!_isDetaching) {
              setState(() => _dockedDragDistanceY = 0.0);
            }
          },
          child: Tooltip(
            message: 'Tirer vers le bas pour détacher la barre',
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: widget.onDetach,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drag_indicator_rounded, size: 16, color: Color(0xFF64748B)),
                    SizedBox(width: 2),
                    Icon(Icons.open_with_rounded, size: 14, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ] else ...[
        MouseRegion(
          cursor: SystemMouseCursors.move,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isVertical ? 4 : 2,
              vertical: widget.isVertical ? 2 : 4,
            ),
            child: Icon(
              widget.isVertical
                  ? Icons.drag_handle_rounded
                  : Icons.drag_indicator_rounded,
              size: 16,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],

      _buildDivider(isDark),

      // 1. Navigation / Select Mode
      _buildToolButton(
        context: context,
        icon: Icons.pan_tool_alt_rounded,
        tooltip: 'Mode Lecture / Navigation',
        isSelected: widget.activeTool == PdfTool.none,
        onPressed: () {
          setState(() => _activeOptionsTool = null);
          widget.onToolChanged(PdfTool.none);
        },
      ),

      const SizedBox(width: 3, height: 3),

      // 2. Pen
      _buildPenButton(context),

      const SizedBox(width: 3, height: 3),

      // 3. Highlighter
      _buildHighlighterButton(context),

      const SizedBox(width: 3, height: 3),

      // 4. Eraser
      _buildToolButton(
        context: context,
        icon: Icons.auto_fix_normal_rounded,
        tooltip: 'Gomme (Effacer traits)',
        isSelected: widget.activeTool == PdfTool.eraser,
        onPressed: () {
          setState(() => _activeOptionsTool = null);
          widget.onToolChanged(
            widget.activeTool == PdfTool.eraser ? PdfTool.none : PdfTool.eraser,
          );
        },
      ),

      const SizedBox(width: 3, height: 3),

      // 5. Text Note
      _buildToolButton(
        context: context,
        icon: Icons.note_add_rounded,
        tooltip: 'Ajouter une note texte',
        isSelected: widget.activeTool == PdfTool.textNote,
        onPressed: () {
          setState(() => _activeOptionsTool = null);
          widget.onToolChanged(
            widget.activeTool == PdfTool.textNote
                ? PdfTool.none
                : PdfTool.textNote,
          );
        },
      ),

      _buildDivider(isDark),

      // 6. Zoom Out
      IconButton(
        icon: const Icon(Icons.zoom_out_rounded, size: 18),
        tooltip: 'Dézoomer',
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
        onPressed: widget.onZoomOut,
      ),

      const SizedBox(width: 3, height: 3),

      // 7. Zoom In
      IconButton(
        icon: const Icon(Icons.zoom_in_rounded, size: 18),
        tooltip: 'Zoomer',
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
        onPressed: widget.onZoomIn,
      ),

      _buildDivider(isDark),

      // 8. Translation Action Button
      if (widget.isVertical)
        IconButton(
          icon: const Icon(Icons.g_translate_rounded, size: 18, color: Color(0xFF2563EB)),
          tooltip: 'Traduire un texte',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          onPressed: widget.onTranslate,
        )
      else
        ElevatedButton.icon(
          icon: const Icon(Icons.g_translate_rounded, size: 14),
          label: const Text(
            'Traduire',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            minimumSize: const Size(0, 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          onPressed: widget.onTranslate,
        ),

      if (widget.hasAnnotations) ...[
        const SizedBox(width: 3, height: 3),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              size: 18, color: Colors.redAccent),
          tooltip: 'Effacer tous les dessins',
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          onPressed: widget.onClearAll,
        ),
      ],

      // 9. Close Button (re-docks to AppBar)
      if (!widget.isDockedInAppBar) ...[
        _buildDivider(isDark),

        if (widget.onClose != null)
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 17),
            tooltip: 'Replacer dans la barre en haut',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() => _activeOptionsTool = null);
              widget.onClose!();
            },
          ),
      ],
    ];
  }

  Widget _buildDivider(bool isDark) {
    if (widget.isVertical) {
      return Container(
        width: 20,
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 3),
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      );
    }
    return Container(
      height: 18,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  void _showDockedOptionsMenu(BuildContext btnContext, PdfTool tool) {
    final RenderBox? button = btnContext.findRenderObject() as RenderBox?;
    final OverlayState overlay = Overlay.of(context);
    if (button == null) return;

    final RenderBox overlayBox =
        overlay.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height + 4),
            ancestor: overlayBox),
        button.localToGlobal(button.size.bottomRight(const Offset(0, 4)),
            ancestor: overlayBox),
      ),
      Offset.zero & overlayBox.size,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showMenu(
      context: context,
      position: position,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (ctx, setMenuState) {
              return _buildCompactOptionsPanel(
                isDark,
                toolOverride: tool,
                onClosePopover: () => Navigator.of(ctx).pop(),
                onStateChanged: () {
                  setMenuState(() {});
                  setState(() {});
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPenButton(BuildContext context) {
    final isSelected = widget.activeTool == PdfTool.pen;
    final isOptionsOpen = _activeOptionsTool == PdfTool.pen;

    return Builder(
      builder: (btnContext) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (widget.isDockedInAppBar) {
              widget.onToolChanged(PdfTool.pen);
              _showDockedOptionsMenu(btnContext, PdfTool.pen);
            } else {
              if (isSelected) {
                setState(() {
                  _activeOptionsTool =
                      _activeOptionsTool == PdfTool.pen ? null : PdfTool.pen;
                });
              } else {
                widget.onToolChanged(PdfTool.pen);
                setState(() => _activeOptionsTool = PdfTool.pen);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.penColor.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? widget.penColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 17, color: widget.penColor),
                if (isSelected) ...[
                  const SizedBox(width: 1),
                  Icon(
                    isOptionsOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 13,
                    color: widget.penColor,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHighlighterButton(BuildContext context) {
    final isSelected = widget.activeTool == PdfTool.highlighter;
    final isOptionsOpen = _activeOptionsTool == PdfTool.highlighter;

    return Builder(
      builder: (btnContext) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (widget.isDockedInAppBar) {
              widget.onToolChanged(PdfTool.highlighter);
              _showDockedOptionsMenu(btnContext, PdfTool.highlighter);
            } else {
              if (isSelected) {
                setState(() {
                  _activeOptionsTool = _activeOptionsTool == PdfTool.highlighter
                      ? null
                      : PdfTool.highlighter;
                });
              } else {
                widget.onToolChanged(PdfTool.highlighter);
                setState(() => _activeOptionsTool = PdfTool.highlighter);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.highlighterColor.withValues(alpha: 0.28)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? widget.highlighterColor.withValues(alpha: 0.9)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.brush_rounded,
                    size: 17, color: widget.highlighterColor),
                if (isSelected) ...[
                  const SizedBox(width: 1),
                  Icon(
                    isOptionsOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 13,
                    color: widget.highlighterColor,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 17,
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  /// Compact popout attached directly to the toolbar
  Widget _buildCompactOptionsPanel(
    bool isDark, {
    PdfTool? toolOverride,
    VoidCallback? onClosePopover,
    VoidCallback? onStateChanged,
  }) {
    final currentTool = toolOverride ?? _activeOptionsTool;
    final isPen = currentTool == PdfTool.pen;
    final title = isPen ? 'Stylo' : 'Surligneur';
    final colors = isPen
        ? PdfAnnotationToolbar.penColors
        : PdfAnnotationToolbar.highlighterColors;
    final activeColor = isPen ? widget.penColor : widget.highlighterColor;
    final activeWidth = isPen ? widget.penWidth : widget.highlighterWidth;

    return Container(
      width: 205,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: () {
                  if (onClosePopover != null) {
                    onClosePopover();
                  } else {
                    setState(() => _activeOptionsTool = null);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded, size: 14),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 1. Color row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: colors.map((c) {
              final isChosen = c.toARGB32() == activeColor.toARGB32();
              return GestureDetector(
                onTap: () {
                  if (isPen) {
                    widget.onPenColorChanged(c);
                  } else {
                    widget.onHighlighterColorChanged(c);
                  }
                  onStateChanged?.call();
                },
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isChosen
                          ? Colors.white
                          : Colors.black.withValues(alpha: 0.15),
                      width: isChosen ? 2.5 : 1,
                    ),
                    boxShadow: isChosen
                        ? [
                            BoxShadow(
                              color: c.withValues(alpha: 0.6),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isChosen
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // 2. Stroke Width Selector with 3 circles (small, medium, large)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Épaisseur :',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Row(
                children: [
                  // Level 1: Fine (diameter 5)
                  _buildCircleSizeOption(
                    sizeDiameter: 5.0,
                    isSelected: isPen ? activeWidth <= 2.5 : activeWidth <= 8.0,
                    activeColor: activeColor,
                    isDark: isDark,
                    onTap: () {
                      if (isPen) {
                        widget.onPenWidthChanged(2.0);
                      } else {
                        widget.onHighlighterWidthChanged(8.0);
                      }
                      onStateChanged?.call();
                    },
                  ),
                  const SizedBox(width: 8),

                  // Level 2: Medium (diameter 9)
                  _buildCircleSizeOption(
                    sizeDiameter: 9.0,
                    isSelected: isPen
                        ? (activeWidth > 2.5 && activeWidth <= 5.0)
                        : (activeWidth > 8.0 && activeWidth <= 15.0),
                    activeColor: activeColor,
                    isDark: isDark,
                    onTap: () {
                      if (isPen) {
                        widget.onPenWidthChanged(4.0);
                      } else {
                        widget.onHighlighterWidthChanged(14.0);
                      }
                      onStateChanged?.call();
                    },
                  ),
                  const SizedBox(width: 8),

                  // Level 3: Thick (diameter 14)
                  _buildCircleSizeOption(
                    sizeDiameter: 14.0,
                    isSelected: isPen ? activeWidth > 5.0 : activeWidth > 15.0,
                    activeColor: activeColor,
                    isDark: isDark,
                    onTap: () {
                      if (isPen) {
                        widget.onPenWidthChanged(7.0);
                      } else {
                        widget.onHighlighterWidthChanged(22.0);
                      }
                      onStateChanged?.call();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleSizeOption({
    required double sizeDiameter,
    required bool isSelected,
    required Color activeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.white24 : Colors.black12),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: sizeDiameter,
          height: sizeDiameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activeColor,
          ),
        ),
      ),
    );
  }
}
