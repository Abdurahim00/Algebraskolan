import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injectable.config.dart';

/// GetIt instance for dependency injection
final GetIt getIt = GetIt.instance;

/// Configure dependencies using injectable
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies({String? environment}) async {
  getIt.init(environment: environment);
}

/// Available environments
abstract class Environment {
  static const dev = 'dev';
  static const staging = 'staging';
  static const prod = 'prod';
  static const test = 'test';
}

/// Module for registering third-party dependencies
@module
abstract class RegisterModule {
  // This will be used with injectable_generator
  // Add third-party dependencies here
}