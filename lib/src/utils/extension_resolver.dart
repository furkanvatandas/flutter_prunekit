import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// Utility class for resolving extension method references.
///
/// This class provides methods to determine if AST nodes (method invocations,
/// property accesses, operators) resolve to extension members, and to generate
/// unique identifiers for extension declarations.
///
/// Extension resolution requires semantic analysis (resolved AST with element
/// information). If semantic resolution is unavailable, methods return null.
class ExtensionResolver {
  /// Resolves a method invocation to its defining extension, if any.
  ///
  /// Returns the [ExtensionElement] that declares the method, or null if:
  /// - The method is not an extension method
  /// - Semantic analysis is unavailable (staticElement is null)
  /// - The method is an instance method or top-level function
  ///
  /// Example:
  /// ```dart
  /// // For: "hello".capitalize()
  /// final extension = resolveExtensionFromMethodCall(node);
  /// // Returns: StringExtension element if capitalize is defined there
  /// ```
  static ExtensionElement? resolveExtensionFromMethodCall(MethodInvocation node) {
    // Access the static element through the methodName's element getter
    final element = node.methodName.element;
    if (element == null) {
      return null; // Semantic analysis unavailable
    }

    final enclosing = element.enclosingElement;
    if (enclosing is ExtensionElement) {
      return enclosing;
    }

    return null; // Not an extension method
  }

  /// Resolves a property access to its defining extension, if any.
  ///
  /// Returns the [ExtensionElement] that declares the getter, or null if:
  /// - The property is not an extension getter
  /// - Semantic analysis is unavailable
  /// - The property is an instance property or top-level variable
  ///
  /// Example:
  /// ```dart
  /// // For: "hello world".wordCount
  /// final extension = resolveExtensionFromPropertyAccess(node);
  /// // Returns: StringExtension element if wordCount getter is defined there
  /// ```
  static ExtensionElement? resolveExtensionFromPropertyAccess(PropertyAccess node) {
    // Access the static element through the propertyName's element getter
    final element = node.propertyName.element;
    if (element == null) {
      return null; // Semantic analysis unavailable
    }

    final enclosing = element.enclosingElement;
    if (enclosing is ExtensionElement) {
      return enclosing;
    }

    return null; // Not an extension property
  }

  /// Resolves a binary expression (operator) to its defining extension, if any.
  ///
  /// Returns the [ExtensionElement] that declares the operator, or null if:
  /// - The operator is not an extension operator
  /// - Semantic analysis is unavailable
  /// - The operator is built-in or from the base type
  ///
  /// Example:
  /// ```dart
  /// // For: vector1 + vector2
  /// final extension = resolveExtensionFromOperator(node);
  /// // Returns: VectorExtension element if operator+ is defined there
  /// ```
  static ExtensionElement? resolveExtensionFromOperator(BinaryExpression node) {
    // For binary expressions, the element is accessed via staticElement property
    final element = node.element;
    if (element == null) {
      return null; // Semantic analysis unavailable
    }

    final enclosing = element.enclosingElement;
    if (enclosing is ExtensionElement) {
      return enclosing;
    }

    return null; // Not an extension operator
  }

  /// Generates a unique identifier for an extension declaration.
  ///
  /// For named extensions, returns: `$filePath#$extensionName`
  /// For unnamed extensions, returns: `$filePath:$lineNumber`
  ///
  /// The file path + line number scheme ensures unique IDs for unnamed extensions
  /// while maintaining readability for named extensions.
  ///
  /// Parameters:
  /// - [element]: The extension element from the Dart Analyzer
  /// - [filePath]: Absolute path to the file containing the extension
  /// - [lineNumber]: Line number of the extension declaration (for unnamed extensions)
  ///
  /// Example:
  /// ```dart
  /// // Named extension
  /// generateExtensionId(stringExt, "/lib/utils.dart", 10)
  /// // Returns: "/lib/utils.dart#StringExtension"
  ///
  /// // Unnamed extension
  /// generateExtensionId(unnamedExt, "/lib/utils.dart", 42)
  /// // Returns: "/lib/utils.dart:42"
  /// ```
  static String generateExtensionId(
    ExtensionElement element,
    String filePath,
    int lineNumber,
  ) {
    final name = element.name;
    if (name != null && name.isNotEmpty) {
      // Named extension: use file path + extension name for global uniqueness
      return '$filePath#$name';
    } else {
      // Unnamed extension: use file path + line number
      return '$filePath:$lineNumber';
    }
  }
}
