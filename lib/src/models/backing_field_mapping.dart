import 'field_declaration.dart';
import 'method_declaration.dart';

/// Links a field to its corresponding getter/setter methods for transitive
/// dead code detection.
///
/// This mapping identifies fields that serve as backing storage for properties
/// (getter/setter pairs), enabling detection of unused field-backed properties
/// where both the field and its accessors are unused.
class BackingFieldMapping {
  /// The backing field declaration
  final FieldDeclaration fieldDeclaration;

  /// Associated getter method (nullable)
  final MethodDeclaration? getterMethod;

  /// Associated setter method (nullable)
  final MethodDeclaration? setterMethod;

  /// Heuristic confidence that this mapping is correct (0.0 to 1.0)
  ///
  /// - High confidence (0.9-1.0): Naming convention match (_field + get/set field)
  /// - Medium confidence (0.6-0.8): Semantic analysis finds field in accessor body
  /// - Low confidence (0.3-0.5): Similar names but doesn't match convention
  final double confidenceScore;

  /// How the mapping was determined
  final BackingFieldMatchReason matchReason;

  BackingFieldMapping({
    required this.fieldDeclaration,
    required this.confidenceScore,
    required this.matchReason,
    this.getterMethod,
    this.setterMethod,
  }) {
    // Validation
    if (getterMethod == null && setterMethod == null) {
      throw ArgumentError(
        'At least one of getterMethod or setterMethod must be non-null',
      );
    }
    if (confidenceScore < 0.0 || confidenceScore > 1.0) {
      throw ArgumentError('confidenceScore must be between 0.0 and 1.0');
    }
    if (getterMethod != null && getterMethod!.methodType != MethodType.getter) {
      throw ArgumentError('getterMethod must be a getter');
    }
    if (setterMethod != null && setterMethod!.methodType != MethodType.setter) {
      throw ArgumentError('setterMethod must be a setter');
    }

    // Verify same declaring type
    final fieldType = fieldDeclaration.declaringType;
    if (getterMethod != null && getterMethod!.containingClass != fieldType) {
      throw ArgumentError(
        'Getter must be in the same declaring type as field',
      );
    }
    if (setterMethod != null && setterMethod!.containingClass != fieldType) {
      throw ArgumentError(
        'Setter must be in the same declaring type as field',
      );
    }
  }

  /// Property name (getter/setter name)
  String get propertyName {
    return getterMethod?.name ?? setterMethod!.name;
  }

  /// Check if this is high confidence mapping (≥0.9)
  bool get isHighConfidence => confidenceScore >= 0.9;

  /// Check if this is medium confidence mapping (0.6-0.8)
  bool get isMediumConfidence => confidenceScore >= 0.6 && confidenceScore < 0.9;

  /// Check if this is low confidence mapping (<0.6)
  bool get isLowConfidence => confidenceScore < 0.6;

  /// Convert to JSON representation
  Map<String, dynamic> toJson() => {
        'fieldDeclaration': fieldDeclaration.toJson(),
        'getterMethod': getterMethod != null
            ? {
                'name': getterMethod!.name,
                'filePath': getterMethod!.filePath,
                'lineNumber': getterMethod!.lineNumber,
              }
            : null,
        'setterMethod': setterMethod != null
            ? {
                'name': setterMethod!.name,
                'filePath': setterMethod!.filePath,
                'lineNumber': setterMethod!.lineNumber,
              }
            : null,
        'confidenceScore': confidenceScore,
        'matchReason': matchReason.name,
      };

  @override
  String toString() => 'BackingFieldMapping(field: ${fieldDeclaration.name}, '
      'property: $propertyName, confidence: $confidenceScore)';
}

/// How the field-to-accessor mapping was determined
enum BackingFieldMatchReason {
  /// Field _fieldName + get/set fieldName pattern (high confidence)
  namingConvention,

  /// Field accessed within getter/setter body (medium confidence)
  semanticAnalysis,

  /// Future: explicit @BackingField annotation
  explicitAnnotation,
}
