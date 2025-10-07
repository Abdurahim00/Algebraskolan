import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

// Domain layer
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_student_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../../domain/repositories/i_fritids_repository.dart';

// Data layer
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_student_repository.dart';
import '../../data/repositories/firestore_transaction_repository.dart';
import '../../data/repositories/firestore_user_repository.dart';
import '../../data/repositories/firestore_fritids_repository.dart';

// Services (existing)
import '../../backend/student_service.dart';
import '../../backend/transaction_service.dart';
import '../../backend/auth_service.dart';
import '../../backend/coins_service.dart';
import '../../backend/sound_manager.dart';

// Providers
import '../../provider/google_sign_In.dart';
import '../../provider/custom_auth_provider.dart';
import '../../provider/student_provider.dart';
import '../../provider/transaction_provider.dart';
import '../../provider/question_provider.dart';
import '../../provider/connectivity_provider.dart';

// Use cases - Auth
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/google_login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';

// Use cases - Student
import '../../domain/usecases/student/fetch_students_usecase.dart';
import '../../domain/usecases/student/search_students_usecase.dart';

// Use cases - Coins
import '../../domain/usecases/coins/update_coins_usecase.dart';
import '../../domain/usecases/coins/batch_update_coins_usecase.dart';
import '../../domain/usecases/coins/fetch_transactions_usecase.dart';

// Use cases - Fritids
import '../../domain/usecases/fritids/register_fritids_pass_usecase.dart';
import '../../domain/usecases/fritids/get_today_fritids_registrations_usecase.dart';
import '../../domain/usecases/fritids/get_registrations_by_period_usecase.dart';
import '../../domain/usecases/fritids/get_fritids_statistics_usecase.dart';

/// Service locator instance
final GetIt sl = GetIt.instance;

/// Initialize all dependencies
Future<void> setupServiceLocator() async {
  // External dependencies
  _registerExternalDependencies();
  
  // Repositories
  _registerRepositories();
  
  // Services
  _registerServices();
  
  // Use cases
  _registerUseCases();
  
  // Providers
  _registerProviders();
}

void _registerExternalDependencies() {
  // Firebase instances (Singleton)
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  sl.registerLazySingleton<FirebaseRemoteConfig>(() => FirebaseRemoteConfig.instance);
}

