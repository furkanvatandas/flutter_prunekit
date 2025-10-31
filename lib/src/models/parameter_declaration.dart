import 'variable_declaration.dart';
import 'variable_types.dart';

/// Specialized declaration model for callable parameters.
class ParameterDeclaration extends VariableDeclaration {
  /// Kind of parameter (required, optional positional, named).
  final ParameterKind parameterKind;

  /// Position in the parameter list (0-based index within its category).
  final int position;

  /// Default value expression, when provided.
  final String? defaultValue;

  /// Whether the parameter is marked with the `required` keyword.
  final bool isRequired;

  /// Name of the enclosing callable (function, method, constructor).
  final String enclosingCallable;

  const ParameterDeclaration({
    required super.id,
    required super.name,
    required super.filePath,
    required super.lineNumber,
    required super.columnNumber,
    required super.scope,
    required super.mutability,
    required this.parameterKind,
    required this.position,
    required this.isRequired,
    required this.enclosingCallable,
    super.annotations,
    super.ignoreComments,
    super.staticType,
    super.isIntentionallyUnused,
    this.defaultValue,
    super.isFieldInitializer,
  }) : super(
          variableType: VariableType.parameter,
        );

  /// Convenience helper describing the signature position.
  String get signaturePosition => '${parameterKind.name}#$position';
}
