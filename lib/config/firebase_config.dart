import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const String devProjectId = 'algebra-dev';
  static const String prodProjectId = 'algebra-82c5d';

  static const String devStorageBucket = 'algebra-dev.appspot.com';
  static const String prodStorageBucket = 'algebra-82c5d.firebasestorage.app';

  static const String devDatabaseUrl = 'https://algebra-dev.firebaseio.com';
  static const String prodDatabaseUrl = 'https://algebra-82c5d-default-rtdb.europe-west1.firebasedatabase.app';

  static FirebaseOptions getDevOptions() {
    return const FirebaseOptions(
      apiKey: 'AIzaSyCvUSW8MQvtqzX799jD1q_VbslmVZzaOxo',
      appId: '1:508884989833:android:49fcbff4c7bfc619a51358',
      messagingSenderId: '508884989833',
      projectId: devProjectId,
      storageBucket: devStorageBucket,
    );
  }

  static FirebaseOptions getProdOptions() {
    return const FirebaseOptions(
      apiKey: 'AIzaSyAkjr0gCk-FRGj5bwSVoju4iXHfg6OqgyQ',
      appId: '1:195764286049:android:cc8d9098cc2d15700d3020',
      messagingSenderId: '195764286049',
      projectId: prodProjectId,
      storageBucket: prodStorageBucket,
      databaseURL: prodDatabaseUrl,
    );
  }

  static FirebaseOptions getOptionsForEnvironment(String environment) {
    switch (environment) {
      case 'dev':
      case 'development':
        return getDevOptions();
      case 'prod':
      case 'production':
      default:
        return getProdOptions();
    }
  }
}