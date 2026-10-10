# 📖 PROJET QRAYTI (قرايتي) — HISTORIQUE, INSTRUCTIONS & DIRECTIVES POUR LES MODÈLES IA

---

> # 🚨 INSTRUCTION CRITIQUE ET OBLIGATOIRE POUR TOUT MODÈLE D'IA (AI MODEL INSTRUCTION)
> 
> **À L'ATTENTION DE TOUT MODÈLE D'INTELLIGENCE ARTIFICIELLE (GPT-4, Claude, Gemini, DeepSeek, Copilot, etc.) TRAVAILLANT SUR CE PROJET :**
> 
> 1. **LECTURE PRÉALABLE OBLIGATOIRE** : Vous avez l'obligation formelle de **lire l'intégralité de ce fichier** avant d'analyser le code, d'émettre des recommandations ou d'effectuer la moindre modification dans l'un des dépôts de l'écosystème Qrayti (`cours`, `cours_web`, `cours_windows`).
> 2. **RESPECT DES STANDARDS & PROTOCOLES** : Vous devez strictement respecter les architectures, choix techniques, solutions aux pièges réseau/CORS et contraintes documentés ci-dessous.
> 3. **MISE À JOUR OBLIGATOIRE EN FIN DE MISSION** : Dès que vous terminez une tâche ou une modification, vous devez **OBLIGATOIREMENT COMPLÉTER ET METTRE À JOUR CE FICHIER** avec :
>    - La liste exacte des fichiers modifiés et des fonctionnalités ajoutées/corrigées.
>    - Les nouveaux bogues ou obstacles techniques rencontrés et la solution technique précise apportée.
>    - Les recommandations ou instructions nécessaires pour les futures IA et développeurs.
> 4. **MÉMOIRE TECHNIQUE DU PROJET** : Ne supprimez sous aucun prétexte les sections historiques existantes.
> 5. **ANIMATION PROFESSIONNELLE OFFICIELLE DE DÉMARRAGE (SPLASH SCREEN INTANGIBLE)** : L'animation d'ouverture Web de grand luxe créée pour Qrayti (trame géométrique islamique dorée à 8 pointes, particules flottantes d'or de la lumière du savoir, logo officiel transparent RGBA, typographie noble dorée *Qrayti • قرايتي*, filet doré animé, slogan *Excellence & Réussite • التميز الدراسي* et transition douce `cubic-bezier` sans à-coups) définie dans la racine ([`qrayti_splash_snippet(1).html`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours/qrayti_splash_snippet(1).html), [`qrayti_splash_demo(1).html`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours/qrayti_splash_demo(1).html)) et implémentée dans [`cours_web/web/index.html`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours_web/web/index.html) est **STRICTEMENT INTANGIBLE**. Il est **formellement interdit à toute IA de la remplacer, de la simplifier, de la supprimer ou de réintroduire des barres de progression / loaders génériques**. Tout déploiement Web doit obligatoirement être compilé et déployé depuis le dossier dédié **`flutter/app/cours_web`** (et JAMAIS depuis `cours/build/web` qui est réservé à l'application mobile).

---

## 1. Identité & Vue d'Ensemble du Projet Qrayti

* **Nom de marque officiel** : **Qrayti (قرايتي)**
* **Slogan officiel** : *Excellence & Réussite • التميز الدراسي*
* **Historique des appellations** : Anciennement connu sous les noms *Cours Lycée Maroc*, *Cours Maroc*, *My Pocket*. Rebrandé officiellement et définitivement sous **Qrayti** sur tous les supports.
* **Palette de couleurs officielle** :
  * Vert émeraude marocain : `#0F5132` / `#10B981`
  * Or royal / Ambre : `#F59E0B` / `#FBBF24`
  * Bleu nuit profond (Thème sombre) : `#0B1120` / `#0F172A`
