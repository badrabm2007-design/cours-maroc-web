import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

enum AmbientSoundType {
  none,
  rain,
  cafe,
  nature,
}

extension AmbientSoundTypeExt on AmbientSoundType {
  String localizedName(bool isArabic) {
    switch (this) {
      case AmbientSoundType.none:
        return isArabic ? 'بدون صوت' : 'Silencieux';
      case AmbientSoundType.rain:
        return isArabic ? 'صوت المطر' : 'Pluie apaisante';
      case AmbientSoundType.cafe:
        return isArabic ? 'هدوء المقهى' : 'Calme de Café';
      case AmbientSoundType.nature:
        return isArabic ? 'الغابة والجبل' : 'Forêt & Montagne';
    }
  }

  String get emoji {
    switch (this) {
      case AmbientSoundType.none:
        return '🔇';
      case AmbientSoundType.rain:
        return '🌧️';
      case AmbientSoundType.cafe:
        return '☕';
      case AmbientSoundType.nature:
        return '🌲';
    }
  }

  String? get assetPath {
    switch (this) {
      case AmbientSoundType.none:
        return null;
      case AmbientSoundType.rain:
        return 'audio/rain.ogg';
      case AmbientSoundType.cafe:
        return 'audio/cafe.ogg';
      case AmbientSoundType.nature:
        return 'audio/nature.ogg';
    }
  }
}

class FocusSoundService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  AmbientSoundType _currentSound = AmbientSoundType.none;
  bool _isPlaying = false;
  double _volume = 0.7;

  AmbientSoundType get currentSound => _currentSound;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  FocusSoundService() {
    _init();
  }

  void _init() {
    _player.setReleaseMode(ReleaseMode.loop);
    _player.setVolume(_volume);

    _player.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
  }

  Future<void> selectSound(AmbientSoundType sound) async {
    if (_currentSound == sound && _isPlaying) {
      await pause();
      return;
    }

    _currentSound = sound;
    if (sound == AmbientSoundType.none) {
      await stop();
      return;
    }

    try {
      final path = sound.assetPath;
      if (path != null) {
        await _player.stop();
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(_volume);
        await _player.play(AssetSource(path));
        _isPlaying = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error playing ambient sound on web $sound: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing ambient sound: $e');
    }
  }

  Future<void> resume() async {
    if (_currentSound == AmbientSoundType.none) return;
    try {
      await _player.resume();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming ambient sound: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentSound = AmbientSoundType.none;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping ambient sound: $e');
    }
  }

  Future<void> setVolume(double val) async {
    _volume = val.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
