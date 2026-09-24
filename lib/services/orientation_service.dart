import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OrientationCategory {
  final String id;
  final String nomFr;
  final String nomAr;
  final String icone;
  final List<String> fiches;

  OrientationCategory({
    required this.id,
    required this.nomFr,
    required this.nomAr,
    required this.icone,
    required this.fiches,
  });

  factory OrientationCategory.fromJson(Map<String, dynamic> json) {
    return OrientationCategory(
      id: json['id'] as String? ?? '',
      nomFr: json['nom_fr'] as String? ?? '',
      nomAr: json['nom_ar'] as String? ?? '',
      icone: json['icone'] as String? ?? 'school',
      fiches: (json['fiches'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class SchoolSummary {
  final String id;
  final String fichier;
  final String nom;
  final String nomAr;
  final String type;
  final String duree;
  final String diplome;
  final int? villesCount;
  final int? places;
  final String? concours;
  final String? plateforme;

  SchoolSummary({
    required this.id,
    required this.fichier,
    required this.nom,
    required this.nomAr,
    required this.type,
    required this.duree,
    required this.diplome,
    this.villesCount,
    this.places,
    this.concours,
    this.plateforme,
  });

  factory SchoolSummary.fromJson(Map<String, dynamic> json) {
    return SchoolSummary(
      id: json['id'] as String? ?? '',
      fichier: json['fichier'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      nomAr: json['nom_ar'] as String? ?? '',
      type: json['type'] as String? ?? '',
      duree: json['duree'] as String? ?? '',
      diplome: json['diplome'] as String? ?? '',
      villesCount: json['villes_count'] as int?,
      places: json['places'] as int?,
      concours: json['concours'] as String?,
      plateforme: json['plateforme'] as String?,
    );
  }
}

class SimulationResult {
  final String schoolId;
  final String schoolName;
  final String schoolNameAr;
  final double scoreCandidat;
  final double? seuilReference;
  final String statut; // 'admissible', 'chance_reelle', 'liste_attente', 'difficile'
  final String statutLabelFr;
  final String statutLabelAr;
  final String details;

  SimulationResult({
    required this.schoolId,
    required this.schoolName,
    required this.schoolNameAr,
    required this.scoreCandidat,
    this.seuilReference,
    required this.statut,
    required this.statutLabelFr,
    required this.statutLabelAr,
    required this.details,
  });
}

class OrientationService extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<OrientationCategory> _categories = [];
  List<SchoolSummary> _schools = [];
  final Map<String, Map<String, dynamic>> _cacheSchoolDetails = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<OrientationCategory> get categories => _categories;
  List<SchoolSummary> get schools => _schools;

  Future<void> init() async {
    if (_schools.isNotEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final jsonString = await rootBundle
          .loadString('assets/orientation/schools/index.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;

      final rawCategories = data['categories'] as List<dynamic>? ?? [];
      _categories = rawCategories
          .map((c) => OrientationCategory.fromJson(c as Map<String, dynamic>))
          .toList();

      final rawSchools = data['etablissements'] as List<dynamic>? ?? [];
      _schools = rawSchools
          .map((s) => SchoolSummary.fromJson(s as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading orientation index: $e');
      _errorMessage = 'Impossible de charger les données d\'orientation.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getSchoolDetails(String filename) async {
    if (_cacheSchoolDetails.containsKey(filename)) {
      return _cacheSchoolDetails[filename];
    }

    try {
      final jsonString =
          await rootBundle.loadString('assets/orientation/schools/$filename');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      _cacheSchoolDetails[filename] = data;
      return data;
    } catch (e) {
      debugPrint('Error loading school details for $filename: $e');
      return null;
    }
  }

  List<SchoolSummary> filterSchools({
    String? query,
    String? categoryId,
  }) {
    List<SchoolSummary> result = List.from(_schools);

    if (categoryId != null && categoryId != 'toutes') {
      final cat = _categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => OrientationCategory(
            id: '', nomFr: '', nomAr: '', icone: '', fiches: []),
      );
      if (cat.fiches.isNotEmpty) {
        result = result.where((s) => cat.fiches.contains(s.id)).toList();
      }
    }

    if (query != null && query.trim().isNotEmpty) {
      final cleanQuery = query.toLowerCase().trim();
      result = result.where((s) {
        final matchesName = s.nom.toLowerCase().contains(cleanQuery);
        final matchesNameAr = s.nomAr.contains(cleanQuery);
        final matchesType = s.type.toLowerCase().contains(cleanQuery);
        final matchesDiplome = s.diplome.toLowerCase().contains(cleanQuery);
        return matchesName || matchesNameAr || matchesType || matchesDiplome;
      }).toList();
    }

    return result;
  }

  List<SimulationResult> simulateChances({
    required double noteNational,
    required double noteRegional,
    required String branchCode, // 'sm', 'pc', 'svt', 'eco', 'technique', 'bac_pro'
  }) {
    final score = (noteNational * 0.75) + (noteRegional * 0.25);
    final results = <SimulationResult>[];

    // Reference thresholds
    final Map<String, Map<String, double>> thresholds = {
      'encg': {
        'sm': 12.00,
        'eco': 12.00,
        'pc': 14.00,
        'svt': 14.00,
        'bac_pro': 14.00,
      },
      'ensa': {
        'sm': 12.00,
        'pc': 14.00,
        'svt': 14.40,
        'technique': 14.40,
        'bac_pro': 14.40,
      },
      'ensam': {
        'sm': 12.25,
        'pc': 15.40,
        'svt': 16.17,
        'technique': 15.00,
        'bac_pro': 16.17,
      },
      'fmp_fmd_pharmacie': {
        'sm': 12.00,
        'pc': 12.00,
        'svt': 12.00,
      },
      'iav_hassan_2': {
        'sm': 15.00,
        'pc': 16.50,
        'svt': 17.00,
      },
      'ena_architecture': {
        'sm': 13.00,
        'pc': 14.80,
        'svt': 14.80,
        'technique': 14.50,
      },
      'enam_meknes': {
        'sm': 15.61,
        'pc': 16.43,
        'svt': 15.90,
      },
      'iscae_groupe': {
        'sm': 17.70,
        'pc': 18.60,
        'svt': 18.10,
        'eco': 17.30,
        'technique': 18.40,
      },
      'est_maroc': {
        'sm': 12.00,
        'pc': 12.50,
        'svt': 13.00,
        'eco': 12.00,
        'technique': 12.00,
      },
      'fst_maroc': {
        'sm': 12.50,
        'pc': 13.00,
        'svt': 13.50,
        'technique': 12.50,
      },
    };

    for (final school in _schools) {
      final schoolThresholdMap = thresholds[school.id];
      if (schoolThresholdMap == null) continue;

      final seuil = schoolThresholdMap[branchCode];
      if (seuil == null) continue; // Branch not directly applicable

      String statut;
      String labelFr;
      String labelAr;
      String details;

      final diff = score - seuil;
      if (diff >= 0.5) {
        statut = 'admissible';
        labelFr = 'Très favorable';
        labelAr = 'فرصة قوية جداً';
        details = 'Votre moyenne (${score.toStringAsFixed(2)}) dépasse le seuil historique de référence (${seuil.toStringAsFixed(2)}).';
      } else if (diff >= 0.0) {
        statut = 'chance_reelle';
        labelFr = 'Dans le seuil';
        labelAr = 'مؤهل للمباراة';
        details = 'Votre moyenne (${score.toStringAsFixed(2)}) est alignée avec le seuil habituel (${seuil.toStringAsFixed(2)}).';
      } else if (diff >= -1.25) {
        statut = 'liste_attente';
        labelFr = 'Liste d\'attente probable';
        labelAr = 'لائحة انتظار مرجحة';
        details = 'Écart de ${(-diff).toStringAsFixed(2)} pt. Forte probabilité d\'appel lors des désistements en phase 2 ou 3.';
      } else {
        statut = 'difficile';
        labelFr = 'Compétitif';
        labelAr = 'تنافسي مرتفع';
        details = 'Seuil estimé à ${seuil.toStringAsFixed(2)}. Privilégiez également les filières de secours (EST, FST).';
      }

      results.add(SimulationResult(
        schoolId: school.id,
        schoolName: school.nom,
        schoolNameAr: school.nomAr,
        scoreCandidat: score,
        seuilReference: seuil,
        statut: statut,
        statutLabelFr: labelFr,
        statutLabelAr: labelAr,
        details: details,
      ));
    }

    results.sort((a, b) {
      final order = {'admissible': 0, 'chance_reelle': 1, 'liste_attente': 2, 'difficile': 3};
      return (order[a.statut] ?? 4).compareTo(order[b.statut] ?? 4);
    });

    return results;
  }
}
