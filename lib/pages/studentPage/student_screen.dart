import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebra/provider/google_sign_In.dart';
import 'package:algebra/provider/transaction_provider.dart';
import 'package:algebra/pages/studentPage/widget/coin_widget.dart';
import 'package:algebra/pages/studentPage/widget/student_drawer.dart';
import 'package:algebra/pages/studentPage/widget/transactions.dart'; // Import TransactionWidget if the path is different

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

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: const Size(430, 932), // Consistent size across the app
        devicePixelRatio: 3.0, // Ensure it matches your design
      ),
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/favicon.png",
                width: screenWidth * 0.15,
                height: screenHeight * 0.05, // Adjust height as needed
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            // Add an empty container to balance the Row
            Container(width: 48), // Same width as the drawer icon
          ],
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
