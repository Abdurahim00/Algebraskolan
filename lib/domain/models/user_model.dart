/// Domain model for User
/// Represents a generic user in the system
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final List<String> providers;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.providers = const [],
    this.createdAt,
    this.lastLoginAt,
    this.metadata,
  });

  /// Create from map (for database operations)
  factory UserModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return UserModel(
      uid: id ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'student',
      providers: map['providers'] != null 
          ? List<String>.from(map['providers'])
          : [],
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      lastLoginAt: map['lastLoginAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'])
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'providers': providers,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Check if user is a teacher
  bool get isTeacher => role == 'teacher';

  /// Check if user is a student
  bool get isStudent => role == 'student';

  /// Check if user has Google provider
  bool get hasGoogleProvider => providers.contains('google.com');

  /// Check if user has password provider
  bool get hasPasswordProvider => providers.contains('password');

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    List<String>? providers,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      providers: providers ?? this.providers,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is UserModel &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.role == role;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      role.hashCode;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, '
           'role: $role, providers: $providers)';
  }
}