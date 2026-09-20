import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isAnonymous;

  const AuthUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'isAnonymous': isAnonymous,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        photoUrl: json['photoUrl'] as String?,
        isAnonymous: json['isAnonymous'] as bool? ?? false,
      );
}

class AuthService extends ChangeNotifier {
  static const String _keyUser = 'auth_user_session_v1';
  static const String _keyPromptShown = 'auth_prompt_shown_v1';

  bool _initialized = false;
  AuthUser? _currentUser;
  bool _hasShownPrompt = false;

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _currentUser != null && !_currentUser!.isAnonymous;
  AuthUser? get currentUser => _currentUser;
  bool get hasShownPrompt => _hasShownPrompt;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasShownPrompt = prefs.getBool(_keyPromptShown) ?? false;
      final rawUser = prefs.getString(_keyUser);
      if (rawUser != null && rawUser.isNotEmpty) {
        _currentUser = AuthUser.fromJson(json.decode(rawUser));
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> markPromptShown() async {
    _hasShownPrompt = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPromptShown, true);
    } catch (e) {
      debugPrint('AuthService markPromptShown error: $e');
    }
  }

  Future<bool> signInWithGoogle({
    String? customName,
    String? customEmail,
  }) async {
    try {
      final user = AuthUser(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        displayName: customName ?? 'Élève Cours Maroc',
        email: customEmail ?? 'eleve@coursmaroc.ma',
        photoUrl: null,
      );
      _currentUser = user;
      _hasShownPrompt = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, json.encode(user.toJson()));
      await prefs.setBool(_keyPromptShown, true);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
    } catch (e) {
      debugPrint('signOut error: $e');
    }
    notifyListeners();
  }
}
