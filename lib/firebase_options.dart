import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return const FirebaseOptions(
        apiKey: "AIzaSyCz-BuekIrud7R-c6XegCWGJpx_WgP98QY",
        appId: "1:149243887464:web:f5aae24352e930801b20dd",
        messagingSenderId: "149243887464",
        projectId: "diet-app-398cf",
        storageBucket: "diet-app-398cf.firebasestorage.app", // (없으면 비워도 됨)
      );
    }
    throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
  }
}