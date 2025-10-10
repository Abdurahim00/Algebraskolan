import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/di/injection_container.dart';
import '../core/result/result.dart';
import '../domain/usecases/auth/google_login_usecase.dart';
import '../domain/usecases/auth/logout_usecase.dart';
import '../domain/usecases/base_usecase.dart';
import '../other/network_alert.dart';
import '../provider/connectivity_provider.dart';
import '/backend/control_page.dart';

class GoogleSignInProvider extends ChangeNotifier {
  static final GoogleSignInProvider instance = GoogleSignInProvider._();
  
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _user;
  bool _isLoading = false;
  String? _errorMessage;

  GoogleSignInAccount? get user => _user;
  String? get uid => InjectionContainer.authRepository.currentUser?.uid;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  GoogleSignInProvider._();

  Future<void> googleLogin(BuildContext context,
      ConnectivityController connectivityController) async {
    print('=== GOOGLE LOGIN STARTED ===');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Start Google Sign-In with timeout
      print('Step 1: Starting Google Sign-In...');
      final googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Google Sign-In timed out after 15 seconds');
          return null;
        },
      );
      if (googleUser == null) {
        print('Step 1 FAILED: User cancelled Google Sign-In or timeout');
        _isLoading = false;
        notifyListeners();
        return;
      }
      print('Step 1 SUCCESS: Google user signed in: ${googleUser.email}');
      _user = googleUser;
      notifyListeners();

      // Step 2: Get authentication credentials
      print('Step 2: Getting authentication credentials...');
      final googleAuth = await googleUser.authentication;

      // Check if tokens are available
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('ERROR: Google auth tokens are null');
        _errorMessage = 'Authentication failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Step 3: Use GoogleLoginUseCase
      print('Step 3: Executing Google login use case...');
      final googleLoginUseCase = InjectionContainer.googleLoginUseCase;
      final result = await googleLoginUseCase(
        GoogleLoginParams(
          accessToken: googleAuth.accessToken!,
          idToken: googleAuth.idToken!,
        ),
      );

      // Handle the result
      await result.fold(
        onSuccess: (user) async {
          print('Step 3 SUCCESS: User logged in: ${user.email} (UID: ${user.uid})');
          
          // Set loading to false after successful sign-in
          print('Step 4: Setting loading to false and notifying listeners...');
          _isLoading = false;
          notifyListeners();
          
          // Navigate to home page after successful sign-in
          print('Step 5: Navigating to HomePage...');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
          print('=== GOOGLE LOGIN COMPLETED SUCCESSFULLY ===');
        },
        onFailure: (error) async {
          print('Step 3 FAILED: ${error.message}');
          _errorMessage = error.message;
          _isLoading = false;
          notifyListeners();
          
          // Handle specific errors
          if (error is NetworkError) {
            // Show network alert dialog with a retry callback
            NetworkAlertPopup.show(context, connectivityController, () {
              // Retry logic for Google login
              googleLogin(context, connectivityController);
            });
          } else if (error is UnauthorizedError) {
            // Show unauthorized domain message
            _showErrorDialog(
              context,
              'Åtkomst nekad',
              'Endast användare med @algebraskolan.se eller @algebrautbildning.se e-postadresser kan logga in.',
            );
          } else {
            // Show general error message
            _showErrorDialog(
              context,
              'Inloggningsfel',
              error.message ?? 'Ett fel uppstod vid inloggning. Försök igen.',
            );
          }
        },
      );
    } catch (e) {
      print('Unexpected error during sign-in: $e');
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

  Future<void> googleLogout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use LogoutUseCase
      final logoutUseCase = InjectionContainer.logoutUseCase;
      final result = await logoutUseCase();
      
      result.fold(
        onSuccess: (_) async {
          // Also disconnect from Google Sign-In
          if (_googleSignIn.currentUser != null) {
            await _googleSignIn.signOut();
            try {
              await _googleSignIn.disconnect();
            } catch (error) {
              debugPrint('Failed to disconnect: $error');
            }
          }
          
          _user = null;
          _isLoading = false;
          notifyListeners();
        },
        onFailure: (error) {
          debugPrint('Logout failed: ${error.message}');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Unexpected error during logout: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> googleDisconnect() async {
    if (_googleSignIn.currentUser != null) {
      await _googleSignIn.disconnect();
    }
  }

  Future<bool> initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      await googleLogout();
      prefs.setBool('isFirstLaunch', false);
      return false;
    }

    final currentUser = InjectionContainer.authRepository.currentUser;
    if (currentUser != null) {
      try {
        // Try silent sign-in with Google (with timeout for simulator compatibility)
        final GoogleSignInAccount? googleUser = await _googleSignIn
            .signInSilently()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('Silent Google Sign-In timed out (likely on simulator)');
                return null;
              },
            );
        if (googleUser != null) {
          _user = googleUser;
          notifyListeners();

          // Validate domain through repository
          final authRepository = InjectionContainer.authRepository;
          final isValidDomain = await authRepository.isEmailDomainAllowed(
            currentUser.email ?? '',
          );

          if (!isValidDomain) {
            await googleLogout();
            return false;
          }

          // Check if user exists in database
          final userRepository = InjectionContainer.userRepository;
          final userData = await userRepository.getUserData(currentUser.uid);
          
          if (userData != null) {
            _user = googleUser;
            return true;
          }
          
          return false;
        } else {
          return false;
        }
      } catch (error) {
        debugPrint("Error in silent sign-in: $error");
        return false;
      }
    } else {
      return false;
    }
  }
  
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}