import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/curriculum_models.dart';

class FavoriteItem {
  final DocumentItem document;
  final String subjectName;
  final DateTime addedAt;

  FavoriteItem({
    required this.document,
    required this.subjectName,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'document': document.toJson(),
        'subjectName': subjectName,
        'addedAt': addedAt.toIso8601String(),
      };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        document: DocumentItem.fromJson(json['document'] as Map<String, dynamic>),
        subjectName: json['subjectName'] as String? ?? '',
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class FavoritesService extends ChangeNotifier {
  static const String _prefsKey = 'user_favorites_v1';
  final Map<String, FavoriteItem> _favorites = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;
  List<FavoriteItem> get allFavorites => _favorites.values.toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> map = json.decode(raw);
        for (final entry in map.entries) {
          _favorites[entry.key] =
              FavoriteItem.fromJson(entry.value as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  bool isFavorite(String documentId) => _favorites.containsKey(documentId);

  Future<void> toggleFavorite({
    required DocumentItem document,
    required String subjectName,
  }) async {
    if (_favorites.containsKey(document.id)) {
      _favorites.remove(document.id);
    } else {
      _favorites[document.id] = FavoriteItem(
        document: document,
        subjectName: subjectName,
        addedAt: DateTime.now(),
      );
    }
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> removeFavorite(String documentId) async {
    if (_favorites.containsKey(documentId)) {
      _favorites.remove(documentId);
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        for (final entry in _favorites.entries) entry.key: entry.value.toJson()
      };
      await prefs.setString(_prefsKey, json.encode(map));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  List<Map<String, dynamic>> exportData() {
    return _favorites.values.map((f) => f.toJson()).toList();
  }

  Future<void> importCloudData(List<dynamic> list) async {
    try {
      bool changed = false;
      for (final item in list) {
        FavoriteItem? fav;
        if (item is Map<String, dynamic>) {
          fav = FavoriteItem.fromJson(item);
        } else if (item is Map) {
          fav = FavoriteItem.fromJson(Map<String, dynamic>.from(item));
        }
        if (fav != null) {
          final existing = _favorites[fav.document.id];
          if (existing == null) {
            _favorites[fav.document.id] = fav;
            changed = true;
          } else if (fav.addedAt.isAfter(existing.addedAt)) {
            _favorites[fav.document.id] = fav;
            changed = true;
          }
        }
      }
      if (changed) {
        notifyListeners();
        await _saveToPrefs();
      }
    } catch (e) {
      debugPrint('FavoritesService importCloudData error: $e');
    }
  }
}
