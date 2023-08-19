import 'package:algebra/provider/google_sign_In.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../backend/control_page.dart';

// ignore: must_be_immutable
class StudentScreen extends StatelessWidget {
  StudentScreen({super.key});

  GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);

    return Scaffold(
      key: _scaffoldkey,
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
                child: (Image.asset("assets/images/Algebraskola1.png"))),
            ListTile(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return CupertinoAlertDialog(
                        title: Text("Är du säker?"),
                        actions: [
                          MaterialButton(
                            onPressed: () {
                              provider.googleLogout();

                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (context) => HomePage()));
                            },
                            child: Text("Ja"),
                          ),
                          MaterialButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("Nej"),
                          )
                        ],
                      );
                    });
              },
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
