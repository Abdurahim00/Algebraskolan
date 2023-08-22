import 'package:cloud_firestore/cloud_firestore.dart';

class CoinService {
  final FirebaseFirestore firestore;

  CoinService(this.firestore);

  Future<void> incrementCoins(String userId, int amount) async {
    final userDoc = firestore.collection('users').doc(userId);
    await userDoc.update({'coins': FieldValue.increment(amount)});
  }

  Future<bool> decrementCoins(String userId, int amount) async {
    final userDoc = firestore.collection('users').doc(userId);

    // Fetch the current coin count
    final doc = await userDoc.get();
    if (!doc.exists) {
      // Handle the case where the user doesn't exist
      return false;
    }

    final currentCoins =
        doc.data()?['coins'] ?? 0; // Ensure there's a default value

    // Check if there's enough coins to decrement
    if (currentCoins >= amount) {
      await userDoc.update({'coins': FieldValue.increment(-amount)});

      return true;
      // Successful decrement
    } else {
      // Not enough coins
      return false; // Unsuccessful decrement
    }
  }
}
