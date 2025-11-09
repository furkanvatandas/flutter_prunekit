/// Represents a field declared in a class, mixin, enum, or extension type.
///
/// This model tracks field declarations for unused field detection (spec 006).
class FieldDeclaration {
  /// Field name as declared in source code
  final String name;

  /// Absolute path to file containing the declaration
  final String filePath;

  /// Line number where field is declared (1-indexed)
  final int lineNumber;

  /// Column number where field is declared (1-indexed)
  final int columnNumber;

  /// Name of the class/mixin/enum/extension type containing the field
  final String declaringType;

  /// Type of declaring context (class, mixin, enum, extensionType)
  final FieldDeclaringTypeKind declaringTypeKind;

  /// Instance or static field
  final FieldType fieldType;

  /// Mutability: const, final, var, late
  final FieldMutability mutability;

  /// Public or private visibility (determined by leading underscore)
  final Visibility visibility;

  /// Annotations applied to the field (for @keepUnused detection)
  final List<String> annotations;

  /// True if field is instance field in enhanced enum (Dart 2.17+)
  final bool isEnumInstanceField;

  /// True if field is representation field in extension type (Dart 3.3+)
  final bool isExtensionTypeRepresentation;

  FieldDeclaration({
    required this.name,
    required this.filePath,
    required this.lineNumber,
    required this.columnNumber,
    required this.declaringType,
    required this.declaringTypeKind,
    required this.fieldType,
    required this.mutability,
    required this.visibility,
    this.annotations = const [],
    this.isEnumInstanceField = false,
    this.isExtensionTypeRepresentation = false,
  }) {
    // Validation
    if (name.isEmpty) {
      throw ArgumentError('name must be non-empty');
    }
    if (lineNumber <= 0 || columnNumber <= 0) {
      throw ArgumentError('lineNumber and columnNumber must be positive');
    }
    if (isExtensionTypeRepresentation && declaringTypeKind != FieldDeclaringTypeKind.extensionType) {
      throw ArgumentError(
        'isExtensionTypeRepresentation can only be true if declaringTypeKind is extensionType',
      );
    }
  }

  /// Unique identifier format: {declaringType}.{name}
  ///
  /// Example: `User.email`
  /// Note: Does not include filePath because fields are uniquely identified by their class and name
  String get uniqueId => '$declaringType.$name';

  /// Check if field has @keepUnused annotation
  bool get hasKeepUnusedAnnotation => annotations.any((a) => a == 'keepUnused' || a == 'KeepUnused');

  /// Convert to JSON representation
  Map<String, dynamic> toJson() => {
        'name': name,
        'filePath': filePath,
        'lineNumber': lineNumber,
        'columnNumber': columnNumber,
        'declaringType': declaringType,
        'declaringTypeKind': declaringTypeKind.name,
        'fieldType': fieldType.name,
        'mutability': mutability.name,
        'visibility': visibility.name,
        'annotations': annotations,
        'isEnumInstanceField': isEnumInstanceField,
        'isExtensionTypeRepresentation': isExtensionTypeRepresentation,
      };

  @override
  String toString() => '$declaringType.$name';
}

/// Type of context declaring the field
enum FieldDeclaringTypeKind {
  /// Regular class
  classType,

  /// Mixin declaration
  mixin,

  /// Enum declaration (including enhanced enums)
  enum_,

  /// Extension type (Dart 3.3+)
  extensionType,
}

/// Instance-level or static field
enum FieldType {
  /// Instance-level field
  instance,

  /// Static/class-level field
  static,
}

/// Field mutability characteristics
enum FieldMutability {
  /// const field (compile-time constant)
  const_,

  /// final field (runtime constant, set once)
  final_,

  /// Mutable var field
  var_,

  /// Late field (lazy initialization)
  late,
}

/// Field visibility based on naming convention
enum Visibility {
  /// Field name doesn't start with underscore
  public,

  /// Field name starts with underscore
  private,
}
