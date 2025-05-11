import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// To configure Firebase for your app:
/// 1. Go to Firebase Console (https://console.firebase.google.com/)
/// 2. Create a new project or select an existing one
/// 3. Add your app to the project (Android, iOS, Web)
/// 4. Download the configuration file (google-services.json for Android)
/// 5. Replace the placeholder values below with your actual Firebase configuration
/// 6. For Android: Place google-services.json in android/app/
/// 7. For iOS: Place GoogleService-Info.plist in ios/Runner/
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_r8_pYOO_9yo_T7rCdy7S2xvQYlN3boA',
    appId: '1:273191817418:web:df15dae70f687f21f7a433',
    messagingSenderId: '273191817418',
    projectId: 'gezzybuddy-77169',
    authDomain: 'gezzybuddy-77169.firebaseapp.com',
    storageBucket: 'gezzybuddy-77169.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_r8_pYOO_9yo_T7rCdy7S2xvQYlN3boA',
    appId: '1:273191817418:android:df15dae70f687f21f7a433',
    messagingSenderId: '273191817418',
    projectId: 'gezzybuddy-77169',
    storageBucket: 'gezzybuddy-77169.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'gezzybuddy',
    storageBucket: 'gezzybuddy.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.gezzybuddy',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'gezzybuddy',
    storageBucket: 'gezzybuddy.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.gezzybuddy',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'gezzybuddy',
    storageBucket: 'gezzybuddy.appspot.com',
  );
} 