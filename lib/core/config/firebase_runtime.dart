import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hosh/firebase_options.dart';

FirebaseOptions? resolveFirebaseOptions() {
  if (kIsWeb) {
    return null;
  }

  try {
    return DefaultFirebaseOptions.currentPlatform;
  } on UnsupportedError {
    return null;
  }
}
