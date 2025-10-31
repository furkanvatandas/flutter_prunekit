import 'scope_context.dart';
import 'variable_types.dart';

/// Describes a variable declaration discovered during analysis.
///
/// This model contains enough metadata to support reporting, filtering, and
/// downstream reference tracking.
class VariableDeclaration {
  /// Unique identifier for the declaration (`filePath#scopeId#name`).
  final String id;

  /// Variable name as written in source code.
  final String name;

  /// Absolute file path that contains the declaration.
  final String filePath;

  /// Line number (1-indexed) where the declaration starts.
  final int lineNumber;

  /// Column number (0-indexed) where the declaration starts.
  final int columnNumber;

  /// Specific variable category (local, parameter, top-level, catch).
  final VariableType variableType;

  /// Lexical scope that owns this declaration.
  final ScopeContext scope;

  /// Mutability qualifier for the declaration.
  final Mutability mutability;

  /// Whether the name is intentionally unused (exactly `_`).
  final bool isIntentionallyUnused;

  /// Whether this declaration represents a constructor field initializer (`this.field`).
  final bool isFieldInitializer;

  /// Whether this declaration was created from a pattern binding.
  final bool isPatternBinding;

  /// Pattern classification when [isPatternBinding] is true.
  final PatternType? patternType;

  /// Annotations applied to the declaration (e.g., `@keepUnused`).
  final List<String> annotations;

  /// Ignore comments associated with the declaration.
  final List<String> ignoreComments;

  /// Static type from semantic analysis, if available.
  final String? staticType;

  /// Creates a new variable declaration record.
  const VariableDeclaration({
    required this.id,
    required this.name,
    required this.filePath,
    required this.lineNumber,
    required this.columnNumber,
    required this.variableType,
    required this.scope,
    required this.mutability,
    this.isIntentionallyUnused = false,
    this.isFieldInitializer = false,
    this.isPatternBinding = false,
    this.patternType,
    List<String>? annotations,
    List<String>? ignoreComments,
    this.staticType,
  })  : annotations = annotations ?? const [],
        ignoreComments = ignoreComments ?? const [];

  /// Whether the declaration is explicitly ignored via annotation or comment.
  ///
  /// T092: Checks for @keepUnused annotation or ignore comments.
  bool get hasExplicitIgnore {
    // Check for @keepUnused annotation
    if (annotations.any((ann) => ann.toLowerCase() == 'keepunused')) {
      return true;
    }

    // Only treat comments as "ignore" if they contain actual ignore directives
    return ignoreComments.any((comment) => comment.contains('ignore:') || comment.contains('ignore_for_file:'));
  }

  /// Convenience identifier used by reports.
  String get displayLabel => '$filePath:$lineNumber:$columnNumber - $name';

  @override
  String toString() => 'VariableDeclaration($name @ $filePath:$lineNumber:$columnNumber)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VariableDeclaration) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
