import 'package:analyzer/dart/ast/ast.dart';

/// Tracks field writes in constructor bodies, initializer lists, and
/// `this.field` parameters.
///
/// Fields can be initialized in three ways:
/// 1. Initializer list: `ClassName() : field = value`
/// 2. Constructor body: `ClassName() { field = value; }`
/// 3. Field parameter: `ClassName(this.field)`
///
/// This tracker identifies all three patterns to distinguish field
/// initialization from actual usage.
class ConstructorFieldTracker {
  /// Extracts field names from field formal parameters (`this.field`).
  ///
  /// Example: `Example(this.name, int age)` → `['name']`
  List<String> extractFieldParameterNames(FormalParameterList parameters) {
    final fieldNames = <String>[];

    for (final param in parameters.parameters) {
      // Handle DefaultFormalParameter wrapper
      final baseParam = param is DefaultFormalParameter ? param.parameter : param;

      if (baseParam is FieldFormalParameter) {
        // Extract the field name from the parameter
        final name = baseParam.name.lexeme;
        fieldNames.add(name);
      }
    }

    return fieldNames;
  }

  /// Extracts field names from constructor initializers.
  ///
  /// Example: `Example() : name = 'default', age = 0` → `['name', 'age']`
  List<String> extractInitializerFieldNames(
    List<ConstructorInitializer> initializers,
  ) {
    final fieldNames = <String>[];

    for (final initializer in initializers) {
      if (initializer is ConstructorFieldInitializer) {
        fieldNames.add(initializer.fieldName.name);
      }
    }

    return fieldNames;
  }

  /// Analyzes a constructor declaration and returns all field names that
  /// are written (initialized).
  ///
  /// Combines both field parameters and initializer list analysis.
  List<String> analyzeConstructor(ConstructorDeclaration constructor) {
    final fieldNames = <String>[];

    // Pattern 1: this.field in parameter list
    fieldNames.addAll(extractFieldParameterNames(constructor.parameters));

    // Pattern 2: field = value in initializer list
    fieldNames.addAll(extractInitializerFieldNames(constructor.initializers));

    return fieldNames;
  }

  /// Checks if a parameter is a field formal parameter.
  bool isFieldParameter(FormalParameter param) {
    final baseParam = param is DefaultFormalParameter ? param.parameter : param;
    return baseParam is FieldFormalParameter;
  }

  /// Gets the field name from a field formal parameter, if it is one.
  ///
  /// Returns null if the parameter is not a field formal parameter.
  String? getFieldNameFromParameter(FormalParameter param) {
    final baseParam = param is DefaultFormalParameter ? param.parameter : param;

    if (baseParam is FieldFormalParameter) {
      return baseParam.name.lexeme;
    }
    return null;
  }

  /// Checks if a constructor initializer is a field initializer.
  bool isFieldInitializer(ConstructorInitializer initializer) {
    return initializer is ConstructorFieldInitializer;
  }

  /// Checks if the given constructor has any field writes.
  ///
  /// Returns true if the constructor initializes at least one field
  /// (via parameter or initializer list).
  bool hasFieldWrites(ConstructorDeclaration constructor) {
    return analyzeConstructor(constructor).isNotEmpty;
  }
}
