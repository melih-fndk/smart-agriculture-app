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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDKaHY6y7FESOVXv-VhnGxSlW5J7CjMZCg',
    appId: '1:1035276027199:web:4b9e2948392952bf377f8a',
    messagingSenderId: '1035276027199',
    projectId: 'tarimus-db',
    authDomain: 'tarimus-db.firebaseapp.com',
    storageBucket: 'tarimus-db.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBPdYpzUKWaMx1oIZWr_wRP-hcTRy8bxSM',
    appId: '1:1035276027199:android:ea17244c879cb6cd377f8a',
    messagingSenderId: '1035276027199',
    projectId: 'tarimus-db',
    storageBucket: 'tarimus-db.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDAzdW5yi1OhuB4wSokm3WEW7VzR_knC2M',
    appId: '1:1035276027199:ios:1c8ab418d460155c377f8a',
    messagingSenderId: '1035276027199',
    projectId: 'tarimus-db',
    storageBucket: 'tarimus-db.firebasestorage.app',
    iosBundleId: 'com.example.tarimus',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDAzdW5yi1OhuB4wSokm3WEW7VzR_knC2M',
    appId: '1:1035276027199:ios:1c8ab418d460155c377f8a',
    messagingSenderId: '1035276027199',
    projectId: 'tarimus-db',
    storageBucket: 'tarimus-db.firebasestorage.app',
    iosBundleId: 'com.example.tarimus',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDKaHY6y7FESOVXv-VhnGxSlW5J7CjMZCg',
    appId: '1:1035276027199:web:9e222d0de6b9761d377f8a',
    messagingSenderId: '1035276027199',
    projectId: 'tarimus-db',
    authDomain: 'tarimus-db.firebaseapp.com',
    storageBucket: 'tarimus-db.firebasestorage.app',
  );
}
