import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/curriculum_models.dart';

class DownloadRecord {
  final String fileId;
  final String localPath;
  final String fileName;
  final String title;
  final String subjectName;
  final String category;
  final int size;
  final DateTime downloadedAt;

  DownloadRecord({
    required this.fileId,
    required this.localPath,
    required this.fileName,
    required this.title,
    required this.subjectName,
    required this.category,
    required this.size,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'fileId': fileId,
        'localPath': localPath,
        'fileName': fileName,
        'title': title,
        'subjectName': subjectName,
        'category': category,
        'size': size,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory DownloadRecord.fromJson(Map<String, dynamic> json) => DownloadRecord(
        fileId: json['fileId'] as String,
        localPath: json['localPath'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subjectName: json['subjectName'] as String? ?? '',
        category: json['category'] as String? ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        downloadedAt: DateTime.tryParse(json['downloadedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  String get formattedSize {
    if (size <= 0) return '';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(0)} Ko';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}

class DownloadService extends ChangeNotifier {
  static const String _prefsKey = 'offline_downloads_web_v1';
  final Map<String, DownloadRecord> _downloads = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  DownloadService() {
    init();
  }

  Future<void> init() async {
    if (_initialized) return;
    await _loadDownloads();
    _initialized = true;
  }

  Future<void> _loadDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null) {
        final List<dynamic> list = json.decode(jsonStr);
        for (final item in list) {
          final record = DownloadRecord.fromJson(item as Map<String, dynamic>);
          _downloads[record.fileId] = record;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading downloads on web: $e');
    }
  }

  Future<void> _saveDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _downloads.values.map((e) => e.toJson()).toList();
      await prefs.setString(_prefsKey, json.encode(list));
    } catch (e) {
      debugPrint('Error saving downloads on web: $e');
    }
  }

  List<DownloadRecord> get allDownloads => _downloads.values.toList()
    ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));

  bool isDownloaded(String fileId) => _downloads.containsKey(fileId);

  bool isDownloading(String fileId) => false;

  double getProgress(String fileId) => 0.0;

  bool isCached(String fileId) => _downloads.containsKey(fileId);

  String? getExistingFilePath(String fileId) {
    if (_downloads.containsKey(fileId)) {
      return 'https://drive.google.com/file/d/$fileId/preview';
    }
    return null;
  }

  void clearCachedDocument(String fileId) {
    _downloads.remove(fileId);
  }

  void prefetchDocuments(List<DocumentItem> documents, {int maxCount = 2}) {}

  Future<String?> loadPdfForViewing({
    required DocumentItem document,
    bool isBackground = false,
  }) async {
    return 'https://drive.google.com/file/d/${document.id}/preview';
  }

  void cancelViewing(String fileId) {}

  Future<String?> downloadDocument({
    required DocumentItem document,
    required String subjectName,
  }) async {
    final downloadUrl =
        'https://drive.google.com/uc?id=${document.id}&export=download';
    
    // Trigger browser native download
    await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);

    final record = DownloadRecord(
      fileId: document.id,
      localPath: downloadUrl,
      fileName: '${document.title}.pdf',
      title: document.title,
      subjectName: subjectName,
      category: document.categoryDisplayName,
      size: 1024 * 1024,
      downloadedAt: DateTime.now(),
    );

    _downloads[document.id] = record;
    await _saveDownloads();
    notifyListeners();
    return downloadUrl;
  }

  Future<void> deleteDownload(String fileId) async {
    _downloads.remove(fileId);
    await _saveDownloads();
    notifyListeners();
  }

  Future<void> removeDownload(String fileId) async {
    await deleteDownload(fileId);
  }

  Future<void> clearAllDownloads() async {
    _downloads.clear();
    await _saveDownloads();
    notifyListeners();
  }

  int get totalDownloadSizeBytes =>
      _downloads.values.fold(0, (sum, item) => sum + item.size);

  String get formattedTotalSize {
    final bytes = totalDownloadSizeBytes;
    if (bytes <= 0) return '0 Mo';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
