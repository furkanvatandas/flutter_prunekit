import '../models/scope_context.dart';
import '../models/variable_declaration.dart';
import '../models/variable_types.dart';

/// Maintains the lexical scope stack while traversing the AST.
///
/// Variable detection relies on deterministic scope information in order to
/// link declarations to the correct context and to resolve references that may
/// originate from nested blocks, closures, or catch clauses.
class VariableScopeTracker {
  final List<ScopeContext> _scopeStack = [];
  final Map<String, List<VariableDeclaration>> _variablesByScopeId = {};
  final Map<String, ScopeContext> _scopesById = {};

  /// Pushes a new scope onto the stack.
  ScopeContext pushScope({
    required ScopeType scopeType,
    required String filePath,
    required int startLine,
    required int endLine,
    String? enclosingDeclaration,
  }) {
    final depth = _scopeStack.length;
    final parentScope = _scopeStack.isEmpty ? null : _scopeStack.last;
    final id = _buildScopeId(filePath, startLine, endLine, scopeType, depth);

    final scope = ScopeContext(
      id: id,
      scopeType: scopeType,
      filePath: filePath,
      startLine: startLine,
      endLine: endLine,
      depth: depth,
      parentScopeId: parentScope?.id,
      enclosingDeclaration: enclosingDeclaration ?? parentScope?.enclosingDeclaration,
    );

    _scopeStack.add(scope);
    _scopesById[id] = scope;
    return scope;
  }

  /// Pops the current scope from the stack.
  ScopeContext popScope() {
    if (_scopeStack.isEmpty) {
      throw StateError('Cannot pop scope: scope stack is empty.');
    }

    final scope = _scopeStack.removeLast();
    _variablesByScopeId.remove(scope.id);
    return scope;
  }

  /// Returns the scope that is currently on top of the stack.
  ScopeContext? get currentScope => _scopeStack.isEmpty ? null : _scopeStack.last;

  /// Finds a scope by its ID (used for walking parent scope chains).
  ScopeContext? findScopeById(String scopeId) => _scopesById[scopeId];

  /// Registers a variable declaration with the tracker.
  void registerVariable(VariableDeclaration declaration) {
    final scopeId = declaration.scope.id;
    final variables = _variablesByScopeId.putIfAbsent(scopeId, () => []);
    variables.add(declaration);
  }

  /// Attempts to resolve a variable by walking the scope chain from the
  /// innermost scope to the outermost.
  VariableDeclaration? resolveVariable(String name) {
    for (var i = _scopeStack.length - 1; i >= 0; i--) {
      final scope = _scopeStack[i];
      final variables = _variablesByScopeId[scope.id];
      if (variables == null) {
        continue;
      }

      for (final declaration in variables) {
        if (declaration.name == name) {
          return declaration;
        }
      }
    }
    return null;
  }

  /// Returns the current depth of the stack (0 for top-level).
  int get depth => _scopeStack.length;

  /// Builds a deterministic identifier for a scope.
  String _buildScopeId(
    String filePath,
    int startLine,
    int endLine,
    ScopeType scopeType,
    int depth,
  ) {
    return '$filePath#$startLine-$endLine#${scopeType.name}#$depth';
  }
}
