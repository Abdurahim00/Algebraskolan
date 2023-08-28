import 'package:algebra/page/studentPage/widget/coin_widget.dart';
import 'package:algebra/page/studentPage/widget/transactions.dart'; // Make sure to import TransactionWidget if the path is different
import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/transaction_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../backend/control_page.dart';

class StudentScreen extends StatefulWidget {
  StudentScreen({Key? key}) : super(key: key);

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();
  final ValueNotifier<bool> refreshNotifier = ValueNotifier<bool>(false);
  bool shouldShowDonation = true;
  String? uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<GoogleSignInProvider>(context, listen: false);
      setState(() {
        uid = provider.uid;
      });
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID is null. Unable to proceed.')),
        );
      }
    });
  }

  @override
  void dispose() {
    // Clean up
    shouldShowDonation = false;
    super.dispose();
  }

  _handleLogout() {
    final provider = Provider.of<GoogleSignInProvider>(context, listen: false);
    provider.googleLogout();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (context) => HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        key: _scaffoldkey,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.orange),
            onPressed: () {
              _scaffoldkey.currentState?.openDrawer();
            },
          ),
          title: null,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Center(
            child: Image.asset(
              "assets/images/favicon.png",
              width: screenWidth * 0.7,
              height: screenHeight * 0.7,
            ),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                  child: Image.asset("assets/images/Algebraskola1.png")),
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
                              _handleLogout();
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (uid != null && uid!.isNotEmpty) // <-- Check uid here
                  ChangeNotifierProvider<TransactionProvider>(
                    create: (_) => TransactionProvider(
                      uid: uid!,
                      googleSignInProvider: Provider.of<GoogleSignInProvider>(
                          context,
                          listen: false),
                    ),
                    child: TransactionWidget(
                      shouldShowDonation: shouldShowDonation,
                      refreshNotifier: refreshNotifier,
                    ),
                  ),
                SizedBox(
                  height: screenHeight * 0.12,
                ),
                CoinWidget(uid: uid ?? ""),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
