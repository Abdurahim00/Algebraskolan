class CoinTransaction {
  final String teacherName;
  final int amount;
  final DateTime timestamp;

  CoinTransaction({
    required this.teacherName,
    required this.amount,
    required this.timestamp,
  });

  factory CoinTransaction.fromMap(Map<String, dynamic> map) {
    return CoinTransaction(
      teacherName: map['teacherName'] ?? '',
      amount: map['amount'] ?? 0,
      timestamp: map['timestamp'].toDate(),
    );
  }
}
