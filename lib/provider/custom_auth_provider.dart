import 'package:flutter/material.dart';
import '../core/di/injection_container.dart';
import '../core/result/result.dart';
import '../domain/usecases/auth/login_usecase.dart';
import '../domain/usecases/auth/register_usecase.dart';
import '../domain/usecases/auth/logout_usecase.dart';
import '../other/network_alert.dart';
import '../provider/connectivity_provider.dart';
import '/backend/control_page.dart';

class CustomAuthProvider extends ChangeNotifier {
  static final CustomAuthProvider instance = CustomAuthProvider._();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CustomAuthProvider._();

  Future<void> registerWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    required String role,
    required ConnectivityController connectivityController,
  }) async {
    print('=== CUSTOM REGISTRATION STARTED ===');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Step 1: Executing register use case...');
      final registerUseCase = InjectionContainer.registerUseCase;
      final result = await registerUseCase(
        RegisterParams(
          email: email,
          password: password,
          role: role == 'lärare' ? 'teacher' : 'student',
        ),
      );

      await result.fold(
        onSuccess: (user) async {
          print('Registration SUCCESS: User created');
          
          _isLoading = false;
          notifyListeners();

          print('Step 2: Navigating to HomePage...');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
          print('=== CUSTOM REGISTRATION COMPLETED SUCCESSFULLY ===');
        },
        onFailure: (error) async {
          print('Registration FAILED: ${error.message}');
          _errorMessage = error.message;
          _isLoading = false;
          notifyListeners();

          // Handle specific errors
          if (error is NetworkError) {
            NetworkAlertPopup.show(context, connectivityController, () {
              registerWithEmail(
                context: context,
                email: email,
                password: password,
                role: role,
                connectivityController: connectivityController,
              );
            });
          } else if (error is ValidationError) {
            String title = 'Registreringsfel';
            String message = error.message ?? 'Ett fel uppstod vid registrering.';
            
            if (error.code == 'INVALID_DOMAIN') {
              title = 'Obehörig domän';
              message = 'Endast @algebraskolan.se eller @algebrautbildning.se är tillåtet.';
            } else if (error.code == 'EMAIL_ALREADY_IN_USE') {
              title = 'Konto finns redan';
              message = 'Detta konto är redan registrerat. Använd "Logga in" istället eller logga in med Google om du registrerat med Google.';
            } else if (error.code == 'WEAK_PASSWORD') {
              message = 'Lösenordet är för svagt.';
            } else if (error.code == 'INVALID_EMAIL') {
              message = 'Ogiltig e-postadress.';
            }
            
            _showErrorDialog(context, title, message);
          } else {
            _showErrorDialog(
              context,
              'Registreringsfel',
              error.message ?? 'Ett fel uppstod vid registrering.',
            );
          }
        },
      );
    } catch (e) {
      print('Unexpected error during registration: $e');
      _isLoading = false;
      _errorMessage = 'Ett oväntat fel uppstod';
      notifyListeners();
      
      _showErrorDialog(
        context,
        'Fel',
        'Ett oväntat fel uppstod. Försök igen senare.',
      );
    }
  }

  Future<void> loginWithEmail({
    required BuildContext context,
    required String email,
    required String password,
    required ConnectivityController connectivityController,
  }) async {
    print('=== CUSTOM LOGIN STARTED ===');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Step 1: Executing login use case...');
      final loginUseCase = InjectionContainer.loginUseCase;
      final result = await loginUseCase(
        LoginParams(
          email: email,
          password: password,
        ),
      );

      await result.fold(
        onSuccess: (user) async {
          print('Login SUCCESS: Signed in as ${user.email}');
          
          _isLoading = false;
          notifyListeners();

          print('Step 2: Navigating to HomePage...');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
          print('=== CUSTOM LOGIN COMPLETED SUCCESSFULLY ===');
        },
        onFailure: (error) async {
          print('Login FAILED: ${error.message}');
          _errorMessage = error.message;
          _isLoading = false;
          notifyListeners();

          // Handle specific errors
          if (error is NetworkError) {
            NetworkAlertPopup.show(context, connectivityController, () {
              loginWithEmail(
                context: context,
                email: email,
                password: password,
                connectivityController: connectivityController,
              );
            });
          } else if (error is ValidationError) {
            String title = 'Inloggningsfel';
            String message = error.message ?? 'Ett fel uppstod vid inloggning.';
            
            if (error.code == 'INVALID_DOMAIN') {
              title = 'Obehörig domän';
              message = 'Bara Algebraskolan mail är tillåtet.';
            } else if (error.code == 'INVALID_EMAIL') {
              message = 'Ogiltig e-postadress.';
            }
            
            _showErrorDialog(context, title, message);
          } else if (error is AuthenticationError) {
            String message = 'Fel e-postadress eller lösenord.';
            
            if (error.code == 'USER_NOT_FOUND') {
              message = 'Ingen användare hittades med denna e-postadress.';
            } else if (error.code == 'WRONG_PASSWORD') {
              message = 'Fel lösenord. Om du registrerade dig med Google, använd "Anslut med Google" istället.';
            } else if (error.code == 'TOO_MANY_REQUESTS') {
              message = 'För många försök. Försök igen senare.';
            }
            
            _showErrorDialog(context, 'Inloggningsfel', message);
          } else {
            _showErrorDialog(
              context,
              'Inloggningsfel',
              error.message ?? 'Ett fel uppstod vid inloggning.',
            );
          }
        },
      );
    } catch (e) {
      print('Unexpected error during login: $e');
      _isLoading = false;
      _errorMessage = 'Ett oväntat fel uppstod';
      notifyListeners();
      
      _showErrorDialog(
        context,
        'Fel',
        'Ett oväntat fel uppstod. Försök igen senare.',
      );
    }
  }

  Future<bool> setPasswordForCurrentUser({
    required String password,
  }) async {
    try {
      final authRepository = InjectionContainer.authRepository;
      final currentUser = authRepository.currentUser;
      
      if (currentUser == null) {
        print('No user currently signed in');
        return false;
      }

      // Use repository to update password
      final success = await authRepository.updatePassword(password);
      
      if (success) {
        print('Password successfully set for user: ${currentUser.email}');
        
        // Try to link email-password credential
        try {
          await authRepository.linkEmailPasswordCredential(
            email: currentUser.email!,
            password: password,
          );
          print('Email/password credential linked successfully');
        } catch (e) {
          // Credential might already be linked
          print('Credential linking result: $e');
        }
      }
      
      return success;
    } catch (e) {
      print('Error setting password: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final logoutUseCase = InjectionContainer.logoutUseCase;
      final result = await logoutUseCase();
      
      result.fold(
        onSuccess: (_) {
          print('Logout successful');
        },
        onFailure: (error) {
          print('Logout failed: ${error.message}');
        },
      );
    } catch (e) {
      print('Unexpected error during logout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}