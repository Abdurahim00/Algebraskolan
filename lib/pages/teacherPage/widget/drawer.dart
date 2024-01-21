import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/google_sign_In.dart';
import '../../../provider/student_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
              children: [
                ListTile(
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
