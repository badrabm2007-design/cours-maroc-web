import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_language_service.dart';
import '../services/focus_timer_service.dart';
import '../screens/focus_mode_screen.dart';

/// Top-level overlay wrapper for MaterialApp.builder
class FocusTimerOverlayWrapper extends StatefulWidget {
  final Widget child;

  const FocusTimerOverlayWrapper({super.key, required this.child});

  @override
  State<FocusTimerOverlayWrapper> createState() => _FocusTimerOverlayWrapperState();
}

class _FocusTimerOverlayWrapperState extends State<FocusTimerOverlayWrapper> {
  FocusTimerService? _timerService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newService = context.read<FocusTimerService>();
    if (_timerService != newService) {
      _timerService?.phaseFinishNotifier.removeListener(_onPhaseFinished);
      _timerService = newService;
      _timerService?.phaseFinishNotifier.addListener(_onPhaseFinished);
    }
  }

  @override
  void dispose() {
    _timerService?.phaseFinishNotifier.removeListener(_onPhaseFinished);
    super.dispose();
  }

  void _onPhaseFinished() {
    final event = _timerService?.phaseFinishNotifier.value;
    if (event == null || !mounted) return;

    final navContext = FocusTimerService.navigatorKey.currentContext ?? context;
    final isArabic = navContext.mounted ? navContext.read<AppLanguageService>().isArabic : false;

    showDialog(
      context: navContext,
      barrierDismissible: true,
      builder: (ctx) {
        final isBreak = event.isBreak;
        final primaryColor = isBreak ? const Color(0xFF0284C7) : const Color(0xFF0F5132);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Text(isBreak ? '🎉' : '⚡', style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isBreak
                      ? (isArabic ? 'انتهت جلسة التركيز !' : 'Bravo, session terminée !')
                      : (isArabic ? 'انتهت الاستراحة !' : 'Fin de la pause !'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            isBreak
                ? (isArabic
                    ? 'لقد أنهيت وقت المذاكرة بنجاح. حان وقت استراحة مستحقة لمدة ${event.durationMinutes} دقيقة.'
                    : 'Vous avez brillamment travaillé. Prenez une pause méritée de ${event.durationMinutes} minutes pour vous détendre.')
                : (isArabic
                    ? 'هل أنت مستعد للانطلاق في جولة تركيز وإنتاجية جديدة ؟'
                    : 'Êtes-vous prêt(e) pour une nouvelle session de concentration productive ?'),
            style: const TextStyle(fontSize: 14.5, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                isArabic ? 'إغلاق' : 'Fermer',
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _timerService?.startTimer();
              },
              child: Text(
                isBreak
                    ? (isArabic ? 'بدء الاستراحة' : 'Démarrer la pause')
                    : (isArabic ? 'بدء التركيز' : 'Démarrer le travail'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final bool isDesktop = kIsWeb
        ? (mediaQuery != null && mediaQuery.size.width >= 900)
        : (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    return Stack(
      children: [
        widget.child,
        if (isDesktop) const FloatingFocusTimerBadge(),
      ],
    );
  }
}

/// Draggable and magnetic floating mini-timer badge for PC (Web & Windows)
/// Can dock magnetically in the top AppBar of all screens like iron to a magnet!
class FloatingFocusTimerBadge extends StatefulWidget {
  const FloatingFocusTimerBadge({super.key});

  @override
  State<FloatingFocusTimerBadge> createState() => _FloatingFocusTimerBadgeState();
}

class _FloatingFocusTimerBadgeState extends State<FloatingFocusTimerBadge> {
  // Ultra-compact dimensions: no blank voids, fits cleanly inside any 56px AppBar!
  static const double _badgeWidth = 168.0;
  static const double _badgeHeight = 36.0;

  Offset? _position;
  ActiveDockingScreen? _lastActiveScreen;
  bool? _lastHasCorriges;
  bool _isFreeFloating = false;
  final Map<ActiveDockingScreen, Offset> _screenDockedOffsets = {};

  bool _checkIsDocked(ActiveDockingScreen screen, Offset pos) {
    if (screen == ActiveDockingScreen.subjectDetail) {
      return (pos.dy - 70.0).abs() <= 15;
    }
    return pos.dy <= 45 || (pos.dy - 65.0).abs() <= 10;
  }

  Offset _defaultDockPositionFor(
    ActiveDockingScreen screen,
    Size screenSize,
    bool hasCorriges,
  ) {
    final double screenW = screenSize.width;

    switch (screen) {
      case ActiveDockingScreen.home:
        const double dockY = 9.0;
        const double minSlotX = 350.0;
        final double rightBoundary = kIsWeb ? 580.0 : 440.0;
        final double maxSlotX = screenW - rightBoundary - _badgeWidth;
        if (minSlotX <= maxSlotX) {
          return const Offset(minSlotX, dockY);
        } else {
          final double fallbackX = (screenW - _badgeWidth) / 2;
          return Offset(fallbackX.clamp(180.0, (screenW - _badgeWidth - 16.0).clamp(180.0, 9999.0)), dockY);
        }

      case ActiveDockingScreen.pdfViewer:
        const double dockY = 9.0;
        final double minSlotX = (screenW / 2) + 20.0;
        final double maxSlotX = screenW - 260.0 - _badgeWidth;
        if (minSlotX <= maxSlotX) {
          return Offset(minSlotX, dockY);
        } else {
          final double fallbackX = (screenW - _badgeWidth - 180.0).clamp(180.0, 9999.0);
          return Offset(fallbackX, dockY);
        }

      case ActiveDockingScreen.subjectDetail:
        const double dockY = 70.0;
        final double chipSpan = hasCorriges ? 220.0 : 135.0;
        final double chipsRight = (screenW / 2) + chipSpan;
        final double rightSlotX = chipsRight + 16.0;
        final double maxRightX = screenW - _badgeWidth - 16.0;

        if (maxRightX >= rightSlotX) {
          return Offset(maxRightX, dockY);
        } else {
          final double chipsLeft = (screenW / 2) - chipSpan;
          final double maxLeftX = chipsLeft - _badgeWidth - 16.0;
          if (maxLeftX >= 16.0) {
            return const Offset(16.0, dockY);
          } else {
            return Offset(maxRightX.clamp(16.0, 9999.0), dockY);
          }
        }

      case ActiveDockingScreen.orientation:
        const double dockY = 9.0;
        const double minSlotX = 330.0;
        final double maxSlotX = screenW - 430.0 - _badgeWidth;
        if (minSlotX <= maxSlotX) {
          return const Offset(minSlotX, dockY);
        } else {
          final double fallbackX = (screenW - _badgeWidth) / 2;
          return Offset(fallbackX.clamp(180.0, (screenW - _badgeWidth - 16.0).clamp(180.0, 9999.0)), dockY);
        }

      case ActiveDockingScreen.other:
        return const Offset(60.0, 9.0);
    }
  }

  Offset _computeDockedPosition({
    required ActiveDockingScreen screen,
    required Offset currentPos,
    required Size screenSize,
    required bool hasCorriges,
  }) {
    final double screenW = screenSize.width;

    switch (screen) {
      case ActiveDockingScreen.subjectDetail:
        // Top row (Y = 0..64) is STRICTLY FORBIDDEN.
        // Dock into lower filter bar at Y = 70.0 in the empty space outside filter pills.
        const double dockY = 70.0;
        final double chipSpan = hasCorriges ? 220.0 : 135.0;
        final double chipsLeft = (screenW / 2) - chipSpan;
        final double chipsRight = (screenW / 2) + chipSpan;

        final double maxLeftSlot = chipsLeft - _badgeWidth - 12.0;
        final double minRightSlot = chipsRight + 12.0;
        final double maxRightSlot = screenW - _badgeWidth - 16.0;

        double finalX;
        if (currentPos.dx + (_badgeWidth / 2) < (screenW / 2)) {
          // Snap to left slot
          if (maxLeftSlot >= 16.0) {
            finalX = currentPos.dx.clamp(16.0, maxLeftSlot);
          } else {
            finalX = currentPos.dx.clamp(minRightSlot, maxRightSlot.clamp(minRightSlot, screenW));
          }
        } else {
          // Snap to right slot
          if (maxRightSlot >= minRightSlot) {
            finalX = currentPos.dx.clamp(minRightSlot, maxRightSlot);
          } else {
            finalX = currentPos.dx.clamp(16.0, maxLeftSlot.clamp(16.0, screenW));
          }
        }
        return Offset(finalX, dockY);

      case ActiveDockingScreen.pdfViewer:
        // Dock in AppBar row (Y = 9.0)
        const double dockY = 9.0;
        final double minSlotX = (screenW / 2) + 20.0;
        final double maxSlotX = screenW - 260.0 - _badgeWidth;
        if (minSlotX <= maxSlotX) {
          return Offset(currentPos.dx.clamp(minSlotX, maxSlotX), dockY);
        } else {
          final double fallbackX = (screenW - _badgeWidth - 180.0).clamp(180.0, 9999.0);
          return Offset(fallbackX, dockY);
        }

      case ActiveDockingScreen.home:
        const double dockY = 9.0;
        const double minSlotX = 350.0;
        final double rightBoundary = kIsWeb ? 580.0 : 440.0;
        final double maxSlotX = screenW - rightBoundary - _badgeWidth;

        if (minSlotX <= maxSlotX) {
          final double finalX = currentPos.dx.clamp(minSlotX, maxSlotX);
          return Offset(finalX, dockY);
        } else {
          final double fallbackX = (screenW - _badgeWidth) / 2;
          return Offset(fallbackX.clamp(180.0, (screenW - _badgeWidth - 16.0).clamp(180.0, 9999.0)), dockY);
        }

      case ActiveDockingScreen.orientation:
        const double dockY = 9.0;
        const double minSlotX = 330.0;
        final double maxSlotX = screenW - 430.0 - _badgeWidth;

        if (minSlotX <= maxSlotX) {
          final double finalX = currentPos.dx.clamp(minSlotX, maxSlotX);
          return Offset(finalX, dockY);
        } else {
          final double fallbackX = (screenW - _badgeWidth) / 2;
          return Offset(fallbackX.clamp(180.0, (screenW - _badgeWidth - 16.0).clamp(180.0, 9999.0)), dockY);
        }

      case ActiveDockingScreen.other:
        const double dockY = 9.0;
        return Offset(currentPos.dx.clamp(60.0, screenW - _badgeWidth - 60.0), dockY);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerService = context.watch<FocusTimerService>();

    // Hide if disabled by user or if the student is currently inside FocusModeScreen
    if (!timerService.isFloatingEnabled || timerService.isFocusScreenOpen) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeScreen = timerService.activeDockingScreen;
    final hasCorriges = timerService.subjectDetailHasCorriges;

    // Detect screen or filter state changes: adapt docking to the active screen
    if (_lastActiveScreen != activeScreen || _lastHasCorriges != hasCorriges) {
      _lastActiveScreen = activeScreen;
      _lastHasCorriges = hasCorriges;

      // Always adapt to the newly active screen's dedicated docking slot!
      // This guarantees that leaving SubjectDetailScreen (dockY=70) resets position cleanly to Y=9 on HomeScreen,
      // and leaving PdfViewerScreen cleanly adopts HomeScreen's designated slot.
      final preferred = _screenDockedOffsets[activeScreen] ??
          _defaultDockPositionFor(activeScreen, screenSize, hasCorriges);
      _position = _computeDockedPosition(
        screen: activeScreen,
        currentPos: preferred,
        screenSize: screenSize,
        hasCorriges: hasCorriges,
      );
      _isFreeFloating = false;
    }

    // Default position: magnetically docked according to active screen
    _position ??= _defaultDockPositionFor(activeScreen, screenSize, hasCorriges);

    // Keep clamped inside screen bounds
    final clampedX = _position!.dx.clamp(8.0, (screenSize.width - _badgeWidth - 8.0).clamp(8.0, 9999.0));
    final clampedY = _position!.dy.clamp(6.0, (screenSize.height - _badgeHeight - 8.0).clamp(6.0, 9999.0));
    _position = Offset(clampedX, clampedY);

    final isBreak = timerService.isRestPhase;
    final primaryColor = isBreak ? const Color(0xFF0284C7) : const Color(0xFF0F5132);

    final bool isDocked = !_isFreeFloating && _checkIsDocked(activeScreen, _position!);

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position!.dx + details.delta.dx,
              _position!.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (details) {
          double finalX = _position!.dx;
          double finalY = _position!.dy;

          if (activeScreen == ActiveDockingScreen.subjectDetail) {
            // SubjectDetailScreen: Top row (0..64) is FORBIDDEN.
            // If dragged near header (Y < 115), snap to filter bar (Y = 70) outside filter pills!
            if (finalY < 115.0) {
              final docked = _computeDockedPosition(
                screen: activeScreen,
                currentPos: Offset(finalX, finalY),
                screenSize: screenSize,
                hasCorriges: hasCorriges,
              );
              finalX = docked.dx;
              finalY = docked.dy;
              _isFreeFloating = false;
              _screenDockedOffsets[activeScreen] = Offset(finalX, finalY);
            } else {
              // Free movement in body
              _isFreeFloating = true;
              if (finalX > screenSize.width - _badgeWidth - 40) {
                finalX = screenSize.width - _badgeWidth - 12.0;
              } else if (finalX < 40) {
                finalX = 12.0;
              }
            }
          } else {
            // HomeScreen / PdfViewerScreen / OrientationScreen / Other:
            if (finalY < 60.0) {
              final docked = _computeDockedPosition(
                screen: activeScreen,
                currentPos: Offset(finalX, finalY),
                screenSize: screenSize,
                hasCorriges: hasCorriges,
              );
              finalX = docked.dx;
              finalY = docked.dy;
              _isFreeFloating = false;
              _screenDockedOffsets[activeScreen] = Offset(finalX, finalY);
            } else {
              // Free movement in body
              _isFreeFloating = true;
              if (finalX > screenSize.width - _badgeWidth - 40) {
                finalX = screenSize.width - _badgeWidth - 12.0;
              } else if (finalX < 40) {
                finalX = 12.0;
              }
            }
          }

          setState(() {
            _position = Offset(finalX, finalY);
          });
        },
        child: Material(
          type: MaterialType.transparency,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: _badgeWidth,
            height: _badgeHeight,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? (isDocked ? const Color(0xFF162032) : const Color(0xFF1E293B))
                  : (isDocked ? const Color(0xFFF8FAFC) : Colors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDocked
                    ? primaryColor.withValues(alpha: 0.5)
                    : primaryColor.withValues(alpha: 0.75),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDocked ? 0.12 : 0.22),
                  blurRadius: isDocked ? 8 : 14,
                  offset: isDocked ? const Offset(0, 2) : const Offset(0, 4),
                ),
                if (!isDocked)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Drag handle icon (subtle, clearly indicates draggable)
                MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 3),

                // 2. State Dot Indicator (pulse active color)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: timerService.isRunning ? primaryColor : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),

                // 3. Compact Countdown Time (no giant blank space!)
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _openFocusScreen(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: Text(
                      timerService.formattedTime,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: primaryColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // 4. Quick Play / Pause Button (No blocking tooltip overlay!)
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: timerService.toggleTimer,
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Icon(
                      timerService.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                // 5. Expand to Full Screen Button (No blocking tooltip overlay!)
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _openFocusScreen(context),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                // 6. Close / Dismiss Button (No blocking tooltip overlay!)
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => timerService.toggleFloatingEnabled(false),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openFocusScreen(BuildContext context) {
    final navContext = FocusTimerService.navigatorKey.currentContext ?? context;
    Navigator.of(navContext).push(
      MaterialPageRoute(builder: (_) => const FocusModeScreen()),
    );
  }
}
