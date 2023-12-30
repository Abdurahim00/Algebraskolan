import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/apple_sign_in_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../backend/control_page.dart';
import '../transaction_history.dart';

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  void _handleLogout(BuildContext context) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      // Check the provider used for sign-in
      final isGoogleUser =
          firebaseUser.providerData.any((p) => p.providerId == 'google.com');
      final isAppleUser =
          firebaseUser.providerData.any((p) => p.providerId == 'apple.com');

      if (isGoogleUser) {
        // Perform Google Sign-Out
        final googleProvider =
            Provider.of<GoogleSignInProvider>(context, listen: false);
        await googleProvider.googleLogout();
      } else if (isAppleUser) {
        // Perform Apple Sign-Out
        final appleProvider =
            Provider.of<AppleSignInProvider>(context, listen: false);
        await appleProvider.appleLogout();
      }

      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();
    }

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final displayName = firebaseUser?.displayName ?? 'Unknown';
    final email = firebaseUser?.email ?? 'No Email';
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
                    accountEmail: Text(email),
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
