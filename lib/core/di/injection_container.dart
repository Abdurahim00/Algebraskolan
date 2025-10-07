import 'package:get_it/get_it.dart';

// Domain layer
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_student_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/repositories/i_user_repository.dart';

// Providers
import '../../provider/google_sign_In.dart';
import '../../provider/custom_auth_provider.dart';
import '../../provider/student_provider.dart';
import '../../provider/transaction_provider.dart';
import '../../provider/question_provider.dart';
import '../../provider/connectivity_provider.dart';

// Services
import '../../backend/student_service.dart';
import '../../backend/transaction_service.dart';
import '../../backend/auth_service.dart';
import '../../backend/coins_service.dart';
import '../../backend/sound_manager.dart';

// Use cases
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/google_login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/student/fetch_students_usecase.dart';
import '../../domain/usecases/student/search_students_usecase.dart';
import '../../domain/usecases/coins/update_coins_usecase.dart';
import '../../domain/usecases/coins/batch_update_coins_usecase.dart';
import '../../domain/usecases/coins/fetch_transactions_usecase.dart';
import '../../domain/usecases/fritids/register_fritids_pass_usecase.dart';
import '../../domain/usecases/fritids/get_today_fritids_registrations_usecase.dart';
import '../../domain/usecases/fritids/get_registrations_by_period_usecase.dart';
import '../../domain/usecases/fritids/get_fritids_statistics_usecase.dart';

/// Injection container for easy access to dependencies
/// This provides a cleaner API for accessing registered services
class InjectionContainer {
  static final GetIt _sl = GetIt.instance;
  
  // Repositories
  static IAuthRepository get authRepository => _sl<IAuthRepository>();
  static IStudentRepository get studentRepository => _sl<IStudentRepository>();
  static ITransactionRepository get transactionRepository => _sl<ITransactionRepository>();
  static IUserRepository get userRepository => _sl<IUserRepository>();
  
  // Providers
  static GoogleSignInProvider get googleSignInProvider => _sl<GoogleSignInProvider>();
  static CustomAuthProvider get customAuthProvider => _sl<CustomAuthProvider>();
  static StudentProvider get studentProvider => _sl<StudentProvider>();
  static TransactionProvider get transactionProvider => _sl<TransactionProvider>();
  static QuestionProvider get questionProvider => _sl<QuestionProvider>();
  static ConnectivityController get connectivityController => _sl<ConnectivityController>();
  
  // Services (Legacy)
  static StudentService get studentService => _sl<StudentService>();
  static TransactionService get transactionService => _sl<TransactionService>();
  static UserAuthService get authService => _sl<UserAuthService>();
  static CoinService get coinService => _sl<CoinService>();
  static SoundManager get soundManager => _sl<SoundManager>();
  
  // Use Cases - Auth
  static LoginUseCase get loginUseCase => _sl<LoginUseCase>();
  static RegisterUseCase get registerUseCase => _sl<RegisterUseCase>();
  static GoogleLoginUseCase get googleLoginUseCase => _sl<GoogleLoginUseCase>();
  static LogoutUseCase get logoutUseCase => _sl<LogoutUseCase>();
  
  // Use Cases - Student
  static FetchStudentsUseCase get fetchStudentsUseCase => _sl<FetchStudentsUseCase>();
  static SearchStudentsUseCase get searchStudentsUseCase => _sl<SearchStudentsUseCase>();
  
  // Use Cases - Coins
  static UpdateCoinsUseCase get updateCoinsUseCase => _sl<UpdateCoinsUseCase>();
  static BatchUpdateCoinsUseCase get batchUpdateCoinsUseCase => _sl<BatchUpdateCoinsUseCase>();
  static FetchTransactionsUseCase get fetchTransactionsUseCase => _sl<FetchTransactionsUseCase>();
  static GetTransactionStatsUseCase get transactionStatsUseCase => _sl<GetTransactionStatsUseCase>();

  // Use Cases - Fritids
  static RegisterFritidsPassUseCase get registerFritidsPassUseCase => _sl<RegisterFritidsPassUseCase>();
  static GetTodayFritidsRegistrationsUseCase get getTodayFritidsRegistrationsUseCase => _sl<GetTodayFritidsRegistrationsUseCase>();
  static GetRegistrationsByPeriodUseCase get getRegistrationsByPeriodUseCase => _sl<GetRegistrationsByPeriodUseCase>();
  static GetFritidsStatisticsUseCase get getFritidsStatisticsUseCase => _sl<GetFritidsStatisticsUseCase>();

  // Generic getter for any registered type
  static T get<T extends Object>() => _sl<T>();
  
  // Check if a type is registered
  static bool isRegistered<T extends Object>() => _sl.isRegistered<T>();
  
  // Reset the container (useful for testing)
  static Future<void> reset() async => await _sl.reset();
}