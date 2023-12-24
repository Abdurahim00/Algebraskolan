import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../provider/google_sign_In.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'No Name'),
            accountEmail: Text(user?.email ?? 'No Email'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: imageProvider,
            ),
          ),
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
            title: const Text(
              "Logga ut",
            ),
          ),
          // Add other ListTiles if needed
        ],
      ),
    );
  }
}
