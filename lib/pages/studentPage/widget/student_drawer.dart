import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/apple_sign_in_provider.dart';

import '../../../backend/control_page.dart';
import '../../../provider/student_provider.dart';
import '../transaction_history.dart';

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  void _handleLogout(BuildContext context) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      final isGoogleUser =
          firebaseUser.providerData.any((p) => p.providerId == 'google.com');
      final isAppleUser =
          firebaseUser.providerData.any((p) => p.providerId == 'apple.com');

      if (isGoogleUser) {
        final googleProvider =
            Provider.of<GoogleSignInProvider>(context, listen: false);
        await googleProvider.googleLogout();
        await googleProvider.googleDisconnect();
      } else if (isAppleUser) {
        final appleProvider =
            Provider.of<AppleSignInProvider>(context, listen: false);
        await appleProvider.appleLogout();
      }

      await FirebaseAuth.instance.signOut();
    }

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
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
                  Fluttertoast.showToast(
                    msg:
                        "Bekräftelsetexten stämmer inte", // Message shown in toast
                    toastLength:
                        Toast.LENGTH_SHORT, // Duration for the toast display
                    gravity: ToastGravity.BOTTOM, // Location of the toast
                  );
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
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final displayName = firebaseUser?.displayName ?? 'Unknown';
    final isAppleUser =
        firebaseUser?.providerData.any((p) => p.providerId == 'apple.com') ??
            false;
    final email = isAppleUser ? '' : (firebaseUser?.email ?? 'No Email');
    final photoURL = firebaseUser?.photoURL ?? 'assets/images/favicon.png';
    final uid = firebaseUser?.uid;

    return Drawer(
      child: Column(
        children: [
          ListView(
            shrinkWrap: true,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get(),
                builder: (context, snapshot) {
                  String classInfo = 'Loading...';
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      final userDoc = snapshot.data;
                      final classNumber =
                          userDoc?['classNumber'].toString() ?? 'No Class';
                      classInfo = '$classNumber' 'an';
                    } else if (snapshot.hasError) {
                      classInfo = 'Error';
                    }
                  }
                  return UserAccountsDrawerHeader(
                    accountName: Text(displayName),
                    accountEmail: isAppleUser ? null : Text(email),
                    currentAccountPicture: CircleAvatar(
                      backgroundImage:
                          photoURL is String && Uri.parse(photoURL).isAbsolute
                              ? NetworkImage(photoURL)
                              : const AssetImage('assets/images/favicon.png')
                                  as ImageProvider,
                    ),
                    otherAccountsPictures: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(
                          classInfo,
                          style: const TextStyle(fontFamily: 'Pangolin'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              ListTile(
                title: const Text('Historik'),
                trailing: const Icon(Icons.history_rounded),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const TransactionHistoryScreen()));
                },
              ),
              const Divider(),
              // Other ListTiles if needed
            ],
          ),
          ListTile(
            onTap: () => _showLogoutDialog(context),
            title: const Text("Logga ut"),
            trailing: const Icon(Icons.exit_to_app_rounded),
          ),
          Spacer(),
          ListTile(
            onTap: () => _handleDeleteRequest(context),
            leading: const Icon(Icons.delete_forever_rounded),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme.of(context).platform == TargetPlatform.iOS
            ? CupertinoAlertDialog(
                title: const Text("Är du säker?"),
                actions: <Widget>[
                  CupertinoDialogAction(
                    onPressed: () => _handleLogout(context),
                    child: const Text("Ja"),
                  ),
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Nej"),
                  ),
                ],
              )
            : AlertDialog(
                title: const Text("Är du säker?"),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => _handleLogout(context),
                    child: const Text("Ja"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Nej"),
                  ),
                ],
              );
      },
    );
  }
}
