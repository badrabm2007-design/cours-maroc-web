# Données d'Orientation Post-Bac — Cours Maroc

Ce dossier regroupe les fiches techniques structurées au format JSON pour l'ensemble des établissements d'enseignement supérieur post-baccalauréat au Maroc.

## Structure d'une Fiche Établissement
Chaque fichier JSON (ex: `ensa.json`, `est.json`, `fst.json`, `encg.json`) contient :
1. **Identité & Définition** : Identifiant, Nom (FR/AR), Abréviation, Statut et Tutelle.
2. **Organisation des Études** : Durée, Diplômes délivrés, Débouchés professionnels.
3. **Implantation Géographique** : Liste exhaustive des villes et universités affiliées.
4. **Conditions d'Admission** : Séries de Baccalauréat autorisées, critères d'âge et sessions admises.
5. **Historique des Seuils de Présélection** : Seuils nationaux observés par filière (Sciences Maths, PC, SVT, Économie, Techniques) sur les 5 dernières sessions.
6. **Modalités des Concours** : Formule de calcul (75% National + 25% Régional), format des épreuves écrites (QCM).

Toutes ces données sont directement intégrées et restituées dynamiquement dans l'interface de l'application (écrans `OrientationScreen` et `SchoolDetailScreen`).
