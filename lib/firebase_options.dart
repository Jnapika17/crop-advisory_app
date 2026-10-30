import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return web;
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase is not configured for the Fuchsia platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDNH30-lWiqfT9W79KQ2A2EYQMkEx2eQzc',
    authDomain: 'crop-advisory-c8f95.firebaseapp.com',
    projectId: 'crop-advisory-c8f95',
    storageBucket: 'crop-advisory-c8f95.firebasestorage.app',
    messagingSenderId: '1022009310885',
    appId: '1:1022009310885:web:625b447543c0eb589a574c',
    measurementId: 'G-HXFFNZVBFZ',
  );
}
