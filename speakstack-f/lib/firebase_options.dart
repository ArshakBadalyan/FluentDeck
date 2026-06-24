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
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbKYFbpCfjnLeo2GaxZy_lqpRBTsoW35E',
    appId: '1:749772344507:android:0b78462fb6a8031754ad9e',
    messagingSenderId: '749772344507',
    projectId: 'math-project-370321',
    storageBucket: 'math-project-370321.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBRYQGNCvTPnEAvcBsbVO3uvYYND7CBovY',
    appId: '1:749772344507:ios:68f0c8def915a57b54ad9e',
    messagingSenderId: '749772344507',
    projectId: 'math-project-370321',
    storageBucket: 'math-project-370321.firebasestorage.app',
    iosBundleId: 'io.framework7.f7math',
  );

  // TODO: Replace apiKey with your Firebase Web API key from the Firebase console.
  // Go to: Firebase Console > Project Settings > General > Your apps > Web app
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBUZDQ5PklmRzq3I1F75eQ8IkGtPX3IICY',
    appId: '1:749772344507:web:cb6e2a8e3ef0082654ad9e',
    messagingSenderId: '749772344507',
    projectId: 'math-project-370321',
    storageBucket: 'math-project-370321.firebasestorage.app',
    authDomain: 'math-project-370321.firebaseapp.com',
  );
}
