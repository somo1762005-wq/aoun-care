import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web platform is not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // 👈 الإعدادات الحقيقية والمأخوذة من ملف الـ JSON الخاص بمشروعك "عوْن"
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAgwU3b2bnkZTkRZ8OTByoptWX2MiC-yeE', // أخذناه من current_key
    appId: '1:147780489912:android:2c152c292ff418b39f1a4d', // أخذناه من mobilesdk_app_id
    messagingSenderId: '147780489912', // أخذناه من project_number
    projectId: 'aoun-49e7e', // أخذناه من project_id
    storageBucket: 'aoun-49e7e.firebasestorage.app', // أخذناه من storage_bucket
  );
}