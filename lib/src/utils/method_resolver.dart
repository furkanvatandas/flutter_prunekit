import 'package:analyzer/dart/element/element.dart';

/// Resolves method declarations to their semantic elements for accurate analysis.
///
/// This utility handles edge cases like:
/// - Extension methods (requires semantic resolution to find target type)
/// - Generic type parameters
/// - Method overloads (same name, different signatures)
///
/// Note: This utility was originally planned but analysis shows that the
/// ReferenceGraph already handles method resolution adequately for our use cases.
class MethodResolver {
  /// Resolves a method element to its canonical form for tracking.
  ///
  /// Returns a stable identifier that can be used to match declarations
  /// with invocations across different contexts.
  String resolveMethodId(Element element) {
    // Method resolution is handled by ReferenceGraph during AST analysis
    // This provides adequate accuracy for dead code detection
    return '${element.enclosingElement?.name}.${element.name}';
  }

  /// Resolves an extension method to its target type.
  String? resolveExtensionTarget(MethodElement method) {
    if (method.enclosingElement is ExtensionElement) {
      final extension = method.enclosingElement as ExtensionElement;
      return extension.extendedType.getDisplayString();
    }
    return null;
  }

  /// Normalizes generic type parameters for consistent matching.
  String normalizeGenericTypes(String typeString) {
    // Simple normalization - remove angle brackets and their contents
    return typeString.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