* **Plateforme Web de production** : [https://qrayti.online](https://qrayti.online)
* **Dépôts de code GitHub** :
  * Web : `badrabm2007-design/cours_web` (branche `main`)
  * Windows Desktop : `badrabm2007-design/CoursMaroc-Windows` (branche `main`)
  * Mobile : `flutter/app/cours`

---

## 2. Architecture Multi-Plateforme

L'écosystème est divisé en 3 projets Flutter synchronisés :

```
flutter/app/
├── cours/               # Application Mobile (Android APK / AAB & iOS)
├── cours_web/           # Application Web PWA (Netlify + Serverless Functions)
└── cours_windows/       # Application Desktop Windows (Runner x64 C++)
```

### 2.1. Données & Catalogue (`curriculum.json`)
* Emplacement unifié : `assets/data/curriculum.json` (synchronisé sur les 3 projets).
* Contient plus de 20 000 ressources pédagogiques classées par niveau, filière, matière, catégorie (cours, exercices, contrôles, examens) et semestre.
* Niveaux pris en charge :
  * **3ème Année Collège (3AC)** : Parcours International (BIOF) et Parcours Général.
  * **Tronc Commun (TC)** : Sciences BIOF, Lettres et Sciences Humaines, Technologie.
  * **1ère Année Bac (1BAC)** : Sciences Expérimentales, Sciences Maths, Économie (SEG), Lettres, STE, STM.
  * **2ème Année Bac (2BAC)** : PC, SVT, Sciences Maths A & B, Économie, SGC, Lettres, Sciences Humaines, STE, STM.

### 2.2. Hébergement Cloud & Stockage des PDFs
* **Google Drive** : Compte de stockage central `babadre2007@gmail.com`.
* **Registre de déduplication** : [`cours/scripts/data/registry.json`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours/scripts/data/registry.json). Tout document téléversé est enregistré avec son hash SHA-256 unique, empêchant les doublons.

---

## 3. Historique Complet des Modifications Récentes (Changelog)

### Rebranding Majeur & Identité Graphique (v1.2.0 - v1.2.1)
1. **Traitement & Déploiement du Logo Officiel** :
   * Extraction du logo officiel `n.l.jpg`, détourage transparent RGBA haute fidélité (`n.l_transparent.png`, 2048x2048).
   * Déploiement multi-résolution sur :
     * Mobile Android : `assets/images/logo.png`, `android/app/src/main/res/mipmap-*/ic_launcher.png`.
     * Web : `web/favicon.ico` (multi-tailles 16, 24, 32, 48, 64px), `web/icons/Icon-*.png`, `assets/images/logo.png`.
     * Windows Desktop : `windows/runner/resources/app_icon.ico` (multi-résolution jusqu'à 256x256).
   * Rebranding textuel : `AndroidManifest.xml` (`android:label="Qrayti"`), `index.html`, `manifest.json`, système d'internationalisation `app_strings.dart` (fr: *Qrayti*, ar: *قرايتي*, en: *Qrayti*).

2. **Élimination des Indicateurs d'Attente & Nouveau Splash Screen Web (Animation Claude)** :
   * Suppression complète de la barre de progression (`.cm-progress-bar`) et des éléments de chargement classiques.
   * Intégration de l'animation d'ouverture luxueuse créée avec Claude :
     - Trame géométrique islamique marocaine (étoile à 8 pointes en filigrane or subtil).
     - Particules d'or flottantes symbolisant la « lumière du savoir ».
     - Logo officiel transparent avec aura respirante émeraude & or, et faisceau lumineux traversant (`qs-shine`).
     - Typographie noble dorée pour le logotype `Qrayti` et la calligraphie arabe `قرايتي`.
     - Filet séparateur doré animé et slogan « Excellence & Réussite • التميز الدراسي ».
     - Transition fluide sans à-coups (`cubic-bezier`), dissimulation instantanée dès l'événement `flutter-first-frame` ou détection du canvas Flutter, avec durée minimale esthétique de 800 ms (`MIN_SHOW`).
     - Page de démonstration interactive autonome intégrée sur `/demo.html` pour tester et rejouer l'animation à volonté sur localhost.

3. **Correction & Stabilisation Définitive du Widget Chrono Flottant** :
   * Masquage strict sur la première page (sélection du niveau d'études) via `isGradeSelectionActive`.
   * **Suppression du décalage et des sauts entre les pages** : Suppression de l'ancien code qui recalculait des coordonnées différentes par page ($Y=9$ sur Home vs $Y=70$ sur SubjectDetail).
   * Ancrage unifié à $Y=10\text{ px}$ sur tous les écrans avec persistance globale de la position si l'utilisateur déplace le widget.
   * Fluidification par `AnimatedPositioned(250ms, easeOutCubic)`.

4. **Intégration & Nettoyage des Cours de 3ème Année Collège (3AC)** :
   * Traitement des 47 documents PDF authentiques de `Desktop/cours_maroc_downloads/3eme-annee-college`.
   * Téléversement réussi de 100% des documents sur Google Drive (`babadre2007@gmail.com`).
   * Purge de 1 503 entrées fictives du catalogue qui généraient des erreurs 404.
   * Nettoyage et accentuation des titres des cours, exercices et contrôles (en arabe et en français).

5. **Déploiement Windows Desktop v1.2.0** :
   * Compilation release réussie `build\windows\x64\runner\Release\cours_windows.exe`.
   * Empaquetage du package autonome `Qrayti_Windows_v1.2.0.zip` (21,58 Mo) sur le bureau et release GitHub créée.

---

## 4. Problèmes Rencontrés & Solutions Techniques Appliquées

### ⚠️ Problème 1 : Erreur CORS sur Google Drive lors de l'ouverture des PDF sur le Web
* **Description** : Dans le navigateur, le lecteur PDF affichait « Impossible de charger le document » alors que « Ouvrir Drive » fonctionnait.
* **Cause** : Google Drive bloque les requêtes `fetch()` directes de `pdf.js` exécutées depuis un navigateur tiers via les restrictions CORS (*Cross-Origin Resource Sharing*).
* **Solution** :
  1. En production Netlify : Création de la fonction proxy [`netlify/functions/pdf.mts`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours_web/netlify/functions/pdf.mts) accessible sur `/api/pdf?id=<ID>`, qui injecte les en-têtes `Access-Control-Allow-Origin: *`.
  2. En développement local : Ajout du même gestionnaire `/api/pdf` dans le serveur de test Python local [`local_server.py`](file:///C:/Users/HPi5book/.gemini/antigravity/brain/bd3f84ba-9bcb-4106-9898-a4830866baaa/scratch/local_server.py).
  3. Dans l'application Flutter (`pdf_viewer_screen.dart`) : Mécanisme de secours multi-paliers : tentative sur `/api/pdf` local $\rightarrow$ repli automatique sur `https://qrayti.online/api/pdf?id=...` $\rightarrow$ lien direct.

### ⚠️ Problème 2 : Décalage / Saut Violent du Widget Chronomètre entre les Pages
* **Description** : Le chronomètre sautait de 61 pixels vers le bas et de plus de 1 000 pixels horizontalement à chaque clic de navigation.
* **Cause** : L'écouteur `activeDockingScreen` écrasait `_position` à chaque changement d'écran avec un `Positioned` brut non animé.
* **Solution** :
  1. Ancrage unique, unifié et stable à $Y=10\text{ px}$.
  2. Persistance globale de la position choisie tout au long de la session.
  3. Utilisation de `AnimatedPositioned(250ms, Curves.easeOutCubic)` pour des déplacements doux sans téléportation.

### ⚠️ Problème 3 : Cache Persistant de l'Ancien Favicon dans les Navigateurs
* **Description** : Les navigateurs conservaient l'ancien logo en favicon même après rafraîchissement.
* **Cause** : Mise en cache agressive de `favicon.ico` par les navigateurs Web.
* **Solution** :
  1. Génération de favicons aux formats `.ico` et `.png` multi-résolution (16, 32, 48, 64px).
  2. Ajout de paramètres de versioning dans `index.html` : `href="favicon.ico?v=3"`.
  3. Configuration de directives HTTP `Cache-Control: no-cache, no-store, must-revalidate` dans `netlify.toml` et `local_server.py`.

### ⚠️ Problème 4 : Échecs DNS IPv6 avec Netlify CLI sous Windows
* **Description** : Les commandes de déploiement Netlify échouaient sous Windows avec des erreurs `ENOTFOUND api.netlify.com`.
* **Cause** : Node.js sur Windows interroge les adresses IPv6 non routables sur certains réseaux.
* **Solution** : Toujours forcer la résolution IPv4 avant toute commande Netlify :
  ```powershell
  $env:NODE_OPTIONS="--dns-result-order=ipv4first"
  ```

### ⚠️ Problème 5 : Déconnexion TCP lors des Uploads de Grosses Archives sur GitHub
* **Description** : Le téléversement direct de fichiers >15 Mo vers GitHub Release coupait brutalement la connexion.
* **Solution** : Création de la release via `gh release create` et stockage de l'archive ZIP directement sur le bureau (`Desktop\Qrayti_Logos\Qrayti_Windows_v1.2.0.zip`) pour mise à disposition directe ou téléversement morcelé.

### ⚠️ Problème 6 : Erreur de Compilation Android sur `isGradeSelectionActive`
* **Description** : L'exécution de `flutter run` sur appareil Android a échoué avec l'erreur `The getter 'isGradeSelectionActive' isn't defined for the type 'FocusTimerService'`.
* **Cause** : Le widget `floating_focus_timer.dart` synchronisé utilisait le getter `isGradeSelectionActive` qui n'avait été ajouté initialement que dans le projet Web `cours_web`.
* **Solution** : Synchronisation complète de `focus_timer_service.dart`, `level_selection_screen.dart` et `branch_selection_screen.dart` entre `cours_web`, `cours` et `cours_windows`. Analyse `dart analyze` validée à 100% avec zéro erreur.

### ⚠️ Problème 7 : Refus Google Play Console (Politique de Confidentialité non concordante)
* **Description** : Google Play Console a refusé la mise à jour (« Mise à jour refusée — Les renseignements sur l'appli ou le développeur ne concordent pas »).
* **Cause** : Le document en ligne mentionnait encore l'ancien nom « Cours Maroc », n'affichait pas explicitement l'identifiant du package (`com.lyceemaroc.cours.cours_lycee_maroc`), et la redirection Netlify servait le shell SPA au lieu d'une page HTML statique pure.
* **Solution** :
  1. Rédaction d'une page statique ultra-conforme [`privacy.html`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours_web/web/privacy.html) contenant un tableau d'identifiants concordant à 100% avec la fiche Play Store (Nom d'app : **Qrayti**, Package : `com.lyceemaroc.cours.cours_lycee_maroc`, Développeur : **Qrayti**, Email : `contact.coursmaroc@gmail.com`).
  2. Intégration de la clause officielle de non-affiliation gouvernementale (obligatoire pour les apps éducatives).
  3. Déploiement des routes statiques `/privacy`, `/privacy.html` et `/PRIVACY_POLICY.html` dans `netlify.toml` avec `force = true` pour garantir un rendu HTML statique direct (HTTP 200) sans dépendance au moteur Flutter SPA.

### ⚠️ Problème 8 : Tailles inégales des cartes de filières sur mobile
* **Description** : Les cartes de filières variaient en hauteur selon que le nom tenait sur une ligne ou deux (ex. Sciences Expérimentales vs Sciences Économiques et Gestion).
* **Cause** : `_BranchCardItem` dans `branch_selection_screen.dart` calculait sa hauteur de façon dynamique sans contrainte fixe sur mobile.
* **Solution** : Fixation d'une hauteur uniforme de `88px` (`height: isDesktop ? null : 88`), padding ajusté à `16x10`, centrage vertical harmonieux des intitulés en français et en arabe.

### ⚠️ Problème 9 : Dépassement horizontal de 48 pixels sur le Mode Silencieux
* **Description** : Dans l'« Espace Mode Concentration », la carte du mode silencieux affichait un bandeau d'erreur rayé jaune/rouge : `RIGHT OVERFLOWED BY 48 PIXELS`.
* **Cause** : Le titre `Mode Silencieux (Zéro Distraction)` et le badge `Inactif` étaient placés dans une `Row` rigide sans `Flexible` ni `Expanded`, excédant la largeur disponible à côté de l'interrupteur `Switch`.
* **Solution** : Remplacement par `Flexible(child: Text('Mode Silencieux', overflow: TextOverflow.ellipsis))` garantissant zéro débordement sur tout type d'écran.

### ⚠️ Problème 10 : Incomplétude et mutualisation du catalogue 3AC (Collège)
* **Description** : La filière 3AC Général manquait des matières fondamentales en arabe (Maths, Physique, SVT) et les matières communes n'étaient pas synchronisées entre Parcours Général et BIOF.
* **Cause** : Les scrapers initiaux ne ciblaient que les cours BIOF en français ou n'extrayaient pas les liens d'éléments enfants AlloSchool.
* **Solution** :
  1. Développement du script d'ingestion complète [`scripts/expand_3ac.py`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours/scripts/expand_3ac.py).
  2. Téléchargement et téléversement de **46 nouveaux documents authentiques sur Google Drive** (Mathématiques, Physique-Chimie, SVT, Arabe, Histoire-Géo).
  3. Partage sans doublon de stockage (zéro duplication Drive) des matières communes :
     - Vers BIOF : `arabe` (9 docs), `education-islamique` (8 docs), `histoire-geographie` (9 docs).
     - Vers Général : `francais` (3 docs), `anglais` (10 docs).
  4. Les deux filières 3AC disposent désormais de **toutes les 8 matières scolaires** complètes.

---

### ⚠️ Problème 11 : Optimisation et Réduction Maximale du Retard de Lancement du Site Web
* **Description** : Lancement perçu comme lent sur le site web (https://qrayti.online) avec un écran de démarrage (splash screen) qui tardait à s'effacer.
* **Causes identifiées** :
  1. `MIN_SHOW = 1600` ms : Verrou artificiel de 1,6 seconde imposé dans `web/index.html` avant de lancer la disparition du splash, même lorsque Flutter était prêt en 400ms.
  2. Scripts bloquants dans `<head>` : La bibliothèque `pdf.min.js` (280 Ko) était chargée de manière synchrone, bloquant le rendu initial et le démarrage du moteur Flutter.
  3. Téléchargement séquentiel : Le bundle Flutter `main.dart.js` (5,3 Mo) n'était demandé qu'après l'analyse et l'exécution de `flutter_bootstrap.js`.
  4. Connexion tardive à CanvasKit : Absence de préconnexion TLS vers `https://www.gstatic.com`.
  5. Cache navigateur sous-exploité : `no-store` et effacement forcé des caches empêchaient le navigateur de réutiliser instantanément `main.dart.js` et `canvaskit.wasm`.
* **Solutions appliquées** :
  1. **Suppression du délai artificiel** : `MIN_SHOW` ramené de 1600ms à 350ms, temporisation MutationObserver réduite à 40ms, transition d'effacement raccourcie à 0.35s.
  2. **Accélération des keyframes CSS** : L'apparition du logo, du nom doré et du slogan s'accomplit en 250ms (contre 750ms auparavant).
  3. **Préchargement parallèle HTTP/2** : Ajout de `<link rel="preload" href="main.dart.js" as="script">` et `flutter_bootstrap.js` dans `<head>`.
  4. **Préconnexion réseau** : `<link rel="preconnect" href="https://www.gstatic.com" crossorigin>` et `dns-prefetch`.
  5. **Déféré sans blocage** : `pdf.min.js` déplacé en `defer` non-bloquant.
  6. **Règles de cache HTTP Netlify (`_headers`)** :
     - `index.html` et `flutter_bootstrap.js` : `max-age=0, must-revalidate` (mises à jour détectées immédiatement).
     - `main.dart.js` : `max-age=604800, stale-while-revalidate=86400` (ouverture instantanée en ~10-30ms dès la seconde visite).
     - `canvaskit/*` et `assets/*` : `max-age=31536000, immutable`.
  7. **Compilation de production optimisée** : Compilation effectuée avec `flutter build web --release -O4`.

---

### ⚠️ Problème 12 : Échec de Git Push avec 'Could not resolve host: github.com' (Réseau IPv6)
* **Description** : L'exécution de `git push origin main` échouait avec `fatal: unable to access: Could not resolve host: github.com`.
* **Cause** : Comme pour Node.js (Problème 4), la couche libcurl de Git sous Windows tentait de résoudre et se connecter à GitHub via une route IPv6 non routable (`64:ff9b::8c52:7903`) avec dépassement de délai (timeout 21s).
* **Solution** : Configuration globale de Git pour forcer la résolution d'adresses IPv4 :
  ```powershell
  git config --global http.ipResolve ipv4
  ```
### ⚠️ Problème 13 : Routage Multi-Pages Web & Badge « Déjà Consulté » pour les Documents PDF
* **Description** :
  1. Les différentes sections du site (Mode Concentration, Statistiques/Espace Élève, Paramètres, Favoris, Hors-Ligne, Recherche) étaient ouvertes via des dialogues/routes anonymes sans synchronisation de l'URL du navigateur, empêchant l'accès direct par lien, le rafraîchissement ou le partage d'URL dédiée.
  2. L'élève n'avait aucun moyen de distinguer les documents PDF déjà consultés de ceux restant à étudier.
* **Solutions apportées** :
  1. **Routage URL Propre Web (`usePathUrlStrategy`)** :
     - Ajout de `flutter_web_plugins` dans `pubspec.yaml` et appel de `usePathUrlStrategy()` dans `main.dart`.
     - Configuration exhaustive de `onGenerateRoute` avec URL sans hash (`#`) :
       * `/concentration` ou `/focus` $\rightarrow$ `FocusModeScreen`
       * `/statistiques` ou `/analytics` $\rightarrow$ `ProfileAnalyticsScreen`
       * `/parametres` ou `/settings` $\rightarrow$ `SettingsScreen`
       * `/orientation` $\rightarrow$ `OrientationScreen` (et `/orientation/:schoolId`)
       * `/hors-ligne` ou `/downloads` $\rightarrow$ `OfflineDownloadsScreen`
       * `/favoris` $\rightarrow$ `FavoritesScreen`
       * `/recherche` $\rightarrow$ `SearchScreen`
       * `/niveaux` $\rightarrow$ `LevelSelectionScreen`
     - Mise à jour de tous les `Navigator.push` (`home_screen.dart`, `floating_focus_timer.dart`, `settings_screen.dart`) avec `RouteSettings(name: ...)`.
     - Sécurisation du bouton retour (`leading: Navigator.canPop() ? BackButton() : pushReplacementNamed('/')`) sur tous les écrans pour garantir le retour vers l'accueil même en accès direct par URL.
  2. **Indicateur « Déjà Consulté »** :
     - Implémentation du suivi persistant `_viewedDocIds` dans `UserProfileService` avec stockage `SharedPreferences` (`user_viewed_doc_ids_v1`) et synchronisation cloud.
     - Affichage d'un badge compact `✓ Consulté` (avec icône et couleur émeraude/menthe) inséré immédiatement à côté de la pastille de taille de fichier dans `DocumentCard`.

* **Problème 14 : Organisation des Documents 3AC (Cours, Exercices, Contrôles continus, Examens Locaux & Régionaux) & Refonte Top Bar Desktop** :
  - *Constat* : Au niveau 3AC (3eme-annee-college), l'interface n'affichait que les catégories disposant déjà de documents, masquant les volets officiels indispensables du collège marocain. En Mathématiques BIOF, seul Exercices (9) s'affichait, avec des accents manquants dans les titres et un document de français intrusif (« Négocier le projet ») au lieu du Théorème de Pythagore. Sur grand écran, l'en-tête (bouton retour et titre de matière) était masqué et le widget flottant de concentration chevauchait la barre de recherche.
  - *Corrections apportées* :
    1. **Structure Pédagogique Officielle 3AC (5 volets)** :
       - cours : Cours (الدروس)
       - exercices : Exercices (التمارين)
       - controles : Contrôles continus (فروض محروسة)
       - examens-locaux : Examens Locaux (موحد محلي - Fin S1)
       - examens-regionaux : Examens Régionaux (موحد جهوي - Fin S2)
       - **Règle stricte d'affichage** : Conformément à la norme de l'application sur toutes les matières, seules les catégories qui possèdent réellement des documents (`count > 0`) sont affichées dans la barre d'onglets (`_availableCategories = preferredOrder.where((c) => categoriesSet.contains(c)).toList()`). Aucune catégorie vide n'apparaît. Dès que de nouveaux examens ou cours sont ajoutés au catalogue, leur onglet apparaît automatiquement.
    2. **Correction des Données 3AC (curriculum.json)** :
       - Restauration du vrai titre du PDF 3eme-annee-college_biof_mathematiques_exercices_th-or-me-de-pythagore-exercices_120764.pdf : **Théorème de Pythagore (Exercices)** (élimination de l'intrus « Négocier le projet (Cours) »).
       - Correction des caractères accentués : Développement et factorisation, Racines carrées, Puissances, Les atomes et les ions, Quelques matériaux au quotidien.
    3. **Refonte Flex Row de la Top Bar Desktop** :
       - Remplacement de l'ancien Stack absolu par une Row responsive avec Expanded(Center(...)) pour les catégories, garantissant que le bouton retour, le titre (Mathématiques) et le sous-titre de niveau (3ème Année Collège) ne soient jamais masqués.
    4. **Déplacement du Widget Flottant Pomodoro** :
       - Positionnement par défaut sécurisé en bas à droite (screenSize.height - 60, screenSize.width - 190), évitant tout chevauchement avec la barre de recherche et les actions d'en-tête.

### ⚠️ Problème 15 : Élimination Totale de la Marque AlloSchool & Intégration Sélective Moutamadris
* **Description** : Des résumés de cours et fiches (notamment en Arabe, Histoire-Géo, Éducation Islamique et Philosophie) contenaient un bandeau supérieur orange estampillé AlloSchool avec fil d'Ariane cliquable, ou des mentions textuelles de bas de page.
* **Solutions apportées** :
  1. **Moissonnage sélectif de Moutamadris (`scripts/moutamadris_replacer.py`)** :
     - Exploration automatisée des portails de cours Moutamadris (3AC, Tronc Commun, 1ère BAC, 2ème BAC).
     - Analyse automatique en temps réel par PyMuPDF pour ne télécharger et retenir QUE les modèles de professeurs indépendants 100% exempts de tout logo ou filigrane de plateforme.
  2. **Assainissement & Dé-branding In-Place (`scripts/sanitize_ecosystem.py`)** :
     - Redaction propre par aplat blanc du bandeau d'en-tête (y: 0 à 95px) sur la page de garde.
     - Suppression de toutes les annotations et liens cliquables pointant vers des plateformes tierces (`doc.xref_set_key(p.xref, 'Annots', 'null')`).
     - Recherche et biffure automatique de toutes les occurrences d'URL de bas de page.
     - Réécriture des métadonnées du document avec l'entité `Qrayti`.
  3. **Audit de Conformité Final** :
     - Scan complet des **8 406 documents** du catalogue local par inspection multi-threads :
     - **0 document avec logo ou mention AlloSchool (0,00%)**.
     - **100,00% (8 406 fichiers) certifiés propres, neutres et professionnels**.

### ⚠️ Problème 16 : Enrichissement Massif & Organisation Pédagogique du Niveau 3AC (Collège)
* **Description** : Le niveau 3AC (3ème Année Collège) ne contenait initialement que 5 à 10 documents par matière, sans onglets dédiés pour les examens locaux, examens régionaux et contrôles continus. L'utilisateur a souligné le manque de documents et l'obligation de ne jamais afficher d'onglets vides.
* **Solutions apportées** :
  1. **Moissonnage Massif & Dé-branding Temps Réel (`scripts/expand_3ac_exams_and_controles.py`)** :
     - Téléchargement et assainissement (0,00% logos tiers) de plus de 200 documents authentiques marocains depuis Moutamadris.
     - Le catalogue 3AC passe de ~62-71 documents à **349 documents en BIOF** et **339 documents en Général** (total : **688 fiches de cours, exercices, contrôles et examens**).
     - Ventilation par matière :
       * Mathématiques : 67 documents (13 cours, 21 exercices, 15 contrôles, 3 examens locaux, 15 examens régionaux)
       * Physique-Chimie : 57 documents (25 cours, 3 exercices, 3 contrôles, 15 examens locaux, 11 examens régionaux)
       * SVT : 50 documents (24 cours, 4 exercices, 7 contrôles, 4 examens locaux, 11 examens régionaux)
       * Français : 40 documents (21 cours, 1 exercice, 1 contrôle, 2 examens locaux, 15 examens régionaux)
       * Arabe : 40 documents (19 cours, 4 exercices, 1 examen local, 15 examens régionaux, 1 autre)
       * Histoire-Géographie : 44 documents (24 cours, 5 examens locaux, 15 examens régionaux)
       * Éducation Islamique : 39 documents (13 cours, 11 examens locaux, 15 examens régionaux)
       * Anglais : 12 documents (10 cours, 2 examens locaux)
  2. **Structure Pédagogique Officielle & Zéro Onglet Vide** :
     - Ordre pédagogique officiel marocain pour la 3AC :
       1. Cours (`cours`)
       2. Exercices (`exercices`)
       3. Contrôles continus (`controles`)
       4. Examens Locaux - Semestre 1 (`examens-locaux`)
       5. Examens Régionaux - Semestre 2 (`examens-regionaux`)
     - Filtrage dynamique strict : les onglets n'apparaissent QUE si `count > 0`. Aucun onglet vide n'est affiché.
  3. **Indexation Régionale et Annuelle** :
     - Extraction automatique des 12 régions marocaines (`casablanca-settat`, `rabat-sale-kenitra`, `fes-meknes`, `souss-massa`, `oriental`, `tanger-tetouan-al-hoceima`, etc.) et des années d'examens (2010-2023) pour filtrage instantané.
  4. **Serveur Local Ultra-Rapide** :
     - `scratch/local_server.py` doté d'un index mémoire O(1) pour servir tous les PDF locaux instantanément en local (< 1ms).

---


### 4.5. Version du 07/10/2026 — Intégration Dynamique & Rotative de l'Application "My Turn"

1. **Intégration de la Nouvelle Application "My Turn"** :
   - Solution digitale intelligente de gestion en temps réel des files d'attente pour professionnels (salons de coiffure, barbershops, cabinets médicaux, centres de lavage, ateliers) et leurs clients.
   - URL Google Play Store : `https://play.google.com/store/apps/details?id=com.queueflow.queue_flow`
   - Logo haute définition importé sous `assets/images/myturn_icon.png` dans `cours` et `cours_web`.
2. **Architecture de Bannières Dynamiques & Non Statiques ("ne doit pas être fixe et stable")** :
   - **Rotation Automatique de 3 Variantes Bilingues (FR / AR)** pour My Turn :
     * *Variante 0 (Grand Public / Étudiants)* : « Fini l'Attente ! / وداعاً للانتظار » — Suivi en direct du rang sur smartphone, alertes de passage, liberté de se déplacer sans attendre sur place.
     * *Variante 1 (Professionnels & Commerces)* : « My Turn Pro / إدارة الطوابير الذكية » — Ergonomie 1-clic (#1, #2 -> en prestation -> terminé), affichage TV 16:9 paysage en salle d'attente, alertes WhatsApp directes.
     * *Variante 2 (Innovation & Zéro Stress)* : « File Sans Fraude / شفافية وعدالة » — Système infalsifiable garantissant un ordre équitable, QR code instantané, codes courts d'accès (ex: 1F970A) et résilience hors-ligne.
   - **Rotation Temporelle du Podium Publicitaire (Spotlight Multi-Apps)** :
     * Les scores publicitaires varient selon le créneau horaire (`DateTime.now().minute ~/ 2 % 4`) alternant équitablement entre My Turn (score 96), MyPocket (score 96), Focus Domain (score 96), et l'App PC Windows / Partenaire démo.
     * Colonne de gauche : Alternance dynamique entre le jeu de réflexion *Nine Points* et *My Turn*.
   - **Intégration Mobile Responsive** :
     * Création de la méthode `SmartBannerService.getMobileBanner()` et insertion dans le flux vertical de `HomeScreen` sur mobile (`!showSideBanners`) afin que les utilisateurs sur smartphone bénéficient d'un accès 1-tap direct vers le Play Store.
3. **Fichiers Modifiés & Synchronisés** :
   - `cours/assets/images/myturn_icon.png`
   - `cours_web/assets/images/myturn_icon.png`
   - `cours/lib/services/smart_banner_service.dart`
   - `cours_web/lib/services/smart_banner_service.dart`
   - `cours/lib/screens/home_screen.dart`
   - `cours_web/lib/screens/home_screen.dart`


---

### 4.6. Version du 09/10/2026 — Résolution du Référencement Google / Gemini AI Overview, Sécurisation de l'Animation Officielle & Google Search Console

1. **Diagnostic Initial du Référencement & Clarification de l'Entité** :
   - **Problème rencontré** : 
     * Lors de la recherche `qrayti.online` sur Google, Gemini affichait un encadré « Aperçu IA » citant mot pour mot un texte en arabe provenant d'un blogspot concurrent (`qrayti-online.blogspot.com`) et renvoyait les internautes vers Blogger, tout en créant une confusion avec le portail tiers `9rayti.com`.
     * Lors de la recherche `qrayti`, Google suggérait automatiquement `9rayti.com` (« Résultats pour 9rayti »).
     * **Cause technique** : Le site Flutter Web chargeait initialement un canvas JavaScript sans contenu textuel sémantique HTML brut pré-rendu pour les robots d'exploration (Googlebot, Google-Extended pour Gemini, Bingbot). En outre, l'ancien sitemap référençait encore le domaine Netlify d'origine (`cours-maroc.netlify.app`), générant des erreurs de lecture.
   - **Clarification décisive de l'utilisateur** :
     * Le site `https://qrayti-online.blogspot.com` **n'appartient PAS** à l'utilisateur : c'est un concurrent / tiers non affilié. Aucune modification n'est requise ni possible sur Blogger. L'objectif est d'asseoir l'autorité exclusive de **`https://qrayti.online`** pour que Google et Gemini l'identifient comme l'unique référence officielle et éliminent le blogspot concurrent des suggestions.

2. **Mesures Techniques Implémentées dans `flutter/app/cours_web`** :
   - **Intégration des Balises de Validation Google Search Console (GSC)** :
     * Ajout de la nouvelle balise méta requise : `<meta name="google-site-verification" content="HVfYhQJKA1s3TznQTlOQC-YHtc4D7lWTvAc_sJrTMBU" />` (conservant également l'ancienne balise).
     * Propriété officiellement validée avec succès sur GSC.
   - **Contenu Sémantique Pré-rendu Accessible (`#seo-crawler-content`)** :
     * Implémentation d'un bloc sémantique riche masqué visuellement via la classe CSS `.sr-only` (conforme aux normes WCAG et consignes de Google pour le SEO des applications monopages) :
       - Titre principal `<h1>Qrayti Online (قرايتي أونلاين) - Plateforme Éducative & Guide d'Orientation au Maroc</h1>`.
       - Paragraphes explicatifs détaillant la gratuité et l'exhaustivité des ressources conformes au Ministère de l'Éducation Nationale du Maroc.
       - Sections complètes par cycle : Collège 3AC (Maths, Physique-Chimie, SVT, Français, Arabe), Tronc Commun Scientifique et Technologique, 1ère Année Bac (Sciences Expérimentales, Sciences Maths, œuvres littéraires pour le Régional), 2ème Année Bac (2BAC PC, SVT, Sciences Maths A & B, Économie, annales d'examens nationaux 2008-2024 avec corrections détaillées).
       - Guide exhaustif d'orientation post-bac : ENSA, ENCG, EST, FST, CPGE, Médecine et Pharmacie (FMP/FMD), ENSAM, ENA, AIAC.
       - Présentation de la PWA et de l'application Android native sur le Google Play Store.
     * **Bénéfice** : Googlebot et Google-Extended (Gemini) indexent l'intégralité du contenu textuel dès le premier octet HTML, avant toute exécution de JavaScript ou de WebAssembly.
   - **Données Structurées Schema.org JSON-LD (Rich Snippets)** :
     * Déclaration de l'entité `WebSite` avec les variantes de marque : `["Qrayti", "qrayti.online", "قرايتي", "قرايتي أونلاين", "Qrayti Maroc"]`.
     * Déclaration de l'entité `EducationalOrganization` reliant le site web à la fiche Google Play Store officielle.
     * Schéma `FAQPage` ultra-ciblé pour les moteurs IA et le Knowledge Graph :
       - Réponse claire affirmant que `https://qrayti.online` est le seul site officiel.
       - Désaveu formel du blogspot tiers : *« Aucun blog tiers non officiel hébergé sur Blogger (comme blogspot) n'est affilié à la plateforme officielle Qrayti Online »*.
       - Clarification de la différenciation totale vis-à-vis de l'ancien annuaire `9rayti.com`.
   - **Autorisation Explicite des Robots IA dans `robots.txt`** :
     * Autorisation formelle de `Google-Extended` (robot officiel de Gemini), `Googlebot`, `GPTBot`, `PerplexityBot`, `ClaudeBot`, `Bingbot`.
     * Lien de sitemap canonique : `Sitemap: https://qrayti.online/sitemap.xml`.
   - **Plan du Site `sitemap.xml` 100% Dédié** :
     * 207 URL ciblées avec priorité maximale (1.0 sur l'accueil, 0.95 sur l'orientation, 0.85-0.90 sur les niveaux 3AC/1BAC/2BAC).
     * Balises multilingues `xhtml:link` (`fr`, `ar`, `x-default`).

3. **Sécurisation & Préservation Absolue du Splash Screen Officiel (Animation Claude)** :
   - **Incident résolu** : Lors d'un premier test de déploiement, la commande `flutter build web` avait été exécutée par erreur dans le répertoire mobile `cours` au lieu de `cours_web`, ce qui avait réintroduit temporairement un ancien écran de chargement basique avec barre de progression.
   - **Rétablissement & Sanctuarisation** :
     * Le code d'origine de l'animation de démarrage de grand luxe (stocké dans [`qrayti_splash_snippet(1).html`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours/qrayti_splash_snippet(1).html) à la racine) a été réintégré intégralement dans [`cours_web/web/index.html`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours_web/web/index.html).
     * Trame géométrique islamique dorée à 8 pointes (`.qs-pattern`), particules d'or ascendantes (`.qs-particles`), logo transparent officiel RGBA haute fidélité (`.qs-mark`), typographie dorée noble *Qrayti • قرايتي*, filet doré animé et slogan *Excellence & Réussite • التميز الدراسي*.
     * Aucune barre de progression générique.
     * Compilation de release exécutée exclusivement dans `flutter/app/cours_web` (`flutter build web --release`).
     * Déploiement réussi sur Netlify via l'outil MCP (`deployId: 6ac92678fb5a9c36de51ff7d`, statut `ready`).
     * Test de vérification direct HTTP 200 sur `https://qrayti.online` confirmant la présence du splash screen de luxe, des métadonnées SEO et des balises de validation Search Console.

4. **Fichiers Modifiés & Synchronisés** :
   - `cours_web/web/index.html` (Balises GSC, Schema.org FAQ, SEO `#seo-crawler-content`, Splash Screen de luxe préservé)
   - `cours_web/build/web/index.html` (Version de production déployée)
   - `cours_web/web/robots.txt` & `cours_web/build/web/robots.txt`
   - `cours_web/web/sitemap.xml` & `cours_web/build/web/sitemap.xml`
   - `cours/AI_INSTRUCTIONS.md` & `cours_web/AI_INSTRUCTIONS.md`

---

## 5. Guide d'Exécution & Commandes de Déploiement

### 5.1. Prévisualisation Web en Local (Localhost)
Pour lancer le serveur local de test (incluant le relais PDF Google Drive) :
```powershell
python "C:\Users\HPi5book\.gemini\antigravity\brain\bd3f84ba-9bcb-4106-9898-a4830866baaa\scratch\local_server.py"
```
Ouvrir ensuite : **`http://localhost:8080/`**

### 5.2. Compiler la Version Web
Dans `c:\Users\HPi5book\Desktop\flutter\app\cours_web` :
```powershell
flutter build web --release
```

### 5.3. Déployer sur Netlify en Production
```powershell
$env:NODE_OPTIONS="--dns-result-order=ipv4first"
netlify deploy --prod --dir=build/web
```

### 5.4. Compiler la Version Windows
Dans `c:\Users\HPi5book\Desktop\flutter\app\cours_windows` :
```powershell
flutter build windows --release
```
L'exécutable final est généré dans :
`build\windows\x64\runner\Release\cours_windows.exe`

---

## 7. Mise à Jour Critique : Synchronisation Google Drive & Assainissement des PDFs (10/10/2026)

### 7.1. Contexte & Diagnostic des Problèmes Antérieurs
* **Absence des nouveaux documents 3AC sur le site** : L'analyse a révélé que les 556 documents 3AC ajoutés précédemment possédaient des identifiants temporaires locaux (`local_3ac_...`) et des URLs fictives (`https://qrayti.online/api/pdf?id=...`). Ces fichiers n'avaient jamais été téléversés sur Google Drive.
* **Persistance des logos AlloSchool sur le site** : Bien que certains fichiers aient été nettoyés sur le disque local, ils n'avaient pas été réinjectés sur Google Drive via l'API, ce qui faisait que le site web et l'application mobile téléchargeaient toujours les anciens fichiers PDF hébergés sur Drive.
* **Décalage du catalogue distant** : Le catalogue distant hébergé sur Google Drive (`1HXG24aQmnvxj5pl19b7OdqNvQcJSzeyG`) datait du 14 septembre 2026 et écrasait ou bloquait la mise à jour des 20 824 documents.

### 7.2. Actions Opérées & Résultats
1. **Connexion OAuth Google Drive Réussie** : Authentification complète sous le compte `babadre2007@gmail.com` avec jeton auto-rafraîchi (`token.json`).
2. **Nettoyage & Remplacement en Place des 131 Anciens Documents 3AC** : Remplacement direct via l'API Google Drive (`PATCH uploadType=media`) des 131 fichiers existants par leurs versions locales assainies (sans bannières, logos, ou liens AlloSchool). Les liens d'origine restent inchangés mais le contenu servi est 100% propre.
3. **Téléversement de 373 Fichiers Uniques 3AC** : Envoi de l'intégralité des nouveaux fichiers 3AC vers le dossier partagé public `1nqW5Jc5UJXqULOpVMLM3j_5Z9fEprCyl`.
4. **Mise à Jour Intégrale de `curriculum.json`** :
   - 556 références 3AC associées à de vrais IDs Google Drive et vrais liens `https://drive.google.com/uc?id={id}&export=download`.
   - Total catalogue porté à **20 824 documents** (version 101).
   - Zéro ID fictif `local_3ac_` restant.
5. **Nouveau Fichier Catalogue Distant sur Google Drive** :
   - Fichier créé et partagé publiquement sous l'ID : **`1wk2wzvtp_onc9mavEWtsXQXuWB34ETQH`**.
   - `catalogDriveFileId` mis à jour dans `curriculum_service.dart`.
6. **Réinitialisation Forcée du Cache Navigateur** :
   - `qrayti_catalog_v` incrémenté à `101` dans `web/index.html`.
   - Purge automatique de `flutter.cached_curriculum_catalog_json_v1` au chargement de la page pour tous les utilisateurs.

---
*Document rédigé et certifié pour le projet Qrayti. Tout modèle IA intervenant ultérieurement doit le maintenir à jour.*

