import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_language_service.dart';
import '../services/focus_sound_service.dart';
import '../services/focus_timer_service.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  final TextEditingController _taskController = TextEditingController();
  bool _isSilentModeActive = false;
  static const MethodChannel _soundChannel = MethodChannel('com.lyceemaroc.cours/sound');

  @override
  void initState() {
    super.initState();
    // Mark focus screen open so the floating mini-timer is hidden when in full view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FocusTimerService>().setFocusScreenOpen(true);
      }
    });
  }

  @override
  void dispose() {
    if (_isSilentModeActive) {
      try {
        _soundChannel.invokeMethod('toggleSilentMode', {'enable': false});
      } catch (_) {}
    }
    // Notify service that focus screen is closed so floating timer can appear on other screens
    // Using unmounted safe check
    try {
      FocusTimerService.navigatorKey.currentContext
          ?.read<FocusTimerService>()
          .setFocusScreenOpen(false);
    } catch (_) {}
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _toggleSilentMode(bool isArabic) async {
    final nextState = !_isSilentModeActive;
    setState(() {
      _isSilentModeActive = nextState;
    });

    try {
      final res = await _soundChannel.invokeMethod('toggleSilentMode', {'enable': nextState});
      if (!mounted) return;
      if (res == 'permission_needed') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'يرجى تفعيل صلاحية "عدم الإزعاج" للتطبيق في الإعدادات لكتم الإشعارات تلقائياً.'
                  : 'Veuillez accorder l\'accès "Ne pas déranger" pour couper les notifications.',
            ),
            backgroundColor: const Color(0xFF0F5132),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextState
                  ? (isArabic ? '🔕 تم تفعيل وضع الصامت بنجاح لن يزعجك أحد!' : '🔕 Mode Silencieux activé ! Aucune notification ne vous dérangera.')
                  : (isArabic ? '🔔 تم إيقاف وضع الصامت.' : '🔔 Mode sonore normal rétabli.'),
            ),
            backgroundColor: nextState ? const Color(0xFF0F5132) : Colors.blueGrey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextState
                ? (isArabic ? '🔕 تم تفعيل وضع الصامت في التطبيق.' : '🔕 Mode Silencieux activé dans l\'application.')
                : (isArabic ? '🔔 تم استعادة الصوت.' : '🔔 Mode normal rétabli.'),
          ),
          backgroundColor: const Color(0xFF0F5132),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleAddTask(FocusTimerService timerService) {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;
    timerService.addTask(text);
    _taskController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langService = context.watch<AppLanguageService>();
    final isArabic = langService.isArabic;
    final timerService = context.watch<FocusTimerService>();
    final soundService = context.watch<FocusSoundService>();

    final mediaQuery = MediaQuery.of(context);
    final bool isDesktop = kIsWeb
        ? mediaQuery.size.width >= 850
        : (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            mediaQuery.size.width >= 850);

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        timerService.setFocusScreenOpen(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? 'مساحة التركيز والإنتاجية' : 'Espace Mode Concentration',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            // Floating Mini-Timer quick toggle (Desktop only)
            if (isDesktop)
              Tooltip(
                message: isArabic
                    ? 'تفعيل / إخفاء العداد المصغر العائم'
                    : 'Afficher / Masquer le chrono flottant sur les cours',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.push_pin_rounded, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      isArabic ? 'عداد عائم' : 'Chrono Flottant',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: timerService.isFloatingEnabled,
                      activeThumbColor: const Color(0xFF0F5132),
                      onChanged: (val) => timerService.toggleFloatingEnabled(val),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

            // Reset Timer Button
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: isArabic ? 'إعادة ضبط العداد' : 'Réinitialiser le chrono',
              onPressed: timerService.resetTimer,
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: isDesktop
                ? _buildDesktopLayout(timerService, soundService, isDark, isArabic)
                : _buildMobileLayout(timerService, soundService, isDark, isArabic),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 16:9 DESKTOP PC WIDESCREEN LAYOUT (WEB & WINDOWS)
  // =========================================================================
  Widget _buildDesktopLayout(
    FocusTimerService timerService,
    FocusSoundService soundService,
    bool isDark,
    bool isArabic,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      children: [
        // --- TOP ROW: Revision Methods (2-2-1) + Big Glowing Chrono ---
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Half: Revision Methods in 2-2-1 structure
              Expanded(
                flex: 5,
                child: _buildDesktopMethodsColumn(timerService, isDark, isArabic),
              ),

              const SizedBox(width: 24),

              // Right Half: Glowing Chrono Card
              Expanded(
                flex: 5,
                child: _buildTimerCard(timerService, isDark, isArabic, isDesktop: true),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- BOTTOM ROW: Zen Ambient Sounds (50%) + Session To-Do Goals (50%) ---
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left 50%: Zen Ambient Sounds with 4 circular buttons on 1 line
              Expanded(
                flex: 5,
                child: _buildZenAmbientSoundCard(soundService, isDark, isArabic),
              ),

              const SizedBox(width: 24),

              // Right 50%: Session Objective Checklist
              Expanded(
                flex: 5,
                child: _buildGoalsChecklist(timerService, isDark, isArabic),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // =========================================================================
  // MOBILE SINGLE-COLUMN LAYOUT (PHONE)
  // =========================================================================
  Widget _buildMobileLayout(
    FocusTimerService timerService,
    FocusSoundService soundService,
    bool isDark,
    bool isArabic,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // 1. Revision Methods in 2-2-1 structure
        _buildMethods221Widget(timerService, isDark, isArabic),

        const SizedBox(height: 18),

        // 2. Glowing Chrono Card
        _buildTimerCard(timerService, isDark, isArabic, isDesktop: false),

        const SizedBox(height: 18),

        // 3. Zen Ambient Sounds with 4 circular buttons in 1 line
        _buildZenAmbientSoundCard(soundService, isDark, isArabic),

        const SizedBox(height: 18),

        // 4. Session Goals Checklist
        _buildGoalsChecklist(timerService, isDark, isArabic),

        // 5. Android Quiet Mode tip
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
          const SizedBox(height: 18),
          _buildAndroidQuietModeCard(isDark, isArabic),
        ],

        const SizedBox(height: 30),
      ],
    );
  }

  // =========================================================================
  // REVISION METHODS COLUMN (DESKTOP)
  // =========================================================================
  Widget _buildDesktopMethodsColumn(
    FocusTimerService timerService,
    bool isDark,
    bool isArabic,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5132).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded, color: Color(0xFF0F5132), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                isArabic ? 'طريقة المذاكرة والتركيز :' : 'Méthode de Révision :',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            timerService.selectedTechnique.localizedDesc(isArabic),
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white60 : Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // 2-2-1 Structure
          _buildMethods221Grid(timerService, isDark, isArabic),

          // Custom duration pickers if Custom technique is selected
          if (timerService.selectedTechnique == FocusTechnique.custom && !timerService.isRunning) ...[
            const SizedBox(height: 14),
            _buildCustomPickers(timerService, isDark, isArabic),
          ],

          const Spacer(),

          // Floating mini-timer banner / toggle
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF0F5132).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_in_picture_alt_rounded, size: 20, color: Color(0xFF0F5132)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'العداد العائم على الدروس' : 'Chrono flottant déplaçable',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isArabic
                            ? 'تابع الوقت المتبقي أثناء تصفح المواد والملخصات'
                            : 'Gardez un œil sur le temps pendant vos lectures de cours',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: timerService.isFloatingEnabled,
                  activeThumbColor: const Color(0xFF0F5132),
                  onChanged: (val) => timerService.toggleFloatingEnabled(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethods221Widget(
    FocusTimerService timerService,
    bool isDark,
    bool isArabic,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Color(0xFF0F5132), size: 20),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'طريقة التركيز :' : 'Méthode de Révision :',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            timerService.selectedTechnique.localizedDesc(isArabic),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),
          _buildMethods221Grid(timerService, isDark, isArabic),
          if (timerService.selectedTechnique == FocusTechnique.custom && !timerService.isRunning) ...[
            const SizedBox(height: 12),
            _buildCustomPickers(timerService, isDark, isArabic),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // 2 - 2 - 1 STRUCTURE GRID
  // =========================================================================
  Widget _buildMethods221Grid(
    FocusTimerService timerService,
    bool isDark,
    bool isArabic,
  ) {
    return Column(
      children: [
        // Row 1: Pomodoro (25/5 min) & Focus Profond (90/20 min)
        Row(
          children: [
            Expanded(
              child: _buildMethodCard(
                FocusTechnique.pomodoro25,
                timerService,
                isDark,
                isArabic,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMethodCard(
                FocusTechnique.ultradian90,
                timerService,
                isDark,
                isArabic,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Row 2: Pomodoro Étendu (50/10 min) & Personnalisé
        Row(
          children: [
            Expanded(
              child: _buildMethodCard(
                FocusTechnique.pomodoro50,
                timerService,
                isDark,
                isArabic,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMethodCard(
                FocusTechnique.custom,
                timerService,
                isDark,
                isArabic,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Row 3: Mode Libre (Flowtime) (1 card full width)
        _buildMethodCard(
          FocusTechnique.flowtime,
          timerService,
          isDark,
          isArabic,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildMethodCard(
    FocusTechnique tech,
    FocusTimerService timerService,
    bool isDark,
    bool isArabic, {
    bool isFullWidth = false,
  }) {
    final isSelected = timerService.selectedTechnique == tech;
    const emeraldColor = Color(0xFF0F5132);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => timerService.applyTechnique(tech),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? emeraldColor.withValues(alpha: 0.24) : emeraldColor.withValues(alpha: 0.08))
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? emeraldColor
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: emeraldColor.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Emoji / Icon circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? emeraldColor.withValues(alpha: 0.18)
                      : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  tech.iconEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 10),

              // Title and Badges
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tech.localizedShortTitle(isArabic),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        color: isSelected
                            ? (isDark ? Colors.white : emeraldColor)
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tech.localizedDurationBadge(isArabic),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Selected checkmark badge
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: emeraldColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // MAIN GLOWING TIMER CARD
  // =========================================================================
  Widget _buildTimerCard(
    FocusTimerService timerService,
    bool isDark,
    bool isArabic, {
    required bool isDesktop,
  }) {
    final isBreak = timerService.isRestPhase;
    final Color primaryColor = isBreak ? const Color(0xFF0284C7) : const Color(0xFF0F5132);
    final String phaseLabel = timerService.phaseLabel(isArabic);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 26 : 24,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF111C2E), const Color(0xFF172554)]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Phase Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              phaseLabel,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Circular Ring with Countdown/Stopwatch
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: isDesktop ? 210 : 200,
                height: isDesktop ? 210 : 200,
                child: CircularProgressIndicator(
                  value: timerService.progress,
                  strokeWidth: 11,
                  backgroundColor: primaryColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timerService.formattedTime,
                    style: TextStyle(
                      fontSize: isDesktop ? 48 : 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: timerService.isRunning ? primaryColor : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timerService.isRunning
                            ? (isArabic ? 'العداد يعمل' : 'Session active')
                            : (isArabic ? 'موقوف مؤقتاً' : 'En pause'),
                        style: TextStyle(
                          fontSize: 12,
                          color: timerService.isRunning ? primaryColor : Colors.grey,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Action Buttons: Play/Pause, Skip/Flowtime, Reset
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main Play / Pause Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                icon: Icon(timerService.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 26),
                label: Text(
                  timerService.isRunning
                      ? (isArabic ? 'إيقاف مؤقت' : 'Mettre en pause')
                      : (isArabic ? 'ابدأ الآن' : 'Démarrer'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: timerService.toggleTimer,
              ),

              const SizedBox(width: 10),

              // Skip or Flowtime Finish
              if (timerService.selectedTechnique == FocusTechnique.flowtime &&
                  !timerService.isRestPhase &&
                  timerService.flowtimeElapsedSeconds > 0)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.free_breakfast_rounded, size: 20),
                  label: Text(
                    isArabic ? 'أخذ استراحة' : 'Pause (÷ 5)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: timerService.finishFlowtimeSession,
                )
              else
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.skip_next_rounded, size: 20),
                  label: Text(
                    isArabic ? 'تخطي' : 'Passer',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: timerService.skipPhase,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CUSTOM TIME PICKERS
  // =========================================================================
  Widget _buildCustomPickers(
    FocusTimerService timerService,
    bool isDark,
    bool isArabic,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Focus minutes
          Column(
            children: [
              Text(
                isArabic ? 'التركيز (دقيقة)' : 'Travail (min)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: timerService.customFocusMinutes > 5
                        ? () => timerService.setCustomDurations(
                              timerService.customFocusMinutes - 5,
                              timerService.customRestMinutes,
                            )
                        : null,
                  ),
                  Text(
                    '${timerService.customFocusMinutes}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: timerService.customFocusMinutes < 180
                        ? () => timerService.setCustomDurations(
                              timerService.customFocusMinutes + 5,
                              timerService.customRestMinutes,
                            )
                        : null,
                  ),
                ],
              ),
            ],
          ),
          Container(width: 1, height: 38, color: Colors.grey[400]),
          // Rest minutes
          Column(
            children: [
              Text(
                isArabic ? 'الاستراحة (دقيقة)' : 'Repos (min)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: timerService.customRestMinutes > 1
                        ? () => timerService.setCustomDurations(
                              timerService.customFocusMinutes,
                              timerService.customRestMinutes - 1,
                            )
                        : null,
                  ),
                  Text(
                    '${timerService.customRestMinutes}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: timerService.customRestMinutes < 60
                        ? () => timerService.setCustomDurations(
                              timerService.customFocusMinutes,
                              timerService.customRestMinutes + 1,
                            )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ZEN AMBIENT SOUNDS CARD (4 CIRCULAR BUTTONS ON 1 HORIZONTAL LINE)
  // =========================================================================
  Widget _buildZenAmbientSoundCard(
    FocusSoundService soundService,
    bool isDark,
    bool isArabic,
  ) {
    const emeraldColor = Color(0xFF0F5132);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: emeraldColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.headphones_rounded, color: emeraldColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                isArabic ? 'أصوات الخلفية والاسترخاء :' : 'Ambiance Sonore Zen :',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (soundService.isPlaying)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.volume_up_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        isArabic ? 'مشغل' : 'En lecture',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isArabic
                ? 'اختر أجواء صوتية هادئة لعزل الضوضاء المحيطة وزيادة التركيز'
                : 'Choisissez une atmosphère sonore pour éliminer les bruits ambiants',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 18),

          // 4 Circular Buttons on a SINGLE Horizontal Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: AmbientSoundType.values.map((sound) {
              final isSelected = soundService.currentSound == sound;
              return _buildCircularSoundButton(
                sound: sound,
                isSelected: isSelected,
                soundService: soundService,
                isDark: isDark,
                isArabic: isArabic,
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          // Volume Slider
          Row(
            children: [
              const Icon(Icons.volume_down_rounded, size: 18, color: Colors.grey),
              Expanded(
                child: Slider(
                  value: soundService.volume,
                  activeColor: emeraldColor,
                  onChanged: (val) => soundService.setVolume(val),
                ),
              ),
              const Icon(Icons.volume_up_rounded, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${(soundService.volume * 100).round()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularSoundButton({
    required AmbientSoundType sound,
    required bool isSelected,
    required FocusSoundService soundService,
    required bool isDark,
    required bool isArabic,
  }) {
    const emeraldColor = Color(0xFF0F5132);

    String shortLabel;
    switch (sound) {
      case AmbientSoundType.none:
        shortLabel = isArabic ? 'صامت' : 'Silence';
        break;
      case AmbientSoundType.rain:
        shortLabel = isArabic ? 'مطر' : 'Pluie';
        break;
      case AmbientSoundType.cafe:
        shortLabel = isArabic ? 'مقهى' : 'Café';
        break;
      case AmbientSoundType.nature:
        shortLabel = isArabic ? 'طبيعة' : 'Forêt';
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => soundService.selectSound(sound),
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? emeraldColor
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                border: Border.all(
                  color: isSelected
                      ? emeraldColor
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  width: isSelected ? 2.5 : 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: emeraldColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                sound.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          shortLabel,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : emeraldColor)
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // SESSION GOALS CHECKLIST
  // =========================================================================
  Widget _buildGoalsChecklist(
    FocusTimerService timerService,
    bool isDark,
    bool isArabic,
  ) {
    const emeraldColor = Color(0xFF0F5132);
    final tasks = timerService.tasks;
    final completedCount = tasks.where((t) => t.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162032) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: emeraldColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.checklist_rounded, color: emeraldColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                isArabic ? 'أهداف جلسة المذاكرة :' : 'Objectifs de la Session :',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (tasks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: emeraldColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedCount / ${tasks.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: emeraldColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Add Task Input Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    hintText: isArabic
                        ? 'مثال : حل تمرين 1 إلى 4 في الرياضيات...'
                        : 'Ex : Exercices 1 à 4 de dérivation...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onSubmitted: (_) => _handleAddTask(timerService),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: emeraldColor),
                icon: const Icon(Icons.add_rounded),
                onPressed: () => _handleAddTask(timerService),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tasks List
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  isArabic
                      ? 'حدد أهدافك لهذه الجلسة لتحفيز إنجازك !'
                      : 'Fixez 1 à 3 objectifs concrets pour garder le cap durant cette session.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (ctx, index) {
                  final task = tasks[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: task.isCompleted,
                      activeColor: emeraldColor,
                      onChanged: (_) => timerService.toggleTask(task),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                      onPressed: () => timerService.deleteTask(task.id),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // ANDROID QUIET MODE HINT (MOBILE ONLY)
  // =========================================================================
  Widget _buildAndroidQuietModeCard(bool isDark, bool isArabic) {
    final activeColor = const Color(0xFF0F5132);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _toggleSilentMode(isArabic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? (_isSilentModeActive ? const Color(0xFF132A20) : const Color(0xFF1E293B))
              : (_isSilentModeActive ? const Color(0xFFE8F5E9) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isSilentModeActive
                ? activeColor
                : activeColor.withValues(alpha: isDark ? 0.35 : 0.20),
            width: _isSilentModeActive ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: _isSilentModeActive ? 0.18 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isSilentModeActive
                    ? activeColor
                    : activeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSilentModeActive
                    ? Icons.notifications_off_rounded
                    : Icons.notifications_active_outlined,
                color: _isSilentModeActive ? Colors.white : activeColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isArabic
                            ? 'وضع الصامت الفوري'
                            : 'Mode Silencieux (Zéro Distraction)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _isSilentModeActive
                              ? activeColor
                              : (isDark ? Colors.white10 : Colors.black12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isSilentModeActive
                              ? (isArabic ? 'مفعل ✓' : 'Actif ✓')
                              : (isArabic ? 'معطل' : 'Inactif'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _isSilentModeActive
                                ? Colors.white
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isArabic
                        ? 'كتم الإشعارات والمكالمات في هاتفك لضمان تركيز مطلق بدون أي إزعاج.'
                        : 'Coupe les notifications et sonneries pour ne pas être dérangé.',
                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Switch(
              value: _isSilentModeActive,
              activeThumbColor: activeColor,
              activeTrackColor: activeColor.withValues(alpha: 0.35),
              onChanged: (_) => _toggleSilentMode(isArabic),
            ),
          ],
        ),
      ),
    );
  }
}
