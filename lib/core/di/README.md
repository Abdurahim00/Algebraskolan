# Dependency Injection Architecture

## Overview
This app uses **get_it** for dependency injection with **injectable** for code generation.

## Structure

### Service Locator (`service_locator.dart`)
Main configuration file that registers all dependencies:
- External dependencies (Firebase services)
- Repositories (implementing domain interfaces)
- Services (legacy, being migrated)
- Providers (state management)

### Injection Container (`injection_container.dart`)
Provides a clean API for accessing registered dependencies:
```dart
// Access repositories
final authRepo = InjectionContainer.authRepository;

// Access providers
final studentProvider = InjectionContainer.studentProvider;

// Generic access
final myService = InjectionContainer.get<MyService>();
```

### Modules
Organized registration of dependencies:
- `firebase_module.dart` - Firebase services
- `provider_module.dart` - State management providers
- `service_module.dart` - Legacy services

## Usage

### In Widgets
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authRepo = InjectionContainer.authRepository;
    // Use repository
  }
}
```

### In Providers
```dart
class MyProvider extends ChangeNotifier {
  final IStudentRepository _repository;
  
  MyProvider() : _repository = InjectionContainer.studentRepository;
}
```

### For Testing
```dart
setUp(() async {
  await InjectionContainer.reset();
  // Register test doubles
  sl.registerLazySingleton<IAuthRepository>(() => MockAuthRepository());
});
```

## Registration Types

### Singleton
Single instance throughout app lifetime:
```dart
@lazySingleton
class MyService {}
```

### Factory
New instance every time:
```dart
@injectable
class MyController {}
```

## Environment Configuration
Run with different environments:
```bash
# Development
flutter run --dart-define=ENVIRONMENT=development

# Production
flutter run --dart-define=ENVIRONMENT=production

# Testing
flutter test --dart-define=ENVIRONMENT=test
```

## Migration Strategy

### Phase 1 ✅
- Setup dependency injection infrastructure
- Register all existing services
- Maintain backward compatibility

### Phase 2 (Current)
- Gradually replace direct instantiation with DI
- Refactor providers to use repositories
- Remove Firebase dependencies from business logic

### Phase 3 (Future)
- Complete migration to clean architecture
- Remove legacy services
- Full testability with mocked dependencies