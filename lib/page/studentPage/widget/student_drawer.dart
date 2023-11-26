import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:algebra/provider/google_sign_In.dart';

import '../../../backend/control_page.dart';

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({Key? key}) : super(key: key);

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

    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'No Name'),
            accountEmail: Text(user?.email ?? 'No Email'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.photoUrl != null
                  ? NetworkImage(user!.photoUrl!) as ImageProvider<Object>?
                  : const AssetImage('assets/default_user.png'),
            ),
          ),
          ListTile(
            onTap: () => _showLogoutDialog(context),
            title: const Text("Logga ut"),
          ),
          // Add other ListTiles if needed
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
