import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FocusTechnique {
  pomodoro25,
  ultradian90,
  pomodoro50,
  custom,
  flowtime,
}

enum ActiveDockingScreen {
  home,
  subjectDetail,
  pdfViewer,
  orientation,
  other,
}

extension FocusTechniqueExt on FocusTechnique {
  String localizedName(bool isArabic) {
    switch (this) {
      case FocusTechnique.pomodoro25:
        return isArabic ? 'بومودورو (25/5 د)' : 'Pomodoro (25/5 min)';
      case FocusTechnique.ultradian90:
        return isArabic ? 'تركيز عميق (90/20 د)' : 'Focus Profond (90/20 min)';
      case FocusTechnique.pomodoro50:
        return isArabic ? 'بومودورو ممتد (50/10 د)' : 'Pomodoro Étendu (50/10 min)';
      case FocusTechnique.custom:
        return isArabic ? 'مخصص' : 'Personnalisé';
      case FocusTechnique.flowtime:
        return isArabic ? 'النمط الحر (فلو تايم)' : 'Mode Libre (Flowtime)';
    }
  }

  String localizedShortTitle(bool isArabic) {
    switch (this) {
      case FocusTechnique.pomodoro25:
        return isArabic ? 'بومودورو كلاسيكي' : 'Pomodoro Classique';
      case FocusTechnique.ultradian90:
        return isArabic ? 'تركيز فائق العمق' : 'Focus Profond';
      case FocusTechnique.pomodoro50:
        return isArabic ? 'بومودورو ممتد' : 'Pomodoro Étendu';
      case FocusTechnique.custom:
        return isArabic ? 'تخصيص حر' : 'Personnalisé';
      case FocusTechnique.flowtime:
        return isArabic ? 'نمط فلو تايم' : 'Mode Libre (Flowtime)';
    }
  }

  String localizedDurationBadge(bool isArabic) {
    switch (this) {
      case FocusTechnique.pomodoro25:
        return isArabic ? '25 د عمل + 5 د راحة' : '25 min travail + 5 min pause';
      case FocusTechnique.ultradian90:
        return isArabic ? '90 د مكثف + 20 د راحة' : '90 min intense + 20 min pause';
      case FocusTechnique.pomodoro50:
        return isArabic ? '50 د عمل + 10 د راحة' : '50 min travail + 10 min pause';
      case FocusTechnique.custom:
        return isArabic ? 'أوقات قابلة للتعديل' : 'Durées sur-mesure ajustables';
      case FocusTechnique.flowtime:
        return isArabic ? 'بدون قيود • استراحة تلقائية' : 'Chrono libre • Pause auto (÷ 5)';
    }
  }

  String localizedDesc(bool isArabic) {
    switch (this) {
      case FocusTechnique.pomodoro25:
        return isArabic
            ? '25 دقيقة تركيز تليها 5 دقائق استراحة لتجديد النشاط الذهني'
            : '25 min de révision rythmée + 5 min de pause pour recharger les batteries';
      case FocusTechnique.ultradian90:
        return isArabic
            ? '90 دقيقة تركيز مكثف تليها 20 دقيقة استراحة وفق الدورة البيولوجية'
            : '90 min de travail en immersion + 20 min de pause selon le cycle ultradien';
      case FocusTechnique.pomodoro50:
        return isArabic
            ? '50 دقيقة تركيز و10 دقائق استراحة للمشاريع الطويلة'
            : '50 min de travail soutenu + 10 min de pause pour les chapitres denses';
      case FocusTechnique.custom:
        return isArabic
            ? 'حدد مدة التركيز والاستراحة بدقة بحسب احتياجك'
            : 'Ajustez librement les durées de concentration et de repos selon vos besoins';
      case FocusTechnique.flowtime:
        return isArabic
            ? 'ركز بدون قيود زمنية. عند التوقف، تحسب الاستراحة تلقائياً (المدة ÷ 5)'
            : 'Concentration sans limite de temps. La pause est calculée automatiquement (Temps ÷ 5)';
    }
  }

  String get iconEmoji {
    switch (this) {
      case FocusTechnique.pomodoro25:
        return '🍅';
      case FocusTechnique.ultradian90:
        return '🧠';
      case FocusTechnique.pomodoro50:
        return '⏳';
      case FocusTechnique.custom:
        return '⚙️';
      case FocusTechnique.flowtime:
        return '🌊';
    }
  }

  int get defaultFocusMinutes {
    switch (this) {
      case FocusTechnique.pomodoro25:
        return 25;
      case FocusTechnique.ultradian90:
        return 90;
      case FocusTechnique.pomodoro50:
        return 50;
      case FocusTechnique.custom:
        return 35;
      case FocusTechnique.flowtime:
        return 0;
    }
  }

  int get defaultRestMinutes {
    switch (this) {
      case FocusTechnique.pomodoro25:
        return 5;
      case FocusTechnique.ultradian90:
        return 20;
      case FocusTechnique.pomodoro50:
        return 10;
      case FocusTechnique.custom:
        return 7;
      case FocusTechnique.flowtime:
        return 0;
    }
  }
}

