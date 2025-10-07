/// Enum representing fritids groups
enum FritidsGroup {
  solen,
  havet;

  /// Get display name for the group
  String get displayName {
    switch (this) {
      case FritidsGroup.solen:
        return 'Solen';
      case FritidsGroup.havet:
        return 'Havet';
    }
  }

  /// Get icon asset path for the group
  String get iconAsset {
    switch (this) {
      case FritidsGroup.solen:
        return 'assets/images/solen.png';
      case FritidsGroup.havet:
        return 'assets/images/havet.png';
    }
  }

  /// Convert from string to enum
  static FritidsGroup fromString(String value) {
    switch (value.toLowerCase()) {
      case 'solen':
        return FritidsGroup.solen;
      case 'havet':
        return FritidsGroup.havet;
      default:
        throw ArgumentError('Invalid FritidsGroup: $value');
    }
  }

  /// Convert to string for storage
  String toValue() => name;
}
