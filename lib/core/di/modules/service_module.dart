import 'package:injectable/injectable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import existing services
import '../../../backend/student_service.dart';
import '../../../backend/transaction_service.dart';
import '../../../backend/auth_service.dart';
import '../../../backend/coins_service.dart';
import '../../../backend/sound_manager.dart';

/// Module for registering legacy services
/// These will be gradually replaced with repositories and use cases
@module
abstract class ServiceModule {
  
  /// Student Service - Legacy service for backward compatibility
  @lazySingleton
  StudentService studentService(FirebaseFirestore firestore) => 
      StudentService(firestore);
  
  /// Transaction Service - Legacy service
  @lazySingleton
  TransactionService transactionService(FirebaseFirestore firestore) => 
      TransactionService(firestore: firestore);
  
  /// User Auth Service - Legacy service
  @lazySingleton
  UserAuthService get userAuthService => UserAuthService();
  
  /// Coins Service - Legacy service
  @lazySingleton
  CoinService coinService(FirebaseFirestore firestore) => 
      CoinService(firestore);
  
  /// Sound Manager - Singleton for audio management
  @lazySingleton
  SoundManager get soundManager => SoundManager();
}