class FocusTaskItem {
  final String id;
  String title;
  bool isCompleted;

  FocusTaskItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory FocusTaskItem.fromJson(Map<String, dynamic> json) => FocusTaskItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class PhaseFinishEvent {
  final bool isBreak;
  final int durationMinutes;
  final DateTime timestamp;

  PhaseFinishEvent({
    required this.isBreak,
    required this.durationMinutes,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class FocusTimerService extends ChangeNotifier {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const String _prefKeyTasks = 'focus_mode_tasks_v2';
  static const String _prefKeyFloating = 'focus_floating_enabled';
  static const String _prefKeyShowHomeIcon = 'show_focus_mode_icon';

  final ValueNotifier<PhaseFinishEvent?> phaseFinishNotifier = ValueNotifier(null);

  FocusTechnique _selectedTechnique = FocusTechnique.pomodoro25;
  bool _isRestPhase = false;
  bool _isRunning = false;

  int _customFocusMinutes = 35;
  int _customRestMinutes = 7;

  int _remainingSeconds = 25 * 60;
  int _flowtimeElapsedSeconds = 0;
  int _totalFocusSecondsInTechnique = 25 * 60;

  bool _isFloatingEnabled = true;
  bool _isFocusScreenOpen = false;
  Offset? _floatingOffset;

  final List<FocusTaskItem> _tasks = [];
  Timer? _ticker;

  final List<ActiveDockingScreen> _dockingScreenStack = [];
  bool _subjectDetailHasCorriges = false;

  ActiveDockingScreen get activeDockingScreen =>
      _dockingScreenStack.isNotEmpty ? _dockingScreenStack.last : ActiveDockingScreen.home;

  bool get subjectDetailHasCorriges => _subjectDetailHasCorriges;

  void pushDockingScreen(ActiveDockingScreen screen, {bool hasCorriges = false}) {
    _dockingScreenStack.remove(screen); // avoid duplicates
    _dockingScreenStack.add(screen);
    if (screen == ActiveDockingScreen.subjectDetail) {
      _subjectDetailHasCorriges = hasCorriges;
    }
    notifyListeners();
  }

  void popDockingScreen(ActiveDockingScreen screen) {
    _dockingScreenStack.remove(screen);
    notifyListeners();
  }

  void updateSubjectDetailCorriges(bool hasCorriges) {
    if (_subjectDetailHasCorriges != hasCorriges) {
      _subjectDetailHasCorriges = hasCorriges;
      notifyListeners();
    }
  }

  bool _showHomeIcon = true;

  bool get showHomeIcon => _showHomeIcon;

  void setShowHomeIcon(bool value) async {
    _showHomeIcon = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyShowHomeIcon, value);
    } catch (_) {}
  }

  FocusTechnique get selectedTechnique => _selectedTechnique;
  bool get isRestPhase => _isRestPhase;
  bool get isRunning => _isRunning;
  int get customFocusMinutes => _customFocusMinutes;
  int get customRestMinutes => _customRestMinutes;
  int get remainingSeconds => _remainingSeconds;
  int get flowtimeElapsedSeconds => _flowtimeElapsedSeconds;
  int get totalFocusSecondsInTechnique => _totalFocusSecondsInTechnique;
  bool get isFloatingEnabled => _isFloatingEnabled;
  bool get isFocusScreenOpen => _isFocusScreenOpen;
  Offset? get floatingOffset => _floatingOffset;
  List<FocusTaskItem> get tasks => List.unmodifiable(_tasks);

  FocusTimerService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isFloatingEnabled = prefs.getBool(_prefKeyFloating) ?? true;
      _showHomeIcon = prefs.getBool(_prefKeyShowHomeIcon) ?? true;
      final rawTasks = prefs.getString(_prefKeyTasks);
      if (rawTasks != null && rawTasks.isNotEmpty) {
        final List list = json.decode(rawTasks);
        _tasks.clear();
        for (final item in list) {
          _tasks.add(FocusTaskItem.fromJson(item as Map<String, dynamic>));
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('FocusTimerService init error: $e');
    }
  }

  String get formattedTime {
    final int sec = (_selectedTechnique == FocusTechnique.flowtime && !_isRestPhase)
        ? _flowtimeElapsedSeconds
        : _remainingSeconds;
    final m = (sec / 60).floor();
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (_selectedTechnique == FocusTechnique.flowtime && !_isRestPhase) return 1.0;
    if (_totalFocusSecondsInTechnique <= 0) return 1.0;
    return (_remainingSeconds / _totalFocusSecondsInTechnique).clamp(0.0, 1.0);
  }

  String phaseLabel(bool isArabic) {
    if (_isRestPhase) {
      return isArabic ? '☕ استراحة مستحقة' : '☕ Pause Méritée';
    }
    if (_selectedTechnique == FocusTechnique.flowtime) {
      return isArabic ? '🌊 نمط التدفق الحر' : '🌊 Mode Flowtime';
    }
    return isArabic ? '🎯 في قمة التركيز' : '🎯 En Pleine Concentration';
  }

  void setFocusScreenOpen(bool isOpen) {
    if (_isFocusScreenOpen != isOpen) {
      _isFocusScreenOpen = isOpen;
      notifyListeners();
    }
  }

  void toggleFloatingEnabled([bool? val]) async {
    _isFloatingEnabled = val ?? !_isFloatingEnabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyFloating, _isFloatingEnabled);
    } catch (_) {}
  }

