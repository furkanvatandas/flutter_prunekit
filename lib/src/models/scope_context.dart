import 'variable_types.dart';

/// Represents a lexical scope that can own variable declarations and references.
///
/// Scopes form a tree and are tracked by the analyzer while traversing the AST.
class ScopeContext {
  /// Unique identifier for the scope.
  ///
  /// Format: `filePath#lineStart-lineEnd#scopeType#depth`.
  final String id;

  /// The kind of scope (function, method, block, closure, catch block).
  final ScopeType scopeType;

  /// Absolute path to the file that contains this scope.
  final String filePath;

  /// First line (1-indexed) covered by the scope.
  final int startLine;

  /// Last line (1-indexed) covered by the scope.
  final int endLine;

  /// Identifier of the parent scope, if any.
  final String? parentScopeId;

  /// Nesting depth (0 for top level).
  final int depth;

  /// Name of the enclosing declaration (function, method, etc.).
  final String? enclosingDeclaration;

  /// Creates a new scope context.
  const ScopeContext({
    required this.id,
    required this.scopeType,
    required this.filePath,
    required this.startLine,
    required this.endLine,
    required this.depth,
    this.parentScopeId,
    this.enclosingDeclaration,
  });

  /// Returns true when the provided line number is within the scope bounds.
  bool containsLine(int line) => line >= startLine && line <= endLine;

  @override
  String toString() => 'ScopeContext($id, type: $scopeType, depth: $depth)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ScopeContext) return false;
    return id == other.id && filePath == other.filePath;
  }

  @override
  int get hashCode => Object.hash(id, filePath);
}
