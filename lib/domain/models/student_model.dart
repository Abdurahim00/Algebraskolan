import 'package:flutter/foundation.dart';
import 'fritids_group.dart';

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
  final FritidsGroup? fritidsGroup;

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
    this.fritidsGroup,
  }) : localCoins = localCoins ?? ValueNotifier<int>(0);

  /// Create from map (for database operations)
  factory StudentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    // Handle Timestamp conversion
    DateTime? parseTimestamp(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      // Handle Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return null;
    }

    // Parse fritidsGroup if present
    FritidsGroup? fritidsGroup;
    if (map['fritidsGroup'] != null) {
      try {
        fritidsGroup = FritidsGroup.fromString(map['fritidsGroup']);
      } catch (e) {
        // Invalid group, leave as null
      }
    }

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
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
      fritidsGroup: fritidsGroup,
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
      if (fritidsGroup != null) 'fritidsGroup': fritidsGroup!.toValue(),
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
    FritidsGroup? fritidsGroup,
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
      fritidsGroup: fritidsGroup ?? this.fritidsGroup,
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