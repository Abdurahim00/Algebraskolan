import 'package:cloud_firestore/cloud_firestore.dart';

class CoinService {
  final FirebaseFirestore firestore;

  CoinService(this.firestore);

  Future<void> incrementCoins(String userId, int amount) async {
    final userDoc = firestore.collection('users').doc(userId);
    await userDoc.update({'coins': FieldValue.increment(amount)});
  }

  Future<void> decrementCoins(String userId, int amount) async {
    final userDoc = firestore.collection('users').doc(userId);
    await userDoc.update({'coins': FieldValue.increment(-amount)});
  }
}
