import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const bool isConfigured = false;

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured yet. Replace this placeholder with '
      'generated FlutterFire options and set isConfigured = true.',
    );
  }
}
