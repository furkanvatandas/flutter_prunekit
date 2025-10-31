import 'variable_declaration.dart';
import 'variable_types.dart';

/// Specialized declaration model for variables created via pattern matching.
class PatternVariable extends VariableDeclaration {
  /// Source snippet of the pattern that produced this binding.
  final String patternExpression;

  /// Index of the binding within the pattern (0-based).
  final int bindingPosition;

  /// Whether the binding is a rest element (e.g., `...rest`).
  final bool isRestElement;

  const PatternVariable({
    required super.id,
    required super.name,
    required super.filePath,
    required super.lineNumber,
    required super.columnNumber,
    required super.scope,
    required super.mutability,
    required this.patternExpression,
    required this.bindingPosition,
    required this.isRestElement,
    required PatternType super.patternType,
    super.annotations,
    super.ignoreComments,
    super.staticType,
    super.isIntentionallyUnused,
  }) : super(
          variableType: VariableType.local,
          isPatternBinding: true,
        );
}
