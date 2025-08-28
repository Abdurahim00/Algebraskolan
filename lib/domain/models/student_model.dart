import 'package:flutter/foundation.dart';

/// Domain model for Student
/// This is a clean model without Firebase dependencies
class StudentModel {
  final String uid;
  final String email;
  final String displayName;
  final String displayNameLower;
  final String role;
  final int classNumber;
  final int coins;
  final bool hasAnsweredQuestionCorrectly;
  final ValueNotifier<int> localCoins;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.displayNameLower,
    required this.role,
    required this.classNumber,
    required this.coins,
    this.hasAnsweredQuestionCorrectly = false,
    ValueNotifier<int>? localCoins,
    this.createdAt,
    this.updatedAt,
  }) : localCoins = localCoins ?? ValueNotifier<int>(0);

  /// Create from map (for database operations)
  factory StudentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return StudentModel(
      uid: id ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      displayNameLower: map['displayNameLower'] ?? 
                        (map['displayName'] ?? '').toLowerCase(),
      role: map['role'] ?? 'student',
      classNumber: map['classNumber'] ?? 0,
      coins: map['coins'] ?? 0,
      hasAnsweredQuestionCorrectly: map['hasAnsweredQuestionCorrectly'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  /// Convert to map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'displayNameLower': displayNameLower,
      'role': role,
      'classNumber': classNumber,
      'coins': coins,
      'hasAnsweredQuestionCorrectly': hasAnsweredQuestionCorrectly,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Create a copy with updated fields
  StudentModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? displayNameLower,
    String? role,
    int? classNumber,
    int? coins,
    bool? hasAnsweredQuestionCorrectly,
    ValueNotifier<int>? localCoins,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      displayNameLower: displayNameLower ?? this.displayNameLower,
      role: role ?? this.role,
      classNumber: classNumber ?? this.classNumber,
      coins: coins ?? this.coins,
      hasAnsweredQuestionCorrectly: 
          hasAnsweredQuestionCorrectly ?? this.hasAnsweredQuestionCorrectly,
      localCoins: localCoins ?? this.localCoins,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is StudentModel &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.role == role &&
      other.classNumber == classNumber &&
      other.coins == coins;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      role.hashCode ^
      classNumber.hashCode ^
      coins.hashCode;
  }

  @override
  String toString() {
    return 'StudentModel(uid: $uid, displayName: $displayName, role: $role, '
           'classNumber: $classNumber, coins: $coins)';
  }

  // Convenience getters for compatibility
  String get name => displayName;
  String get nameLowercase => displayNameLower;
  bool get hasAnsweredQuestion => hasAnsweredQuestionCorrectly;
}