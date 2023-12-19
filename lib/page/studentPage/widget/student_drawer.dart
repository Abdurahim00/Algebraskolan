import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:algebra/provider/google_sign_In.dart';

import '../../../backend/control_page.dart';
import '../transaction_history.dart';

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  void _handleLogout(BuildContext context) {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);
    provider.googleLogout();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: true);
    final user = provider.user; // This can be null after logout
    final uid = provider.uid;

    return Drawer(
      child: Column(
        children: [
          ListView(
            shrinkWrap: true, // Ensures the ListView only occupies needed space
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
                      classInfo = '$classNumber' + 'an';
                    } else if (snapshot.hasError) {
                      classInfo = 'Error';
                    }
                  }
                  return UserAccountsDrawerHeader(
                    accountName: Text(user?.displayName ?? 'No Name'),
                    accountEmail: Text(user?.email ?? 'No Email'),
                    currentAccountPicture: CircleAvatar(
                      backgroundImage: user?.photoUrl != null
                          ? NetworkImage(user!.photoUrl!)
                          : const AssetImage('assets/default_user.png')
                              as ImageProvider,
                    ),
                    otherAccountsPictures: [
                      CircleAvatar(
                        child: Text(
                          classInfo,
                          style: const TextStyle(fontFamily: 'Pangolin'),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ],
                  );
                },
              ),
              ListTile(
                title: const Text('Historik'),
                trailing: Icon(Icons.history_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => TransactionHistoryScreen()),
                  );
                },
              ),
              Divider(),
              // Other ListTiles if needed
            ],
          ),
          ListTile(
            onTap: () => _showLogoutDialog(context),
            title: const Text("Logga ut"),
            trailing: Icon(Icons.exit_to_app_rounded),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          return CupertinoAlertDialog(
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
          );
        } else {
          return AlertDialog(
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
        }
      },
    );
  }
}
