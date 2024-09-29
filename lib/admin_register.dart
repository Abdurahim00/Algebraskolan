import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSignupPage extends StatefulWidget {
  @override
  _AdminSignupPageState createState() => _AdminSignupPageState();
}

class _AdminSignupPageState extends State<AdminSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _classNumberController = TextEditingController();
  String? _role;
  bool _isLoading = false;

  final List<String> _roles = ['student', 'teacher'];
  final List<String> _allowedDomains = [
    '@algebraskolan.se',
    '@algebrautbildning.se'
  ];

  Future<void> _signupUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final displayName = _displayNameController.text.trim();
        final classNumber = int.parse(_classNumberController.text.trim());
        final role = _role ?? 'student'; // Default role if not selected
        const defaultPassword = 'Algebraskolan1';

        // Check if email domain is allowed
        if (!_allowedDomains.any((domain) => email.endsWith(domain))) {
          throw Exception('Access denied for unauthorized domain.');
        }

        // Create user with email and default password
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: email, password: defaultPassword);

        User? newUser = userCredential.user;

        if (newUser != null) {
          // Store user data in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(newUser.uid)
              .set({
            'email': email,
            'displayName': displayName,
            'displayNameLower': displayName.toLowerCase(),
            'role': role,
            'classNumber': classNumber,
            'coins': 0,
            'hasAnsweredQuestionCorrectly': false,
            'created_at': Timestamp.now(),
            'created_by': 'admin'
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User created successfully!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create user: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Signup Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  // Check if the email domain is allowed
                  if (!_allowedDomains
                      .any((domain) => value.endsWith(domain))) {
                    return 'Please use a valid email (e.g, @algebraskolan.se)';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: 'Display Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a display name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _classNumberController,
                decoration: InputDecoration(labelText: 'Class Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a class number';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(labelText: 'Role'),
                items: _roles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _role = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signupUser,
                      child: Text('Create User'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
