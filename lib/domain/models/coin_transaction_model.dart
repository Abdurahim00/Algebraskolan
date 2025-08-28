/// Domain model for Coin Transaction
/// Represents a coin transaction in the system
class CoinTransactionModel {
  final String? id;
  final String teacherName;
  final int amount;
  final DateTime timestamp;
  final String? studentId;
  final String? description;
  final TransactionType type;

  CoinTransactionModel({
    this.id,
    required this.teacherName,
    required this.amount,
    required this.timestamp,
    this.studentId,
    this.description,
    TransactionType? type,
  }) : type = type ?? (amount >= 0 ? TransactionType.earn : TransactionType.spend);

  /// Create from map (for database operations)
  factory CoinTransactionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return CoinTransactionModel(
      id: id ?? map['id'],
      teacherName: map['teacherName'] ?? '',
      amount: map['amount'] ?? 0,
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] is DateTime 
              ? map['timestamp'] 
              : DateTime.fromMillisecondsSinceEpoch(map['timestamp']))
          : DateTime.now(),
      studentId: map['studentId'],
      description: map['description'],
      type: map['type'] != null 
          ? TransactionType.values.firstWhere(
              (e) => e.toString().split('.').last == map['type'],
              orElse: () => (map['amount'] ?? 0) >= 0 
                  ? TransactionType.earn 
                  : TransactionType.spend,
            )
          : ((map['amount'] ?? 0) >= 0 ? TransactionType.earn : TransactionType.spend),
    );
  }

  /// Convert to map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'teacherName': teacherName,
      'amount': amount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (studentId != null) 'studentId': studentId,
      if (description != null) 'description': description,
      'type': type.toString().split('.').last,
    };
  }

  /// Create a copy with updated fields
  CoinTransactionModel copyWith({
    String? id,
    String? teacherName,
    int? amount,
    DateTime? timestamp,
    String? studentId,
    String? description,
    TransactionType? type,
  }) {
    return CoinTransactionModel(
      id: id ?? this.id,
      teacherName: teacherName ?? this.teacherName,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      studentId: studentId ?? this.studentId,
      description: description ?? this.description,
      type: type ?? this.type,
    );
  }

  /// Get formatted amount string
  String get formattedAmount {
    final sign = amount >= 0 ? '+' : '';
    return '$sign$amount algebronor';
  }

  /// Get transaction message
  String get message {
    return amount >= 0
        ? "$teacherName +$amount algebronor."
        : "$teacherName -${amount.abs()} algebronor.";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is CoinTransactionModel &&
      other.id == id &&
      other.teacherName == teacherName &&
      other.amount == amount &&
      other.timestamp == timestamp &&
      other.studentId == studentId &&
      other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      teacherName.hashCode ^
      amount.hashCode ^
      timestamp.hashCode ^
      studentId.hashCode ^
      type.hashCode;
  }

  @override
  String toString() {
    return 'CoinTransactionModel(id: $id, teacherName: $teacherName, '
           'amount: $amount, timestamp: $timestamp, type: $type)';
  }
}

/// Enum for transaction types
enum TransactionType {
  earn,
  spend,
  bonus,
  penalty,
  transfer,
  adjustment
}