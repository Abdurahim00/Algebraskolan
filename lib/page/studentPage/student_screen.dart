import 'package:algebra/provider/google_sign_In.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../teacherPage/teacher_screen.dart';

// ignore: must_be_immutable
class StudentScreen extends StatelessWidget {
  StudentScreen({super.key});

  GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();
  GoogleSignInProvider _googleSignInProvider = GoogleSignInProvider();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldkey,
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
                child: (Image.asset("assets/images/Algebraskola1.png"))),
            ListTile(
              onTap: () => _googleSignInProvider.googleLogout(),
              title: Text(
                "Logga ut",
                style: GoogleFonts.montserrat(),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Stack(
          children: [
            Center(
              child: Align(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      child: Image.asset(
                        "assets/images/favicon.png",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10.0,
              left: 10.0,
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.orange),
                // your menu icon here
                onPressed: () {
                  _scaffoldkey.currentState?.openDrawer();
                  // your menu button action here
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
