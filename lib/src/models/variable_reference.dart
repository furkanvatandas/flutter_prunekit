import 'scope_context.dart';
import 'variable_types.dart';

/// Represents a single read/write occurrence of a variable in source code.
class VariableReference {
  /// Unique identifier for the reference (`filePath#line#column#variableId`).
  final String id;

  /// Identifier of the referenced variable declaration.
  final String variableId;

  /// Absolute file path that contains the reference.
  final String filePath;

  /// Line number (1-indexed) for the reference location.
  final int lineNumber;

  /// Column number (0-indexed) for the reference location.
  final int columnNumber;

  /// Classification of the reference: read, write, or both.
  final ReferenceType referenceType;

  /// Context in which the reference occurs.
  final ReferenceContext context;

  /// Scope in which the reference appears.
  final ScopeContext enclosingScope;

  /// Whether this reference captures the variable from an outer scope.
  final bool isCapturedByClosure;

  /// Creates a new variable reference record.
  const VariableReference({
    required this.id,
    required this.variableId,
    required this.filePath,
    required this.lineNumber,
    required this.columnNumber,
    required this.referenceType,
    required this.context,
    required this.enclosingScope,
    this.isCapturedByClosure = false,
  });

  @override
  String toString() => 'VariableReference($variableId @ $filePath:$lineNumber:$columnNumber, $referenceType)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VariableReference) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
