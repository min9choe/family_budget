import 'package:firebase_core/firebase_core.dart';

/// Firebase 설정값은 소스에 넣지 않고 빌드할 때 --dart-define 으로 주입합니다.
/// (GitHub Actions에서는 저장소 Secrets 값이 자동으로 들어갑니다. README 참고)
class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
  );
}
