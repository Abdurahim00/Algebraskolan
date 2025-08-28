import 'package:injectable/injectable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Module for Firebase services
/// Provides singleton instances of Firebase services
@module
abstract class FirebaseModule {
  
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;
  
  @lazySingleton
  FirebaseFirestore get firebaseFirestore => FirebaseFirestore.instance;
  
  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn();
  
  @lazySingleton
  FirebaseRemoteConfig get firebaseRemoteConfig => FirebaseRemoteConfig.instance;
}