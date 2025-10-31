import 'variable_declaration.dart';
import 'variable_types.dart';

/// Specialized declaration model for catch clause variables.
class CatchVariable extends VariableDeclaration {
  /// Distinguishes exception variable vs. stack trace variable.
  final CatchVariableType catchType;

  /// Exception type specified in `on Type catch (...)` clauses, if any.
  final String? exceptionType;

  /// Identifier describing the enclosing catch block.
  final String enclosingCatchBlock;

  const CatchVariable({
    required super.id,
    required super.name,
    required super.filePath,
    required super.lineNumber,
    required super.columnNumber,
    required super.scope,
    required super.mutability,
    required this.catchType,
    required this.enclosingCatchBlock,
    this.exceptionType,
    super.annotations,
    super.ignoreComments,
    super.staticType,
    super.isIntentionallyUnused,
  }) : super(
          variableType: VariableType.catchClause,
        );
}