void _registerRepositories() {
  // Auth Repository
  sl.registerLazySingleton<IAuthRepository>(
    () => FirebaseAuthRepository(
      firebaseAuth: sl<FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
  
  // Student Repository
  sl.registerLazySingleton<IStudentRepository>(
    () => FirestoreStudentRepository(
      firestore: sl<FirebaseFirestore>(),
    ),
  );
  
  // Transaction Repository
  sl.registerLazySingleton<ITransactionRepository>(
    () => FirestoreTransactionRepository(
      firestore: sl<FirebaseFirestore>(),
    ),
  );
  
  // User Repository
  sl.registerLazySingleton<IUserRepository>(
    () => FirestoreUserRepository(
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  // Fritids Repository
  sl.registerLazySingleton<IFritidsRepository>(
    () => FirestoreFritidsRepository(
      firestore: sl<FirebaseFirestore>(),
    ),
  );
}

void _registerServices() {
  // Legacy services (keeping for backward compatibility during migration)
  sl.registerLazySingleton<StudentService>(
    () => StudentService(sl<FirebaseFirestore>()),
  );
  
  sl.registerLazySingleton<TransactionService>(
    () => TransactionService(firestore: sl<FirebaseFirestore>()),
  );
  
  sl.registerLazySingleton<UserAuthService>(
    () => UserAuthService(),
  );
  
  sl.registerLazySingleton<CoinService>(
    () => CoinService(sl<FirebaseFirestore>()),
  );
  
  // Sound Manager (Singleton)
  sl.registerLazySingleton<SoundManager>(
    () => SoundManager(),
  );
}

void _registerProviders() {
  // Google Sign In Provider (Singleton)
  sl.registerLazySingleton<GoogleSignInProvider>(
    () => GoogleSignInProvider.instance,
  );
  
  // Custom Auth Provider (Singleton)
  sl.registerLazySingleton<CustomAuthProvider>(
    () => CustomAuthProvider.instance,
  );
  
  // Student Provider (Singleton - same instance throughout app lifecycle)
  sl.registerLazySingleton<StudentProvider>(
    () => StudentProvider(),
  );
  
  // Transaction Provider (Factory)
  sl.registerFactory<TransactionProvider>(
    () => TransactionProvider(
      uid: null, // Will be set when needed
      googleSignInProvider: sl<GoogleSignInProvider>(),
    ),
  );
  
  // Question Provider (Factory)
  sl.registerFactory<QuestionProvider>(
    () => QuestionProvider(),
  );
  
  // Connectivity Controller (Singleton)
  sl.registerLazySingleton<ConnectivityController>(
    () => ConnectivityController(),
  );
}

void _registerUseCases() {
  // Authentication use cases
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(
      sl<IAuthRepository>(),
      sl<IUserRepository>(),
      sl<FirebaseRemoteConfig>(),
    ),
  );
  
  sl.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(
      sl<IAuthRepository>(),
      sl<IUserRepository>(),
      sl<FirebaseRemoteConfig>(),
    ),
  );
  
  sl.registerLazySingleton<GoogleLoginUseCase>(
    () => GoogleLoginUseCase(
      sl<IAuthRepository>(),
      sl<IUserRepository>(),
      sl<FirebaseRemoteConfig>(),
    ),
  );
  
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<IAuthRepository>()),
  );
  
  // Student use cases
  sl.registerLazySingleton<FetchStudentsUseCase>(
    () => FetchStudentsUseCase(sl<IStudentRepository>()),
  );
  
  sl.registerLazySingleton<SearchStudentsUseCase>(
    () => SearchStudentsUseCase(sl<IStudentRepository>()),
  );
  
  // Coin transaction use cases
  sl.registerLazySingleton<UpdateCoinsUseCase>(
    () => UpdateCoinsUseCase(
      sl<IStudentRepository>(),
      sl<ITransactionRepository>(),
      sl<IAuthRepository>(),
    ),
  );
  
  sl.registerLazySingleton<BatchUpdateCoinsUseCase>(
    () => BatchUpdateCoinsUseCase(
      sl<IStudentRepository>(),
      sl<ITransactionRepository>(),
    ),
  );
  
  sl.registerLazySingleton<FetchTransactionsUseCase>(
    () => FetchTransactionsUseCase(sl<ITransactionRepository>()),
  );
  
  sl.registerLazySingleton<GetTransactionStatsUseCase>(
    () => GetTransactionStatsUseCase(sl<ITransactionRepository>()),
  );

  // Fritids use cases
  sl.registerLazySingleton<RegisterFritidsPassUseCase>(
    () => RegisterFritidsPassUseCase(
      sl<IFritidsRepository>(),
      sl<IStudentRepository>(),
      sl<IAuthRepository>(),
    ),
  );

  sl.registerLazySingleton<GetTodayFritidsRegistrationsUseCase>(
    () => GetTodayFritidsRegistrationsUseCase(sl<IFritidsRepository>()),
  );

  sl.registerLazySingleton<GetRegistrationsByPeriodUseCase>(
    () => GetRegistrationsByPeriodUseCase(sl<IFritidsRepository>()),
  );

  sl.registerLazySingleton<GetFritidsStatisticsUseCase>(
    () => GetFritidsStatisticsUseCase(sl<IFritidsRepository>()),
  );
}

/// Reset service locator (useful for testing)
Future<void> resetServiceLocator() async {
  await sl.reset();
}

/// Check if a service is registered
bool isRegistered<T extends Object>() {
  return sl.isRegistered<T>();
}

/// Get a service from the locator
T getService<T extends Object>() {
  return sl.get<T>();
}