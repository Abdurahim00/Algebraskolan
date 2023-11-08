class CoinTransaction {
  String teacherName;
  int amount;
  dynamic
      timestamp; // Changed from DateTime to dynamic to accept FieldValue.serverTimestamp()

  CoinTransaction({
    required this.teacherName,
    required this.amount,
    required this.timestamp, // Accept dynamic type
  });

  Map<String, dynamic> toMap() {
    return {
      'teacherName': teacherName,
      'amount': amount,
      'timestamp': timestamp, // No change needed here
      'isNew': true, // Ensure isNew is always true for new transactions
    };
  }
}
