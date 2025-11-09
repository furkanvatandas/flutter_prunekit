import 'package:analyzer/dart/ast/ast.dart';

/// Tracks fields used in `operator ==` and `hashCode` method implementations.
///
/// Fields referenced in equality operators are legitimate usage, even if not
/// accessed elsewhere. This tracker identifies equality operator methods and
/// extracts field references from their implementations.
///
/// Example:
/// ```dart
/// @override
/// bool operator ==(Object other) =>
///   other is Person && name == other.name && age == other.age;
///
/// @override
/// int get hashCode => Object.hash(name, age);
/// ```
class EqualityOperatorTracker {
  /// Checks if a method declaration is an equality operator.
  ///
  /// Returns true for `operator ==` or `hashCode` getter.
  bool isEqualityMethod(MethodDeclaration method) {
    // Check for operator ==
    if (method.isOperator && method.name.lexeme == '==') {
      return true;
    }

    // Check for hashCode getter
    if (method.isGetter && method.name.lexeme == 'hashCode') {
      return true;
    }

    return false;
  }

  /// Checks if currently inside an equality operator method.
  ///
  /// This can be used during AST traversal to mark field accesses
  /// with the `inEqualityOperator` flag.
  bool isInEqualityContext(MethodDeclaration? enclosingMethod) {
    return enclosingMethod != null && isEqualityMethod(enclosingMethod);
  }

  /// Extracts field names referenced in an equality operator implementation.
  ///
  /// This is a simplified implementation that identifies methods containing
  /// equality logic. Full field reference extraction is done in the AST analyzer
  /// during traversal with semantic resolution.
  bool containsFieldReferences(MethodDeclaration method) {
    return isEqualityMethod(method) && method.body is ExpressionFunctionBody || method.body is BlockFunctionBody;
  }
}
