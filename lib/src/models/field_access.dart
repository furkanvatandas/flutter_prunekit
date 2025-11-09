/// Represents a location where a field is read or written.
///
/// This model tracks field accesses for unused field detection (spec 006).
class FieldAccess {
  /// Name of the field being accessed
  final String fieldName;

  /// Name of the class/mixin/enum containing the field
  final String declaringType;

  /// Absolute path to file containing the access
  final String filePath;

  /// Line number where access occurs (1-indexed)
  final int lineNumber;

  /// Column number where access occurs (1-indexed)
  final int columnNumber;

  /// Read, write, or readWrite (for compound assignment)
  final FieldAccessType accessType;

  /// How the field is accessed (direct, static, implicit this, etc.)
  final FieldAccessPattern accessPattern;

  /// True if field accessed without explicit target in same class
  /// (e.g., `field` instead of `this.field`)
  final bool isImplicitThis;

  /// True if access occurs in constructor (body or initializer list)
  final bool inConstructor;

  /// True if access occurs in `operator ==` or `hashCode`
  final bool inEqualityOperator;

  /// True if access occurs in string interpolation (`$field` or `${field}`)
  final bool inStringInterpolation;

  /// True if access occurs within cascade expression
  final bool inCascade;

  FieldAccess({
    required this.fieldName,
    required this.declaringType,
    required this.filePath,
    required this.lineNumber,
    required this.columnNumber,
    required this.accessType,
    required this.accessPattern,
    this.isImplicitThis = false,
    this.inConstructor = false,
    this.inEqualityOperator = false,
    this.inStringInterpolation = false,
    this.inCascade = false,
  }) {
    // Validation
    if (fieldName.isEmpty) {
      throw ArgumentError('fieldName must be non-empty');
    }
    if (lineNumber <= 0 || columnNumber <= 0) {
      throw ArgumentError('lineNumber and columnNumber must be positive');
    }
    if (isImplicitThis && accessPattern != FieldAccessPattern.thisImplicit) {
      throw ArgumentError(
        'isImplicitThis requires accessPattern to be thisImplicit',
      );
    }
  }

  /// Unique identifier for the field being accessed
  /// Format: DeclaringType.fieldName
  /// Note: Does not include filePath because a field can be accessed from any file
  String get fieldUniqueId => '$declaringType.$fieldName';

  /// Check if this access is a read operation
  bool get isRead => accessType == FieldAccessType.read || accessType == FieldAccessType.readWrite;

  /// Check if this access is a write operation
  bool get isWrite => accessType == FieldAccessType.write || accessType == FieldAccessType.readWrite;

  /// Convert to JSON representation
  Map<String, dynamic> toJson() => {
        'fieldName': fieldName,
        'declaringType': declaringType,
        'filePath': filePath,
        'lineNumber': lineNumber,
        'columnNumber': columnNumber,
        'accessType': accessType.name,
        'accessPattern': accessPattern.name,
        'isImplicitThis': isImplicitThis,
        'inConstructor': inConstructor,
        'inEqualityOperator': inEqualityOperator,
        'inStringInterpolation': inStringInterpolation,
        'inCascade': inCascade,
      };

  @override
  String toString() => '$declaringType.$fieldName at $filePath:$lineNumber ($accessType)';
}

/// Type of field access operation
enum FieldAccessType {
  /// Field is read (e.g., `x = obj.field`)
  read,

  /// Field is written (e.g., `obj.field = x`)
  write,

  /// Field is both read and written (e.g., `obj.field += 1`)
  readWrite,
}

/// Pattern of how the field is accessed
enum FieldAccessPattern {
  /// obj.field (read)
  directRead,

  /// obj.field = value (write)
  directWrite,

  /// this.field within same class
  thisExplicit,

  /// field within same class (no qualifier)
  thisImplicit,

  /// ClassName.field
  staticAccess,

  /// Field initialized in constructor initializer list
  constructorInit,

  /// this.field parameter in constructor
  constructorParam,

  /// $field or ${field.property}
  stringInterpolation,

  /// obj..field within cascade
  cascadeRead,

  /// obj..field = value within cascade
  cascadeWrite,

  /// obj.field += value
  compoundAssignment,

  /// Field used in operator == or hashCode
  equalityOperator,
}
