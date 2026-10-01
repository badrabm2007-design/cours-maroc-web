# 📚 MY POCKET / QRAYTI (قرايتي) — HISTORIQUE DU PROJET & DIRECTIVES POUR LES MODÈLES IA

---

> ## ⚠️ INSTRUCTION FONDAMENTALE ET OBLIGATOIRE POUR TOUTE IA (AI MODEL GUIDELINES)
> 
> **À TOUS LES MODÈLES D'INTELLIGENCE ARTIFICIELLE (Claude, GPT, Gemini, DeepSeek, etc.) INTERVENANT SUR CE PROJET :**
> 
> 1. **LECTURE PRÉALABLE OBLIGATOIRE** : Vous avez l'obligation absolue de lire l'intégralité de ce document avant d'examiner le code ou d'effectuer la moindre modification.
> 2. **RESPECT DES CONTRAINTES TECHNIQUES** : Vous devez scrupuleusement vous conformer aux architectures, protocoles réseau, gestionnaires de cache et solutions techniques documentés ci-dessous (notamment les règles CORS Google Drive, les quirks DNS IPv6 sous Windows, et la persistance de l'état du chronomètre).
> 3. **MISE À JOUR OBLIGATOIRE APRÈS CHAQUE INTERVENTION** : À la fin de chaque session ou tâche réalisée, vous devez **OBLIGATOIREMENT METTRE À JOUR CE FICHIER** en y ajoutant :
>    - Les modifications apportées (fichiers modifiés, fonctionnalités ajoutées ou corrigées).
>    - Les nouveaux problèmes techniques rencontrés et la solution exacte mise en œuvre.
>    - Les nouvelles instructions ou précautions utiles pour les prochaines IA.
> 4. **NE JAMAIS SUPPRIMER L'HISTORIQUE** : Conservez l'historique complet pour préserver la mémoire technique du projet.

---

## 1. Vue d'Ensemble & Identité du Projet

* **Noms du projet** :
  * Nom d'origine : **My Pocket** / **Cours Lycée Maroc**
  * Nom de marque officiel unifié : **Qrayti (قرايتي)** — *Excellence & Réussite • التميز الدراسي*
* **Domaine Web officiel en production** : [https://qrayti.online](https://qrayti.online)
* **Dépôts GitHub** :
  * Version Web : `badrabm2007-design/cours_web`
  * Version Windows Desktop : `badrabm2007-design/CoursMaroc-Windows`
  * Version Mobile : `flutter/app/cours`

### Structure de l'Écosystème Multi-Plateforme :
* **`cours/`** : Application Mobile Flutter (Android / iOS).
* **`cours_web/`** : Application Web PWA Flutter optimisée pour navigateurs desktop et mobiles, hébergée sur Netlify avec Cloud Functions.
* **`cours_windows/`** : Application Windows Desktop native 64-bit avec Runner C++.

---

## 2. Architecture Technique & Ressources

### 2.1. Stockage & Téléchargement des Documents
* **Hébergement Cloud** : Google Drive (compte de production : `babadre2007@gmail.com`).
* **Registre de traçabilité** : [`cours/scripts/data/registry.json`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours/scripts/data/registry.json) contient la liste des milliers de documents vérifiés avec leurs hachages cryptographiques SHA-256 (garantissant l'absence de doublons).
* **Catalogue dynamique unifié** : [`assets/data/curriculum.json`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours_web/assets/data/curriculum.json). Ce fichier est synchronisé entre `cours`, `cours_web` et `cours_windows`. Il structure l'arborescence :
  * `3eme-annee-college` (3AC) : Parcours BIOF et Général.
  * `tronc-commun` (TC) : Sciences BIOF, Lettres, Technologie.
  * `1ere-bac` (1BAC) : Sciences Expérimentales, Sciences Maths, SEG, Lettres, STE, STM.
  * `2eme-bac` (2BAC) : Sciences Physiques (PC), SVT, Sciences Maths A & B, Économie, SGC, Lettres, Sciences Humaines, STE, STM.

### 2.2. Lecteur PDF Intégré & Outils Pédagogiques
* Moteur de rendu : **Syncfusion Flutter PDF Viewer** (`SfPdfViewer.network`) combiné avec le worker `pdf.js` en mode Web.
* Boîte à outils d'annotations : Stylo numérique, surligneur haute précision, notes autocollantes déplaçables (*sticky notes*), gomme, gestion du zoom, bascule plein écran, recherche textuelle et boîte de dialogue de traduction instantanée (Français $\leftrightarrow$ Arabe).

### 2.3. Widget Pomodoro & Focus Timer Flottant
* Widget : [`FloatingFocusTimerBadge`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours_web/lib/widgets/floating_focus_timer.dart).
* Offre une gestion du temps d'étude (cycles de 25 min de travail / 5 min de pause) avec alertes sonores et animations discrètes.

---

## 3. Historique des Problèmes Rencontrés & Solutions Appliquées

### 🚨 Problème 1 : Blocage CORS Google Drive sur la Version Web
* **Symptôme** : Dans le navigateur, lors de l'ouverture d'un PDF, le lecteur affichait « Impossible de charger le document - Une erreur est survenue lors de la récupération du fichier », alors que le bouton « Ouvrir Drive » fonctionnait parfaitement dans un nouvel onglet.
* **Cause** : Google Drive (`drive.usercontent.google.com`) n'envoie pas d'en-tête `Access-Control-Allow-Origin: *`. Le moteur JavaScript `pdf.js` exécuté dans le navigateur subit donc un blocage CORS immédiat.
* **Solution** :
  1. En production Netlify : Création d'une fonction serverless [`netlify/functions/pdf.mts`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours_web/netlify/functions/pdf.mts) routée sur `/api/pdf?id=<ID>` qui télécharge le PDF côté serveur et le restitue avec les en-têtes CORS complets.
  2. En local (localhost) : Implémentation du même point de terminaison `/api/pdf?id=<ID>` dans le serveur de prévisualisation local Python [`local_server.py`](file:///C:/Users/HPi5book/.gemini/antigravity/brain/bd3f84ba-9bcb-4106-9898-a4830866baaa/scratch/local_server.py).
  3. Dans l'application Flutter ([`pdf_viewer_screen.dart`](file:///c:/Users/HPi5book/Desktop/flutter/app/cours_web/lib/screens/pdf_viewer_screen.dart)) : Mise en place d'un système de secours multi-paliers : tentative sur le proxy d'origine (`/api/pdf`) $\rightarrow$ repli automatique sur le proxy live `https://qrayti.online/api/pdf?id=...` $\rightarrow$ lien direct.

### 🚨 Problème 2 : Décalage / Sauts Abrupts du Widget Chronomètre entre les Pages
* **Symptôme** : Lors de la navigation entre l'Accueil, le détail d'une matière et le lecteur PDF, le chronomètre flottant sautait violemment de 61 pixels vers le bas (de $Y=9$ à $Y=70$) et de plus de 1 000 pixels horizontalement.
* **Cause** : L'ancien code recalculait dynamiquement des coordonnées dures différentes pour chaque écran (`ActiveDockingScreen`), écrasant la position à chaque transition de page avec un `Positioned` brut sans animation.
* **Solution** :
  1. Suppression du recalcul par écran : adoption d'une position unifiée et stable dans la barre d'en-tête ($Y=10\text{ px}$).
  2. Persistance globale : mémorisation de l'emplacement choisi par l'utilisateur tout au long de la session.
  3. Utilisation de `AnimatedPositioned(duration: 250ms, curve: Curves.easeOutCubic)` pour que tout recentrage ou redimensionnement glisse avec fluidité au lieu de sauter.

### 🚨 Problème 3 : Éléments d'Attente Indésirables au Démarrage
* **Symptôme** : Au premier chargement web, une barre de progression animée et une boîte générique avec la lettre "Q" donnaient l'impression que le site était lent ou bloqué.
* **Cause** : Le template HTML initial utilisait des classes CSS de chargement classique (`.cm-progress-bar`, `.cm-progress-fill`).
* **Solution** :
  1. Suppression totale des barres et roues de chargement.
  2. Remplacement par le **vrai logo officiel transparent Qrayti** (`icons/Icon-192.png?v=3`).
  3. Ajout d'une aura lumineuse respirante haut de gamme aux teintes émeraude et or royal avec fondu d'entrée et de sortie fluide, créant un écran d'accueil de marque luxueux similaire aux applications professionnelles modernes.

### 🚨 Problème 4 : Fausses Erreurs 404 sur les Cours de 3ème Année Collège (3AC)
* **Symptôme** : Dans la section 3AC, de nombreux liens renvoyaient une erreur 404 introuvable.
* **Cause** : Le fichier `curriculum.json` contenait 1 503 entrées fictives générées lors d'un scraping en mode simulation (`dry-run`) qui ne correspondaient à aucun fichier réel sur Drive.
* **Solution** :
  1. Récupération et téléversement des **47 documents authentiques locaux** depuis `C:\Users\HPi5book\Desktop\cours_maroc_downloads\3eme-annee-college` vers Google Drive (`babadre2007@gmail.com`).
  2. Purge des 1 503 entrées fictives de `curriculum.json`.
  3. Structuration propre des 47 documents vérifiés avec des titres arabes et français nets, soignés et des liens de téléchargement direct HTTP 200.

### 🚨 Problème 5 : Bug de Résolution DNS IPv6 sous Windows avec Netlify CLI
* **Symptôme** : Les commandes `netlify deploy` ou `netlify link` échouaient sous Windows avec des erreurs `ENOTFOUND api.netlify.com` ou des blocages indéfinis.
* **Cause** : Node.js sur Windows privilégie par défaut les adresses IPv6 non routées par certains FAI.
* **Solution** : Définir systématiquement la variable d'environnement :
  ```powershell
  $env:NODE_OPTIONS="--dns-result-order=ipv4first"
  ```
  ou sous CMD :
  ```cmd
  set NODE_OPTIONS=--dns-result-order=ipv4first
  ```

### 🚨 Problème 6 : Déconnexion TCP sur les Gros Téléversements GitHub (>15 Mo)
* **Symptôme** : Le téléversement direct de binaires supérieurs à 15 Mo vers `uploads.github.com` via scripts HTTP échouait par coupure réseau.
* **Solution** : Créer les releases GitHub via l'utilitaire `gh release create`, et générer l'archive zip autonome Windows directement sur le bureau (`Desktop\Qrayti_Logos\Qrayti_Windows_v1.2.0.zip`) pour une distribution rapide et sûre.

---

## 4. Instructions Pratiques & Commandes de Déploiement

### 4.1. Tester en Local (Prévisualisation Web sur Localhost)
Pour lancer le serveur local de test avec le proxy PDF Google Drive intégré :
```powershell
python "C:\Users\HPi5book\.gemini\antigravity\brain\bd3f84ba-9bcb-4106-9898-a4830866baaa\scratch\local_server.py"
```
Accès : **`http://localhost:8080/`**

### 4.2. Compiler la Version Web
Dans le dossier `c:\Users\HPi5book\Desktop\flutter\app\cours_web` :
```powershell
flutter build web --release
```

### 4.3. Déployer la Version Web sur Netlify en Production
```powershell
$env:NODE_OPTIONS="--dns-result-order=ipv4first"
netlify deploy --prod --dir=build/web
```

### 4.4. Compiler la Version Windows Desktop
Dans le dossier `c:\Users\HPi5book\Desktop\flutter\app\cours_windows` :
```powershell
flutter build windows --release
```
L'exécutable généré se trouve dans :
`build\windows\x64\runner\Release\cours_windows.exe`

---

## 5. Journal des Versions (Changelog)

### Version 1.2.1 (01/10/2026) :
* **Web** :
  * Nouveau Splash Screen de marque luxueux avec le logo officiel transparent `icons/Icon-192.png`.
  * Suppression totale de toute barre ou cercle de chargement / attente.
  * Stabilisation définitive du widget chronomètre (ancrage fixe $Y=10$, zéro décalage, persistance globale et transition `AnimatedPositioned`).
  * Visualiseur PDF enrichi d'un proxy local et d'un repli multi-paliers évitant les erreurs CORS.
  * Intégration complète et validée des 47 documents de 3ème Année Collège (3AC) sur Google Drive.
  * Purge des 1 503 entrées fictives du catalogue.
* **Windows** :
  * Déploiement de la version Desktop v1.2.0 empaquetée en ZIP autonome.
* **Général** :
  * Rebranding unifié en **Qrayti (قرايتي)** sur l'ensemble de la documentation et des interfaces.

---
*Ce document doit être obligatoirement tenu à jour par chaque assistant IA intervenant sur le projet.*
