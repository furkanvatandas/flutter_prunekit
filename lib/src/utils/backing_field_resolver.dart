import '../models/field_declaration.dart';
import '../models/method_declaration.dart' as method_model;
import '../models/backing_field_mapping.dart';

/// Resolves backing fields for getter/setter properties using heuristic
/// matching and naming conventions.
///
/// Common Dart pattern: private field `_fieldName` with public getter/setter `fieldName`.
///
/// Example:
/// ```dart
/// String _name;
/// String get name => _name;
/// set name(String value) => _name = value;
/// ```
class BackingFieldResolver {
  /// Identifies backing field mappings using naming convention heuristic.
  ///
  /// Matches fields with pattern `_fieldName` to getters/setters named `fieldName`
  /// in the same class. Returns high confidence (0.9-1.0) mappings.
  List<BackingFieldMapping> identifyBackingFields({
    required Map<String, FieldDeclaration> fieldDeclarations,
    required Map<String, method_model.MethodDeclaration> methodDeclarations,
  }) {
    final mappings = <BackingFieldMapping>[];

    // Group fields by declaring type
    final fieldsByType = <String, List<FieldDeclaration>>{};
    for (final field in fieldDeclarations.values) {
      fieldsByType.putIfAbsent(field.declaringType, () => []).add(field);
    }

    // Group methods by containing class
    final methodsByClass = <String, List<method_model.MethodDeclaration>>{};
    for (final method in methodDeclarations.values) {
      final containingClass = method.containingClass;
      if (containingClass != null) {
        methodsByClass.putIfAbsent(containingClass, () => []).add(method);
      }
    }

    // For each class, find backing field patterns
    for (final className in fieldsByType.keys) {
      final classFields = fieldsByType[className]!;
      final classMethods = methodsByClass[className] ?? [];

      // Look for _fieldName + get/set fieldName pattern
      for (final field in classFields) {
        if (field.visibility != Visibility.private) {
          continue; // Backing fields are typically private
        }

        // Check if field name matches _xxx pattern
        final fieldName = field.name;
        if (fieldName.startsWith('_') && fieldName.length > 1) {
          final propertyName = fieldName.substring(1);

          // Find matching getter/setter
          method_model.MethodDeclaration? getter;
          method_model.MethodDeclaration? setter;

          for (final method in classMethods) {
            if (method.name == propertyName) {
              if (method.methodType == method_model.MethodType.getter) {
                getter = method;
              } else if (method.methodType == method_model.MethodType.setter) {
                setter = method;
              }
            }
          }

          // Create mapping if we found at least one accessor
          if (getter != null || setter != null) {
            mappings.add(
              BackingFieldMapping(
                fieldDeclaration: field,
                getterMethod: getter,
                setterMethod: setter,
                confidenceScore: 0.95, // High confidence for naming convention
                matchReason: BackingFieldMatchReason.namingConvention,
              ),
            );
          }
        }
      }
    }

    return mappings;
  }

  /// Analyzes getter/setter body for field references using semantic analysis.
  ///
  /// This is a placeholder for future semantic analysis implementation.
  /// Currently returns medium confidence mappings based on method body analysis.
  ///
  /// TODO: Implement full semantic analysis of method bodies to find field references.
  List<BackingFieldMapping> analyzeGetterSetterBody({
    required Map<String, FieldDeclaration> fieldDeclarations,
    required Map<String, method_model.MethodDeclaration> methodDeclarations,
  }) {
    // Placeholder for semantic analysis
    // This will be implemented in a future iteration with full AST traversal
    // of getter/setter bodies to find field references
    return [];
  }

  /// Combines all heuristics to produce a complete list of backing field mappings.
  List<BackingFieldMapping> resolveAll({
    required Map<String, FieldDeclaration> fieldDeclarations,
    required Map<String, method_model.MethodDeclaration> methodDeclarations,
  }) {
    final mappings = <BackingFieldMapping>[];

    // Heuristic 1: Naming convention (high confidence)
    mappings.addAll(identifyBackingFields(
      fieldDeclarations: fieldDeclarations,
      methodDeclarations: methodDeclarations,
    ));

    // Heuristic 2: Semantic analysis (medium confidence)
    // mappings.addAll(analyzeGetterSetterBody(
    //   fieldDeclarations: fieldDeclarations,
    //   methodDeclarations: methodDeclarations,
    // ));

    return mappings;
  }
}
