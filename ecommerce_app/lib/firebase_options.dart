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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDs7uoipWX_1JHt05iho9XIjJNBF1zHXcY',
    appId: '1:383889169119:web:b9601edf164231eda6e76a',
    messagingSenderId: '383889169119',
    projectId: 'my-ecommerce-app-32',
    authDomain: 'my-ecommerce-app-32.firebaseapp.com',
    storageBucket: 'my-ecommerce-app-32.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCMzHMfoMxTrRKKyZRXwMtJU3fEqzGXMpI',
    appId: '1:383889169119:android:1fb551ddbd209d0fa6e76a',
    messagingSenderId: '383889169119',
    projectId: 'my-ecommerce-app-32',
    storageBucket: 'my-ecommerce-app-32.firebasestorage.app',
  );

}