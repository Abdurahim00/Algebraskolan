/// Enum representing pass types (morning/afternoon sessions)
enum PassType {
  fm,  // Förmiddag (Morning)
  em;  // Eftermiddag (Afternoon)

  /// Get display name for the pass type
  String get displayName {
    switch (this) {
      case PassType.fm:
        return 'FM';
      case PassType.em:
        return 'EM';
    }
  }

  /// Get full display name
  String get fullDisplayName {
    switch (this) {
      case PassType.fm:
        return 'Förmiddag';
      case PassType.em:
        return 'Eftermiddag';
    }
  }

  /// Convert from string to enum
  static PassType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'fm':
      case 'förmiddag':
        return PassType.fm;
      case 'em':
      case 'eftermiddag':
        return PassType.em;
      default:
        throw ArgumentError('Invalid PassType: $value');
    }
  }

  /// Convert to string for storage
  String toValue() => name;
}
