import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_language_service.dart';
import '../services/focus_timer_service.dart';
import '../services/user_profile_service.dart';
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

  // Global static offset so the timer keeps its exact position across the entire session!
  static Offset? _persistedPosition;
  bool _isDragging = false;

  bool _checkIsDocked(Offset pos) {
    return pos.dy <= 45;
  }

  @override
  Widget build(BuildContext context) {
    final timerService = context.watch<FocusTimerService>();
    final userProfile = context.watch<UserProfileService>();

    // Hide if student hasn't selected their grade yet (first page / welcome screen),
    // or if grade selection is active, or if disabled by user, or if focus screen is open
    if (!userProfile.hasSelectedGrade ||
        timerService.isGradeSelectionActive ||
        !timerService.isFloatingEnabled ||
        timerService.isFocusScreenOpen) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Stable default position: docked comfortably at bottom-right
    // Never conflicts with top navigation, title or search bar on any screen
    if (_persistedPosition == null) {
      final double defaultX = (screenSize.width - _badgeWidth - 24.0).clamp(16.0, screenSize.width - _badgeWidth - 16.0);
      final double defaultY = (screenSize.height - _badgeHeight - 24.0).clamp(16.0, screenSize.height - _badgeHeight - 16.0);
      _persistedPosition = Offset(defaultX, defaultY);
    }

    // Keep clamped inside screen bounds if window was resized
    final clampedX = _persistedPosition!.dx.clamp(8.0, (screenSize.width - _badgeWidth - 8.0).clamp(8.0, 9999.0));
    final clampedY = _persistedPosition!.dy.clamp(6.0, (screenSize.height - _badgeHeight - 8.0).clamp(6.0, 9999.0));
    _persistedPosition = Offset(clampedX, clampedY);

    final isBreak = timerService.isRestPhase;
    final primaryColor = isBreak ? const Color(0xFF0284C7) : const Color(0xFF0F5132);
    final bool isDocked = _checkIsDocked(_persistedPosition!);

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      left: _persistedPosition!.dx,
      top: _persistedPosition!.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _persistedPosition = Offset(
              _persistedPosition!.dx + details.delta.dx,
              _persistedPosition!.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
            double finalX = _persistedPosition!.dx.clamp(12.0, screenSize.width - _badgeWidth - 12.0);
            double finalY = _persistedPosition!.dy;

            // Magnetic snap to top row if dragged near header
            if (finalY < 55.0) {
              finalY = 10.0;
            } else if (finalY > screenSize.height - _badgeHeight - 20.0) {
              finalY = screenSize.height - _badgeHeight - 16.0;
            }
            _persistedPosition = Offset(finalX, finalY);
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
      MaterialPageRoute(
        settings: const RouteSettings(name: '/concentration'),
        builder: (_) => const FocusModeScreen(),
      ),
    );
  }
}
