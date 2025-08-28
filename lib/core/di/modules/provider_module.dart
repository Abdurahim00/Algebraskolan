import 'package:injectable/injectable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import existing providers
import '../../../provider/google_sign_In.dart';
import '../../../provider/custom_auth_provider.dart';
import '../../../provider/student_provider.dart';
import '../../../provider/transaction_provider.dart';
import '../../../provider/question_provider.dart';
import '../../../provider/connectivity_provider.dart';

/// Module for registering providers
/// Manages all provider dependencies
@module
abstract class ProviderModule {
  
  /// Google Sign In Provider - Singleton
  @lazySingleton
  GoogleSignInProvider get googleSignInProvider => GoogleSignInProvider.instance;
  
  /// Custom Auth Provider - Singleton
  @lazySingleton
  CustomAuthProvider get customAuthProvider => CustomAuthProvider.instance;
  
  /// Student Provider - Factory (new instance each time)
  @injectable
  StudentProvider get studentProvider => StudentProvider();
  
  /// Transaction Provider - Factory
  @injectable
  TransactionProvider transactionProvider(GoogleSignInProvider googleSignInProvider) => 
      TransactionProvider(uid: null, googleSignInProvider: googleSignInProvider);
  
  /// Question Provider - Factory
  @injectable
  QuestionProvider get questionProvider => QuestionProvider();
  
  /// Connectivity Controller - Singleton
  @lazySingleton
  ConnectivityController get connectivityController => ConnectivityController();
}