import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoinWidget extends StatelessWidget {
  final String uid;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CoinWidget({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('users').doc(uid).snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading");
        }

        Map<String, dynamic>? data =
            snapshot.data?.data() as Map<String, dynamic>?;
        return Text('Coins: ${data?['coins'] ?? '0'}');
      },
    );
  }
}
