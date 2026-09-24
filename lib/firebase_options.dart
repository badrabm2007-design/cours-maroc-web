import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCwi9aQRpyvKyaY-5Jbal__E7KvOwM6SAM',
    appId: '1:555535888410:web:c5b074fe43e2413221a1a3',
    messagingSenderId: '555535888410',
    projectId: 'cours-maroc-app',
    authDomain: 'cours-maroc-app.firebaseapp.com',
    storageBucket: 'cours-maroc-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCV47P6BJgtuLxKYhSLFRCNrjOYuoUrMnc',
    appId: '1:555535888410:android:e1fe7759e3a54d4e21a1a3',
    messagingSenderId: '555535888410',
    projectId: 'cours-maroc-app',
    storageBucket: 'cours-maroc-app.firebasestorage.app',
  );
}
