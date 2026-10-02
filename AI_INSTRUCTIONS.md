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
  Le push vers GitHub (`main -> main`) s'effectue alors immédiatement en ~1 seconde sans blocage.

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

## 6. Consignes Spécifiques pour les Prochaines Mises à Jour

* **Gestion du Catalogue 3AC** : Si de nouveaux documents PDF 3AC sont ajoutés, utilisez le script [`cours/scripts/upload_local_to_drive.py`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours/scripts/upload_local_to_drive.py) pour les téléverser sur Google Drive et les enregistrer dans `registry.json` et `curriculum.json`.
* **Cohérence Multi-Projets** : Toute modification apportée au catalogue `curriculum.json` ou aux widgets partagés (`floating_focus_timer.dart`, `pdf_viewer_screen.dart`) doit être répliquée sur les 3 projets (`cours`, `cours_web`, `cours_windows`).
* **Respect de la Demande Utilisateur** : Toujours demander l'autorisation de l'utilisateur avant d'exécuter un push vers GitHub ou un déploiement public si l'utilisateur est en cours de prévisualisation locale.

---
*Document rédigé et certifié pour le projet Qrayti. Tout modèle IA intervenant ultérieurement doit le maintenir à jour.*
