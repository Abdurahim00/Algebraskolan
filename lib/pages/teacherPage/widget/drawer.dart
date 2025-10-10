import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../provider/google_sign_In.dart';
import '../../../provider/student_provider.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onRevertTransaction;

  const AppDrawer({
    super.key,
    this.onRevertTransaction,
  });


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
          _buildHeader(user, imageProvider),
          const SizedBox(height: 8),
          _buildSection(
            title: 'ALGEBRONOR',
            children: [
              _DrawerItem(
                icon: Icons.school,
                title: 'Huvudsida',
                iconColor: Colors.green,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Close drawer first, then navigate
                  Navigator.of(context).pop();
                  // Pop all routes back to home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
          const Divider(height: 32, thickness: 1),
          _buildSection(
            title: 'FRITIDS',
            children: [
              _DrawerItem(
                icon: Icons.child_care,
                title: 'Fritids',
                iconColor: Colors.purple,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Close drawer
                  Navigator.of(context).pop();
                  // Navigate to Fritids
                  Navigator.of(context).pushNamed('/fritids');
                },
              ),
              _DrawerItem(
                icon: Icons.history,
                title: 'Fritids Historik',
                iconColor: Colors.blue,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Close drawer
                  Navigator.of(context).pop();
                  // Navigate to Fritids History
                  Navigator.of(context).pushNamed('/fritids-history');
                },
              ),
            ],
          ),
          const Spacer(),
          const Divider(thickness: 1, height: 1),
          const SizedBox(height: 8),
          _DrawerItem(
            icon: Icons.undo,
            title: 'Återställ felaktiga algebrona-utdelningar',
            iconColor: Colors.orange,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
              onRevertTransaction?.call();
            },
          ),
          const Divider(thickness: 1, height: 1),
          _DrawerItem(
            icon: Icons.exit_to_app_rounded,
            title: 'Logga ut',
            iconColor: Colors.grey,
            onTap: () {
              HapticFeedback.lightImpact();
              showDialog(
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
              );
            },
          ),
          const Divider(thickness: 1, height: 1),
          InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              _handleDeleteRequest(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Radera konto',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHeader(GoogleSignInAccount? user, ImageProvider imageProvider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(245, 142, 11, 1),
            Color.fromRGBO(255, 170, 60, 1),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: imageProvider,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'No Name',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'No Email',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _DrawerItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.iconColor,
    this.textColor,
    required this.onTap,
  });

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _isPressed ? Colors.grey[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              AnimatedScale(
                scale: _isPressed ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: widget.textColor ?? Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
