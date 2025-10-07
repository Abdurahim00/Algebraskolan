import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebra/provider/connectivity_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:algebra/pages/admin_menu.dart';

import '../provider/google_sign_In.dart';
import '../provider/custom_auth_provider.dart';
import '../other/network_alert.dart';
import '../widgets/skeleton_loading.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoginMode = true;
  bool _showCustomLogin = false;
  String _selectedRole = 'elev';
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    _fadeController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _toggleLoginMethod() {
    setState(() {
      _showCustomLogin = !_showCustomLogin;
      _isLoginMode = true;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }


  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ange e-postadress';
    }
    if (!value.contains('@')) {
      return 'Ogiltig e-postadress';
    }
    if (!value.endsWith('@algebraskolan.se') && 
        !value.endsWith('@algebrautbildning.se')) {
      return 'Endast @algebraskolan.se eller @algebrautbildning.se är tillåtet';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ange lösenord';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bekräfta lösenord';
    }
    if (value != _passwordController.text) {
      return 'Lösenorden matchar inte';
    }
    return null;
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final connectivityController =
          Provider.of<ConnectivityController>(context, listen: false);
      final customAuthProvider = CustomAuthProvider.instance;

      if (!connectivityController.isConnected.value) {
        NetworkAlertPopup.show(context, connectivityController, () async {
          if (await connectivityController.checkConnectivity()) {
            _handleSubmit();
          }
        });
        return;
      }

      if (_isLoginMode) {
        await customAuthProvider.loginWithEmail(
          context: context,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          connectivityController: connectivityController,
        );
      } else {
        await customAuthProvider.registerWithEmail(
          context: context,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
          connectivityController: connectivityController,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivityController =
        Provider.of<ConnectivityController>(context, listen: false);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Lottie.asset(
              'assets/images/Gradient Circles Warm.json',
              controller: _animationController,
              onLoaded: (composition) {
                _animationController
                  ..duration = composition.duration
                  ..repeat();
              },
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: GestureDetector(
                onLongPress: () {
                  // Hidden admin access
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminMenu(),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/images/Algebraskolan4.png',
                  height: 80,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 100),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            _showCustomLogin 
                                ? (_isLoginMode ? 'Logga in' : 'Registrera dig')
                                : 'Välkommen',
                            style: const TextStyle(
                              fontFamily: 'LilitaOne',
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showCustomLogin
                                ? (_isLoginMode 
                                    ? 'Logga in med din Algebraskolan e-post'
                                    : 'Registrera dig med Algebraskolans mail')
                                : 'Registrera dig med Algebraskolans mail',
                            style: const TextStyle(
                              fontFamily: 'LilitaOne',
                              fontSize: 20,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    if (!_showCustomLogin) ...[
                      Consumer<GoogleSignInProvider>(
                        builder: (context, provider, child) {
                          return provider.isLoading
                              ? Center(
                                  child: Container(
                                    width: 300,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const SkeletonLoader(
                                      width: 300,
                                      height: 50,
                                      borderRadius: BorderRadius.all(Radius.circular(30)),
                                    ),
                                  ),
                                )
                              : ScaleTransition(
                                  scale: Tween(begin: 0.95, end: 1.05).animate(
                                    CurvedAnimation(
                                        parent: _animationController,
                                        curve: Curves.easeInOut),
                                  ),
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      if (connectivityController
                                          .isConnected.value) {
                                        provider.googleLogin(
                                            context, connectivityController);
                                      } else {
                                        NetworkAlertPopup.show(
                                            context, connectivityController,
                                            () async {
                                          if (await connectivityController
                                              .checkConnectivity()) {
                                            provider.googleLogin(
                                                context, connectivityController);
                                          }
                                        });
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/images/google-logo.png',
                                          height: 40.0,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Anslut med Google',
                                          style: TextStyle(
                                            fontFamily: 'LilitaOne',
                                            fontSize: 18,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                        },
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _toggleLoginMethod,
                        child: const Text(
                          'Logga in med e-post istället',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'E-postadress',
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Lösenord',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                obscureText: _obscurePassword,
                                validator: _validatePassword,
                              ),
                              if (!_isLoginMode) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Bekräfta lösenord',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    border: const OutlineInputBorder(),
                                  ),
                                  obscureText: _obscureConfirmPassword,
                                  validator: _validateConfirmPassword,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedRole,
                                  decoration: const InputDecoration(
                                    labelText: 'Välj roll',
                                    prefixIcon: Icon(Icons.person),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'elev',
                                      child: Text('Elev'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'lärare',
                                      child: Text('Lärare'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                ),
                              ],
                              const SizedBox(height: 20),
                              ChangeNotifierProvider.value(
                                value: CustomAuthProvider.instance,
                                child: Consumer<CustomAuthProvider>(
                                  builder: (context, provider, child) {
                                    return provider.isLoading
                                        ? Center(
                                            child: Container(
                                              width: 200,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const SkeletonLoader(
                                                width: 200,
                                                height: 50,
                                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                              ),
                                            ),
                                          )
                                        : ElevatedButton(
                                            onPressed: _handleSubmit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              _isLoginMode
                                                  ? 'Logga in'
                                                  : 'Registrera dig',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _toggleMode,
                                child: Text(
                                  _isLoginMode
                                      ? 'Har du inget konto? Registrera dig'
                                      : 'Har du redan ett konto? Logga in',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _toggleLoginMethod,
                        child: const Text(
                          'Använd Google istället',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}