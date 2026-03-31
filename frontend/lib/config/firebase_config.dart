import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration loaded from environment variables via --dart-define.
///
/// Usage (run/build):
///   flutter run \
///     --dart-define=FIREBASE_PROJECT_ID=your-id \
///     --dart-define=FIREBASE_API_KEY=your-key \
///     --dart-define=FIREBASE_AUTH_DOMAIN=your-id.firebaseapp.com \
///     --dart-define=FIREBASE_STORAGE_BUCKET=your-id.appspot.com \
///     --dart-define=FIREBASE_MESSAGING_SENDER_ID=000000000 \
///     --dart-define=FIREBASE_APP_ID=1:000:web:000 \
///     --dart-define=BACKEND_API_URL=http://localhost:3000
class FirebaseConfig {
  FirebaseConfig._();

  static const String projectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String apiKey =
      String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String authDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
  static const String storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static const String messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String appId =
      String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
  static const String backendUrl =
      String.fromEnvironment('BACKEND_API_URL', defaultValue: 'http://localhost:3000');

  /// FirebaseOptions built from env vars (used for web / manual init).
  static FirebaseOptions get options => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain,
        storageBucket: storageBucket,
      );

  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    // On Android/iOS google-services.json / GoogleService-Info.plist is used
    // automatically by the FlutterFire plugins — no manual options needed.
    // On web we pass options explicitly.
    if (kIsWeb) {
      await Firebase.initializeApp(options: options);
    } else {
      await Firebase.initializeApp();
    }
  }
}
