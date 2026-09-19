import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/curriculum_models.dart';
import 'download_service.dart';
import 'user_profile_service.dart';

enum PrefetchPriority {
  surroundingNeighbor(10),
  otherCategoryTab(7),
  homeViewportTop(5),
  homeViewportBottom(3),
  speculative(1);

  final int value;
  const PrefetchPriority(this.value);
}

class _PrefetchTask {
  final DocumentItem document;
  final PrefetchPriority priority;
  final DateTime queuedAt;

  _PrefetchTask({
    required this.document,
    required this.priority,
  }) : queuedAt = DateTime.now();
}

class SmartPrefetchService extends ChangeNotifier {
  static const int _maxConcurrent = 2;

  final List<_PrefetchTask> _queue = [];
  final Set<String> _inFlightIds = {};
  bool _isProcessing = false;

  /// Returns active Moroccan academic semester based on today's date:
  /// - Months 9 to 1 (Sept - Jan): 'semestre-1'
  /// - Months 2 to 6 (Feb - June): 'semestre-2'
  /// - Months 7 & 8 (July - Aug): 'all' (Summer review / exam prep)
  static String get activeMoroccanSemester {
    final month = DateTime.now().month;
    if (month >= 9 || month == 1) {
      return 'semestre-1';
    } else if (month >= 2 && month <= 6) {
      return 'semestre-2';
    }
    return 'all';
  }

  /// Whether we are in peak national / regional exam preparation period (April to June)
  static bool get isPeakExamSeason {
    final month = DateTime.now().month;
    return month >= 4 && month <= 6;
  }

  /// Filters and orders documents of a subject considering:
  /// 1. Current school semester (S1 vs S2)
  /// 2. Student progression (if student visited Lesson N, start with [N, N+1, N+2])
  List<DocumentItem> selectPredictedDocuments({
    required SubjectItem subject,
    required String category,
    required UserProfileService userProfile,
    int maxCount = 4,
  }) {
    final docs = subject.documents
        .where((d) => d.category == category)
        .toList();
    if (docs.isEmpty) return [];

    final activeSem = activeMoroccanSemester;

    // Filter documents by active semester when applicable
    List<DocumentItem> candidateDocs;
    if (activeSem != 'all' && category != 'examens') {
      final semFiltered = docs
          .where((d) => d.semester == activeSem || d.semester == 'general')
          .toList();
      candidateDocs = semFiltered.isNotEmpty ? semFiltered : docs;
    } else {
      candidateDocs = docs;
    }

    // Progression prediction: did the user study a specific lesson previously?
    final lastStudiedTitle =
        userProfile.getLastStudiedLessonTitle(subject.nameFr, category);

    if (lastStudiedTitle != null && lastStudiedTitle.isNotEmpty) {
      final matchIdx = candidateDocs.indexWhere((d) =>
          d.title == lastStudiedTitle ||
          d.title.toLowerCase() == lastStudiedTitle.toLowerCase());

      if (matchIdx >= 0) {
        final List<DocumentItem> prioritized = [];
        // Next lesson (N+1), current lesson (N), then subsequent (N+2, N+3)
        if (matchIdx + 1 < candidateDocs.length) {
          prioritized.add(candidateDocs[matchIdx + 1]);
        }
        prioritized.add(candidateDocs[matchIdx]);
        if (matchIdx + 2 < candidateDocs.length) {
          prioritized.add(candidateDocs[matchIdx + 2]);
        }
        if (matchIdx + 3 < candidateDocs.length) {
          prioritized.add(candidateDocs[matchIdx + 3]);
        }

        // Complete up to maxCount
        for (final doc in candidateDocs) {
          if (prioritized.length >= maxCount) break;
          if (!prioritized.contains(doc)) {
            prioritized.add(doc);
          }
        }
        return prioritized;
      }
    }

    // Default: return first lessons of the active semester
    return candidateDocs.take(maxCount).toList();
  }

  /// 1. Home Screen Initial Load:
  /// - Top 4 visible subjects in grid: prefetch top 4 PDFs each.
  /// - Next 2 subjects (bottom 2): prefetch top 2-3 PDFs each.
  void prefetchHomeScreenInitial({
    required List<SubjectItem> subjects,
    required UserProfileService userProfile,
    required DownloadService downloadService,
  }) {
    if (subjects.isEmpty) return;

    // Rank subjects considering user affinity
    final sortedSubjects = List<SubjectItem>.from(subjects);
    sortedSubjects.sort((a, b) {
      final countA = userProfile.getSubjectConsultationCount(a.nameFr);
      final countB = userProfile.getSubjectConsultationCount(b.nameFr);
      return countB.compareTo(countA);
    });

    // Top 4 cards: 4 PDFs each
    final topFour = sortedSubjects.take(4).toList();
    for (final s in topFour) {
      final cat = _getPreferredCategory(s, userProfile);
      final docs = selectPredictedDocuments(
        subject: s,
        category: cat,
        userProfile: userProfile,
        maxCount: 4,
      );
      _enqueueDocuments(docs, PrefetchPriority.homeViewportTop, downloadService);
    }

    // Next 2 cards: 2-3 PDFs each
    if (sortedSubjects.length > 4) {
      final nextTwo = sortedSubjects.skip(4).take(2).toList();
      for (final s in nextTwo) {
        final cat = _getPreferredCategory(s, userProfile);
        final docs = selectPredictedDocuments(
          subject: s,
          category: cat,
          userProfile: userProfile,
          maxCount: 3,
        );
        _enqueueDocuments(
            docs, PrefetchPriority.homeViewportBottom, downloadService);
      }
    }
  }

