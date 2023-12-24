import 'package:algebra/backend/coin_transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class Student {
  final String uid;
  final String displayName;
  final String role;
  final int classNumber;
  final int coins;
  final bool hasAnsweredQuestionCorrectly;
  ValueNotifier<int> localCoins;
  List<CoinTransaction> transactions = [];

  Student({
    required this.uid,
    required this.displayName,
    required this.role,
    required this.classNumber,
    required this.coins,
    required this.transactions,
    required this.hasAnsweredQuestionCorrectly,
    ValueNotifier<int>? localCoins, // It is nullable
  }) : localCoins = localCoins ??
            ValueNotifier<int>(0); // If not passed, it is initialized to 0

  factory Student.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      uid: doc.id,
      displayName: data.containsKey('displayName') ? data['displayName'] : '',
      role: data.containsKey('role') ? data['role'] : 'student',
      classNumber: data.containsKey('classNumber') ? data['classNumber'] : 0,
      coins: data.containsKey('coins') ? data['coins'] : 0,
      hasAnsweredQuestionCorrectly:
          data.containsKey('hasAnsweredQuestionCorrectly')
              ? data['hasAnsweredQuestionCorrectly']
              : false,
      transactions: [],
    );
  }

  Student copyWith({
    String? uid,
    String? displayName,
    String? role,
    int? classNumber,
    int? coins,
    bool? hasAnsweredQuestionCorrectly,
    ValueNotifier<int>? localCoins,
  }) {
    return Student(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      classNumber: classNumber ?? this.classNumber,
      coins: coins ?? this.coins,
      hasAnsweredQuestionCorrectly:
          hasAnsweredQuestionCorrectly ?? this.hasAnsweredQuestionCorrectly,
      localCoins: localCoins ?? this.localCoins,
      transactions: this.transactions, // Keep the existing transactions
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Student &&
        other.uid == uid &&
        other.displayName == displayName &&
        other.role == role &&
        other.classNumber == classNumber &&
        other.coins == coins &&
        other.hasAnsweredQuestionCorrectly == hasAnsweredQuestionCorrectly &&
        other.localCoins.value ==
            localCoins.value; // Compare the value of localCoins
  }

  @override
  int get hashCode =>
      uid.hashCode ^
      displayName.hashCode ^
      role.hashCode ^
      classNumber.hashCode ^
      coins.hashCode ^
      hasAnsweredQuestionCorrectly.hashCode ^
      localCoins.value.hashCode; // Calculate hash for the value of localCoins
}