  void setFloatingOffset(Offset offset) {
    _floatingOffset = offset;
    notifyListeners();
  }

  void applyTechnique(FocusTechnique technique) {
    _ticker?.cancel();
    _selectedTechnique = technique;
    _isRunning = false;
    _isRestPhase = false;
    _flowtimeElapsedSeconds = 0;

    if (technique == FocusTechnique.custom) {
      _totalFocusSecondsInTechnique = _customFocusMinutes * 60;
      _remainingSeconds = _totalFocusSecondsInTechnique;
    } else if (technique == FocusTechnique.flowtime) {
      _remainingSeconds = 0;
      _totalFocusSecondsInTechnique = 0;
    } else {
      _totalFocusSecondsInTechnique = technique.defaultFocusMinutes * 60;
      _remainingSeconds = _totalFocusSecondsInTechnique;
    }
    notifyListeners();
  }

  void setCustomDurations(int focusMinutes, int restMinutes) {
    _customFocusMinutes = focusMinutes.clamp(5, 180);
    _customRestMinutes = restMinutes.clamp(1, 60);
    if (_selectedTechnique == FocusTechnique.custom && !_isRunning && !_isRestPhase) {
      _totalFocusSecondsInTechnique = _customFocusMinutes * 60;
      _remainingSeconds = _totalFocusSecondsInTechnique;
    }
    notifyListeners();
  }

  void toggleTimer() {
    if (_isRunning) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  void startTimer() {
    _ticker?.cancel();
    _isRunning = true;
    notifyListeners();

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_selectedTechnique == FocusTechnique.flowtime && !_isRestPhase) {
        _flowtimeElapsedSeconds++;
        notifyListeners();
      } else {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          _onPhaseFinished();
        }
      }
    });
  }

  void pauseTimer() {
    _ticker?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _ticker?.cancel();
    applyTechnique(_selectedTechnique);
  }

  void skipPhase() {
    _onPhaseFinished();
  }

  void finishFlowtimeSession() {
    _ticker?.cancel();
    if (_flowtimeElapsedSeconds < 60) {
      return;
    }
    final breakSeconds = (_flowtimeElapsedSeconds / 5).round();
    final breakMinutes = (breakSeconds / 60).round().clamp(1, 60);

    _isRestPhase = true;
    _isRunning = false;
    _remainingSeconds = breakMinutes * 60;
    _totalFocusSecondsInTechnique = breakMinutes * 60;
    notifyListeners();

    phaseFinishNotifier.value = PhaseFinishEvent(
      isBreak: true,
      durationMinutes: breakMinutes,
    );
  }

  void _onPhaseFinished() {
    _ticker?.cancel();
    if (!_isRestPhase) {
      // Work -> Rest
      int restSeconds;
      if (_selectedTechnique == FocusTechnique.custom) {
        restSeconds = _customRestMinutes * 60;
      } else {
        restSeconds = _selectedTechnique.defaultRestMinutes * 60;
      }
      final durationMins = (restSeconds / 60).round();

      _isRestPhase = true;
      _isRunning = false;
      _remainingSeconds = restSeconds;
      _totalFocusSecondsInTechnique = restSeconds;
      notifyListeners();

      phaseFinishNotifier.value = PhaseFinishEvent(
        isBreak: true,
        durationMinutes: durationMins,
      );
    } else {
      // Rest -> Work
      _isRestPhase = false;
      _isRunning = false;
      if (_selectedTechnique == FocusTechnique.custom) {
        _totalFocusSecondsInTechnique = _customFocusMinutes * 60;
        _remainingSeconds = _totalFocusSecondsInTechnique;
      } else if (_selectedTechnique == FocusTechnique.flowtime) {
        _remainingSeconds = 0;
        _totalFocusSecondsInTechnique = 0;
        _flowtimeElapsedSeconds = 0;
      } else {
        _totalFocusSecondsInTechnique = _selectedTechnique.defaultFocusMinutes * 60;
        _remainingSeconds = _totalFocusSecondsInTechnique;
      }
      notifyListeners();

      phaseFinishNotifier.value = PhaseFinishEvent(
        isBreak: false,
        durationMinutes: (_totalFocusSecondsInTechnique / 60).round(),
      );
    }
  }

  // --- Task Checklist Management ---
  void addTask(String title) {
    final t = title.trim();
    if (t.isEmpty) return;
    _tasks.add(FocusTaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: t,
    ));
    notifyListeners();
    _saveTasks();
  }

  void toggleTask(FocusTaskItem task) {
    task.isCompleted = !task.isCompleted;
    notifyListeners();
    _saveTasks();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    _saveTasks();
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = json.encode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_prefKeyTasks, raw);
    } catch (e) {
      debugPrint('Error saving focus tasks: $e');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    phaseFinishNotifier.dispose();
    super.dispose();
  }
}
