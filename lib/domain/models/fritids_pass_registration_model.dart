import 'fritids_group.dart';
import 'pass_type.dart';

/// Model for fritids pass registration
class FritidsPassRegistrationModel {
  final String id;
  final String studentId;
  final String studentName;
  final FritidsGroup group;
  final PassType passType;
  final DateTime date; // Date only (normalized to start of day)
  final DateTime timestamp; // Exact registration time
  final String staffId;
  final String staffName;
  final int algebronaAwarded; // Should always be 1 per pass
  final bool isReverted;
  final String? revertedBy;
  final DateTime? revertedAt;

  FritidsPassRegistrationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.group,
    required this.passType,
    required this.date,
    required this.timestamp,
    required this.staffId,
    required this.staffName,
    this.algebronaAwarded = 1,
    this.isReverted = false,
    this.revertedBy,
    this.revertedAt,
  });

  /// Create from Firestore map
  factory FritidsPassRegistrationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return FritidsPassRegistrationModel(
      id: id ?? map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      group: FritidsGroup.fromString(map['group'] ?? 'solen'),
      passType: PassType.fromString(map['passType'] ?? 'fm'),
      date: map['date'] is DateTime
          ? map['date']
          : DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      timestamp: map['timestamp'] is DateTime
          ? map['timestamp']
          : DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      staffId: map['staffId'] ?? '',
      staffName: map['staffName'] ?? '',
      algebronaAwarded: map['algebronaAwarded'] ?? 1,
      isReverted: map['isReverted'] ?? false,
      revertedBy: map['revertedBy'],
      revertedAt: map['revertedAt'] != null
          ? (map['revertedAt'] is DateTime
              ? map['revertedAt']
              : DateTime.fromMillisecondsSinceEpoch(map['revertedAt']))
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'group': group.toValue(),
      'passType': passType.toValue(),
      'date': _normalizeDate(date).millisecondsSinceEpoch,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'staffId': staffId,
      'staffName': staffName,
      'algebronaAwarded': algebronaAwarded,
      'isReverted': isReverted,
      if (revertedBy != null) 'revertedBy': revertedBy,
      if (revertedAt != null) 'revertedAt': revertedAt!.millisecondsSinceEpoch,
    };
  }

  /// Normalize date to start of day (00:00:00)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get normalized date as DateTime
  DateTime get normalizedDate => _normalizeDate(date);

  /// Check if this registration is for today
  bool get isToday {
    final now = DateTime.now();
    final today = _normalizeDate(now);
    return normalizedDate == today;
  }

  /// Create a copy with updated fields
  FritidsPassRegistrationModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    FritidsGroup? group,
    PassType? passType,
    DateTime? date,
    DateTime? timestamp,
    String? staffId,
    String? staffName,
    int? algebronaAwarded,
    bool? isReverted,
    String? revertedBy,
    DateTime? revertedAt,
  }) {
    return FritidsPassRegistrationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      group: group ?? this.group,
      passType: passType ?? this.passType,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      algebronaAwarded: algebronaAwarded ?? this.algebronaAwarded,
      isReverted: isReverted ?? this.isReverted,
      revertedBy: revertedBy ?? this.revertedBy,
      revertedAt: revertedAt ?? this.revertedAt,
    );
  }

  @override
  String toString() {
    return 'FritidsPassRegistrationModel(id: $id, student: $studentName, '
           'group: ${group.displayName}, pass: ${passType.displayName}, '
           'date: $date, isReverted: $isReverted)';
  }
}