  /// 2. Home Screen Scroll:
  /// When user scrolls and new subject cards enter the viewport, prefetch 4 PDFs each.
  void prefetchHomeScrolledSubjects({
    required List<SubjectItem> newlyVisibleSubjects,
    required UserProfileService userProfile,
    required DownloadService downloadService,
  }) {
    for (final s in newlyVisibleSubjects) {
      final cat = _getPreferredCategory(s, userProfile);
      final docs = selectPredictedDocuments(
        subject: s,
        category: cat,
        userProfile: userProfile,
        maxCount: 4,
      );
      _enqueueDocuments(
          docs, PrefetchPriority.homeViewportBottom, downloadService);
    }
  }

  /// 3. Subject Detail: Other Tabs Anticipation
  /// When user enters a subject, prefetch top 3 documents in the OTHER tabs
  /// (e.g. exercices, contrôles, examens) so switching tabs is instant!
  void prefetchSubjectOtherTabs({
    required SubjectItem subject,
    required String activeCategory,
    required UserProfileService userProfile,
    required DownloadService downloadService,
  }) {
    const availableCategories = ['cours', 'exercices', 'controles', 'examens', 'resumes'];
    for (final cat in availableCategories) {
      if (cat == activeCategory) continue;
      final docs = selectPredictedDocuments(
        subject: subject,
        category: cat,
        userProfile: userProfile,
        maxCount: 3,
      );
      _enqueueDocuments(
          docs, PrefetchPriority.otherCategoryTab, downloadService);
    }
  }

  /// 4. Surrounding Neighbors Prefetching:
  /// When user taps/opens a document, prefetch the 2 preceding and 2 succeeding PDFs
  /// with Highest Priority (probability of next tap is extremely high).
  void prefetchSurroundingNeighbors({
    required List<DocumentItem> documents,
    required int currentIndex,
    required DownloadService downloadService,
    int radius = 2,
  }) {
    if (documents.isEmpty || currentIndex < 0 || currentIndex >= documents.length) {
      return;
    }

    final toPrefetch = <DocumentItem>[];
    // Next documents first
    for (int i = 1; i <= radius; i++) {
      final nextIdx = currentIndex + i;
      if (nextIdx < documents.length) {
        toPrefetch.add(documents[nextIdx]);
      }
    }
    // Previous documents
    for (int i = 1; i <= radius; i++) {
      final prevIdx = currentIndex - i;
      if (prevIdx >= 0) {
        toPrefetch.add(documents[prevIdx]);
      }
    }

    _enqueueDocuments(
        toPrefetch, PrefetchPriority.surroundingNeighbor, downloadService);
  }

  /// 5. Document List Scroll:
  /// Prefetches documents stopping in the user's viewport.
  void prefetchDocumentListScroll({
    required List<DocumentItem> visibleDocuments,
    required DownloadService downloadService,
    int maxCount = 4,
  }) {
    _enqueueDocuments(
      visibleDocuments.take(maxCount).toList(),
      PrefetchPriority.homeViewportTop,
      downloadService,
    );
  }

  String _getPreferredCategory(SubjectItem s, UserProfileService profile) {
    const cats = ['cours', 'exercices', 'controles', 'examens'];
    String bestCat = 'cours';
    int maxVisits = -1;
    for (final c in cats) {
      final visits = profile.getCategoryConsultationCount(s.nameFr, c);
      if (visits > maxVisits) {
        maxVisits = visits;
        bestCat = c;
      }
    }
    // If student has no history yet, and it's exam season, check examens
    if (maxVisits <= 0 && isPeakExamSeason) {
      if (s.documents.any((d) => d.category == 'examens')) {
        return 'examens';
      }
    }
    return bestCat;
  }

  void _enqueueDocuments(
    List<DocumentItem> docs,
    PrefetchPriority priority,
    DownloadService downloadService,
  ) {
    for (final doc in docs) {
      if (doc.id.isEmpty) continue;
      // Skip if already cached on disk
      if (downloadService.isCached(doc.id)) continue;
      // Skip if already in flight
      if (_inFlightIds.contains(doc.id)) continue;

      // Check if already in queue: if so, upgrade priority if higher
      final existingIdx = _queue.indexWhere((t) => t.document.id == doc.id);
      if (existingIdx >= 0) {
        if (priority.value > _queue[existingIdx].priority.value) {
          _queue[existingIdx] = _PrefetchTask(
            document: doc,
            priority: priority,
          );
        }
      } else {
        _queue.add(_PrefetchTask(
          document: doc,
          priority: priority,
        ));
      }
    }

    // Sort queue by priority descending, then oldest queued
    _queue.sort((a, b) {
      final prioDiff = b.priority.value.compareTo(a.priority.value);
      if (prioDiff != 0) return prioDiff;
      return a.queuedAt.compareTo(b.queuedAt);
    });

    _processNext(downloadService);
  }

  void _processNext(DownloadService downloadService) {
    if (_isProcessing) return;
    _isProcessing = true;

    Future.microtask(() async {
      while (_queue.isNotEmpty && _inFlightIds.length < _maxConcurrent) {
        final task = _queue.removeAt(0);
        final fileId = task.document.id;

        if (downloadService.isCached(fileId)) continue;
        if (_inFlightIds.contains(fileId)) continue;

        _inFlightIds.add(fileId);

        // Run background download
        downloadService
            .loadPdfForViewing(document: task.document, isBackground: true)
            .then((_) {
          _inFlightIds.remove(fileId);
          _processNext(downloadService);
        }).catchError((_) {
          _inFlightIds.remove(fileId);
          _processNext(downloadService);
        });
      }
      _isProcessing = false;
    });
  }

  /// Cancels all pending speculative prefetch tasks
  void clearQueue() {
    _queue.clear();
  }
}
