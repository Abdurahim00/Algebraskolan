/// Result pattern for handling success and failure states
/// Provides a functional approach to error handling
abstract class Result<T> {
  const Result();

  /// Returns true if the result is a success
  bool get isSuccess => this is Success<T>;

  /// Returns true if the result is a failure
  bool get isFailure => this is Failure<T>;

  /// Get the value if success, otherwise returns null
  T? get valueOrNull => isSuccess ? (this as Success<T>).value : null;

  /// Get the error if failure, otherwise returns null
  AppError? get errorOrNull => isFailure ? (this as Failure<T>).error : null;

  /// Transform the result value if success
  Result<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      return Success(transform((this as Success<T>).value));
    } else {
      return Failure((this as Failure<T>).error);
    }
  }

  /// Transform the result with a function that returns a Result
  Result<R> flatMap<R>(Result<R> Function(T) transform) {
    if (isSuccess) {
      return transform((this as Success<T>).value);
    } else {
      return Failure((this as Failure<T>).error);
    }
  }

  /// Execute a function based on success or failure
  R fold<R>({
    required R Function(T) onSuccess,
    required R Function(AppError) onFailure,
  }) {
    if (isSuccess) {
      return onSuccess((this as Success<T>).value);
    } else {
      return onFailure((this as Failure<T>).error);
    }
  }

  /// Execute a side effect when successful
  Result<T> onSuccess(void Function(T) action) {
    if (isSuccess) {
      action((this as Success<T>).value);
    }
    return this;
  }

  /// Execute a side effect when failed
  Result<T> onFailure(void Function(AppError) action) {
    if (isFailure) {
      action((this as Failure<T>).error);
    }
    return this;
  }

  /// Get the value or throw the error
  T getOrThrow() {
    if (isSuccess) {
      return (this as Success<T>).value;
    } else {
      throw (this as Failure<T>).error;
    }
  }

  /// Get the value or return a default
  T getOrDefault(T defaultValue) {
    if (isSuccess) {
      return (this as Success<T>).value;
    } else {
      return defaultValue;
    }
  }
}

/// Represents a successful result
class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success(value: $value)';
}

/// Represents a failed result
class Failure<T> extends Result<T> {
  final AppError error;

  const Failure(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure(error: $error)';
}

/// Base class for application errors
class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError(code: $code, message: $message)';
}

/// Common error types
class NetworkError extends AppError {
  const NetworkError({
    String message = 'Nätverksfel uppstod',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'NETWORK_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class AuthenticationError extends AppError {
  const AuthenticationError({
    String message = 'Autentiseringsfel',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'AUTH_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class ValidationError extends AppError {
  const ValidationError({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'VALIDATION_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class NotFoundError extends AppError {
  const NotFoundError({
    String message = 'Resursen hittades inte',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'NOT_FOUND',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class PermissionError extends AppError {
  const PermissionError({
    String message = 'Du har inte behörighet',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'PERMISSION_DENIED',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class UnauthorizedError extends AppError {
  const UnauthorizedError({
    String message = 'Obehörig åtkomst',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'UNAUTHORIZED',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}

class UnknownError extends AppError {
  const UnknownError({
    String message = 'Ett oväntat fel uppstod',
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? 'UNKNOWN_ERROR',
          originalError: originalError,
          stackTrace: stackTrace,
        );
}