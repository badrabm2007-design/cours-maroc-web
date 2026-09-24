import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';

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
  static const String _keyUser = 'auth_user_session_v2';
  static const String _keyPromptShown = 'auth_prompt_shown_v1';

  bool _initialized = false;
  AuthUser? _currentUser;
  bool _hasShownPrompt = false;
  bool _isSigningIn = false;
  String? _lastError;

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _currentUser != null && !_currentUser!.isAnonymous;
  AuthUser? get currentUser => _currentUser;
  bool get hasShownPrompt => _hasShownPrompt;
  bool get isSigningIn => _isSigningIn;
  String? get lastError => _lastError;

  Future<String?> getIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      debugPrint('Error getting ID token on web: $e');
      return null;
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      // 1. Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // 2. On Web, capture redirect sign-in results if the page was reloaded after redirect
      if (kIsWeb) {
        try {
          final redirectResult = await FirebaseAuth.instance.getRedirectResult();
          if (redirectResult.user != null) {
            final user = redirectResult.user!;
            _currentUser = AuthUser(
              id: user.uid,
              displayName: (user.displayName != null && user.displayName!.isNotEmpty)
                  ? user.displayName!
                  : (user.email?.split('@').first ?? 'Élève Cours Maroc'),
              email: user.email ?? '',
              photoUrl: user.photoURL,
            );
            await _saveUserToPrefs(_currentUser!);
          }
        } catch (e) {
          debugPrint('AuthService getRedirectResult error: $e');
        }
      }

      // 3. Listen to Firebase auth state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          _currentUser = AuthUser(
            id: user.uid,
            displayName: (user.displayName != null && user.displayName!.isNotEmpty)
                ? user.displayName!
                : (user.email?.split('@').first ?? 'Élève Cours Maroc'),
            email: user.email ?? '',
            photoUrl: user.photoURL,
          );
          _saveUserToPrefs(_currentUser!);
        }
        notifyListeners();
      });

      final prefs = await SharedPreferences.getInstance();
      _hasShownPrompt = prefs.getBool(_keyPromptShown) ?? false;
      final rawUser = prefs.getString(_keyUser);
      if (rawUser != null && rawUser.isNotEmpty) {
        _currentUser = AuthUser.fromJson(json.decode(rawUser));
      } else if (FirebaseAuth.instance.currentUser != null) {
        final fbUser = FirebaseAuth.instance.currentUser!;
        _currentUser = AuthUser(
          id: fbUser.uid,
          displayName: (fbUser.displayName != null && fbUser.displayName!.isNotEmpty)
              ? fbUser.displayName!
              : (fbUser.email?.split('@').first ?? 'Élève Cours Maroc'),
          email: fbUser.email ?? '',
          photoUrl: fbUser.photoURL,
        );
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
      _lastError = e.toString();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveUserToPrefs(AuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, json.encode(user.toJson()));
      await prefs.setBool(_keyPromptShown, true);
    } catch (e) {
      debugPrint('Error saving user to prefs: $e');
    }
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

  Future<bool> signInWithGoogle() async {
    if (_isSigningIn) return false;
    _isSigningIn = true;
    _lastError = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        // Real Google Sign-In with popup on Web
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        try {
          final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
          final user = userCredential.user;
          if (user != null) {
            final authUser = AuthUser(
              id: user.uid,
              displayName: (user.displayName != null && user.displayName!.isNotEmpty)
                  ? user.displayName!
                  : (user.email?.split('@').first ?? 'Élève Cours Maroc'),
              email: user.email ?? '',
              photoUrl: user.photoURL,
            );
            _currentUser = authUser;
            _hasShownPrompt = true;
            await _saveUserToPrefs(authUser);
            _isSigningIn = false;
            notifyListeners();
            return true;
          }
        } on FirebaseAuthException catch (e) {
          // If popup is blocked by browser, try redirect flow
          if (e.code == 'popup-blocked' || e.code == 'popup-closed-by-user') {
            await FirebaseAuth.instance.signInWithRedirect(googleProvider);
            return false;
          }
          rethrow;
        }
      } else {
        // Android / Native mobile flow using google_sign_in 7.x
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize(
          serverClientId: '555535888410-ebnf10mjbnms6c32fuh6d6nq1ps77ser.apps.googleusercontent.com',
        );
        final account = await googleSignIn.authenticate(scopeHint: ['email']);
        final authTokens = account.authentication;
        final clientAuth = await account.authorizationClient.authorizationForScopes(['email']);
        final credential = GoogleAuthProvider.credential(
          accessToken: clientAuth?.accessToken,
          idToken: authTokens.idToken,
        );
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) {
          final authUser = AuthUser(
            id: user.uid,
            displayName: (user.displayName != null && user.displayName!.isNotEmpty)
                ? user.displayName!
                : (account.displayName ?? 'Élève Cours Maroc'),
            email: user.email ?? account.email,
            photoUrl: user.photoURL ?? account.photoUrl,
          );
          _currentUser = authUser;
          _hasShownPrompt = true;
          await _saveUserToPrefs(authUser);
          _isSigningIn = false;
          notifyListeners();
          return true;
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('signInWithGoogle FirebaseAuthException: ${e.code} - ${e.message}');
      _lastError = '[${e.code}] ${e.message ?? "Erreur d'authentification"}';
      _isSigningIn = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      _lastError = e.toString();
      _isSigningIn = false;
      notifyListeners();
      return false;
    }

    _isSigningIn = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _lastError = null;
    try {
      await FirebaseAuth.instance.signOut();
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUser);
    } catch (e) {
      debugPrint('signOut error: $e');
    }
    notifyListeners();
  }
}
