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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDolZI2Hz85EJ2DLTmJ-ixZC2zfN6819xU',
    appId: '1:570949749316:web:3a08b6bcab8673fff60a11',
    messagingSenderId: '570949749316',
    projectId: 'noti-c3136',
    authDomain: 'noti-c3136.firebaseapp.com',
    storageBucket: 'noti-c3136.firebasestorage.app',
    measurementId: 'G-V82L925JDV',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAXWyI-OdtDSf8urXPFWyocUeEJvFPNIRc',
    appId: '1:570949749316:ios:b9e49eeda0ac33f3f60a11',
    messagingSenderId: '570949749316',
    projectId: 'noti-c3136',
    storageBucket: 'noti-c3136.firebasestorage.app',
    iosBundleId: 'com.example.notiFlutterConverted',
  );
}
