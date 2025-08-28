import '../../core/result/result.dart';

/// Base class for all use cases
/// Follows the Command pattern for executing business logic
abstract class BaseUseCase<Type, Params> {
  /// Execute the use case
  Future<Result<Type>> call(Params params);
}

/// Base class for use cases that don't require parameters
abstract class NoParamsUseCase<Type> {
  /// Execute the use case without parameters
  Future<Result<Type>> call();
}

/// Base class for synchronous use cases
abstract class SyncUseCase<Type, Params> {
  /// Execute the use case synchronously
  Result<Type> call(Params params);
}

/// Base class for stream use cases
abstract class StreamUseCase<Type, Params> {
  /// Execute the use case and return a stream
  Stream<Result<Type>> call(Params params);
}

/// Marker class for use cases that don't need parameters
class NoParams {
  const NoParams();
}

/// Base class for use case parameters
abstract class Params {
  const Params();
  
  /// Convert parameters to a map for logging or debugging
  Map<String, dynamic> toMap();
}