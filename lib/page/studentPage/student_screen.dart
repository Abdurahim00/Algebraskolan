import 'package:algebra/page/studentPage/widget/coin_widget.dart';
import 'package:algebra/page/studentPage/widget/student_drawer.dart';
import 'package:algebra/page/studentPage/widget/transactions.dart'; // Make sure to import TransactionWidget if the path is different
import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

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
        drawer: const StudentDrawer(),
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
                        listen: false,
                      ),
                    ),
                    child: Consumer<TransactionProvider>(
                      builder: (context, transactionProvider, child) {
                        // Use transactionProvider to build your UI
                        return TransactionWidget(
                          refreshNotifier: refreshNotifier,
                        );
                      },
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
