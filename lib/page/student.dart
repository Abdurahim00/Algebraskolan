import 'package:algebra/backend/coin_transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class Student {
  final String uid;
  final String displayName;
  final String role;
  final int classNumber;
  late final int coins;
  final Timestamp? questionAnsweredAt; // added field
  final bool hasAnsweredQuestionCorrectly; // added field
  ValueNotifier<int> localCoins;
  List<CoinTransaction> transactions = [];

  Student({
    required this.uid,
    required this.displayName,
    required this.role,
    required this.classNumber,
    required this.coins,
    required this.transactions,
    this.questionAnsweredAt, // it can be null
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
      questionAnsweredAt: data.containsKey('questionAnsweredAt')
          ? data['questionAnsweredAt']
          : null,
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
    // added field
    bool? hasAnsweredQuestionCorrectly, // added field
    ValueNotifier<int>? localCoins, // It should be ValueNotifier<int>
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
      transactions: [],
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
      localCoins.value.hashCode; // Calculate hash for the value of localCoins
}
