import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../provider/google_sign_In.dart';
import '../../../provider/student_provider.dart';
import '../../set_password_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  bool _shouldShowPasswordSetup() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    // Check if user has Google provider but no password provider
    final hasGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    final hasPassword = user.providerData.any((p) => p.providerId == 'password');
    
    return hasGoogle && !hasPassword;
  }

  void _handleDeleteRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kommer du att lämna Algebraskolan?'),
          content: const Text('Denna åtgärd kan inte ångras.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the first dialog
                _showConfirmationDialog(context);
              },
              child: const Text('Ja'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nej'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Är du säker att du vill radera kontot permanent?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the second dialog
                _showFinalConfirmationDialog(context);
              },
              child: const Text('Ja'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nej'),
            ),
          ],
        );
      },
    );
  }

  String _generateRandomString(int length) {
    const characters =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%€#")=!""!€:;#"!';

    Random random = Random();
    return String.fromCharCodes(Iterable.generate(length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length))));
  }

  void _showFinalConfirmationDialog(BuildContext context) {
    final TextEditingController confirmationTextController =
        TextEditingController();
    final String confirmationText =
        _generateRandomString(20); // Generates a random string of length 20

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Är du säker att du vill radera kontot permanent?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vänligen skriv följande text för att bekräfta:'),
              Text(confirmationText,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: confirmationTextController),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (confirmationTextController.text == confirmationText) {
                  Navigator.pop(context); // Close the dialog
                  final provider =
                      Provider.of<StudentProvider>(context, listen: false);
                  provider.deleteUserAccount(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Bekräftelsetexten stämmer inte')));
                }
              },
              child: const Text('Bekräfta'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Avbryt'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: true);
    final user = provider.user; // This can be null after logout

    ImageProvider<Object>? imageProvider;
    if (user != null && user.photoUrl != null) {
      imageProvider = NetworkImage(user.photoUrl!);
    } else {
      imageProvider = const AssetImage('assets/default_user.png');
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'No Name'),
            accountEmail: Text(user?.email ?? 'No Email'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: imageProvider,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero, // Ensures no extra padding is added
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ), // Adjusts the padding to position it correctly
                  trailing: const Icon(Icons.exit_to_app_rounded),
                  onTap: () => showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      // Check the platform
                      if (Theme.of(context).platform == TargetPlatform.iOS) {
                        // Use CupertinoAlertDialog for iOS
                        return CupertinoAlertDialog(
                          title: const Text("Är du säker?"),
                          actions: <Widget>[
                            CupertinoDialogAction(
                              onPressed: () {
                                // Perform logout action
                                provider.googleLogout();
                                Navigator.of(context).pop();
                              },
                              child: const Text("Ja"),
                            ),
                            CupertinoDialogAction(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text("Nej"),
                            ),
                          ],
                        );
                      } else {
                        // Fallback to AlertDialog for Android and other platforms
                        return AlertDialog(
                          title: const Text("Är du säker?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                // Perform logout action
                                provider.googleLogout();
                                Navigator.of(context).pop();
                              },
                              child: const Text("Ja"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text("Nej"),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  title: const Text("Logga ut"),
                ),
                // Show password setup option if user is logged in with Google only
                if (_shouldShowPasswordSetup()) ...[
                  ListTile(
                    title: const Text('Lägg till lösenord'),
                    subtitle: const Text('Aktivera inloggning med e-post', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.lock_outline),
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SetPasswordPage()),
                      );
                      if (result == true) {
                        Fluttertoast.showToast(
                          msg: "Lösenord tillagt! Du kan nu logga in med e-post också.",
                          toastLength: Toast.LENGTH_LONG,
                        );
                      }
                    },
                  ),
                ],
                // Add other ListTiles if needed
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded),
            onTap: () => _handleDeleteRequest(context),
          ),
        ],
      ),
    );
  }
}
