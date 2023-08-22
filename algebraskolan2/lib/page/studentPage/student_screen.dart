import 'package:algebra/page/studentPage/widget/coin_Widget.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../backend/control_page.dart';

class StudentScreen extends StatelessWidget {
  StudentScreen({Key? key}) : super(key: key);

  final GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);
    String? uid = provider.uid;

    return Scaffold(
      key: _scaffoldkey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.orange),
          onPressed: () {
            _scaffoldkey.currentState?.openDrawer();
          },
        ),
        title: null, // Set title to null
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Center(
          child: Image.asset(
            "assets/images/favicon.png",
            width: 50, // You can adjust the size as needed
            height: 50,
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Image.asset("assets/images/Algebraskola1.png")),
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
                        ),
                      ],
                    );
                  },
                );
              },
              title: Text("Logga ut", style: GoogleFonts.montserrat()),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: 70, // Adjust this if necessary
              ),
              CoinWidget(uid: uid ?? ""),
            ],
          ),
        ),
      ),
    );
  }
}
