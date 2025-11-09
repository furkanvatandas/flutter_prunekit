import 'package:glob/glob.dart';
import 'field_declaration.dart';

/// Represents a pattern for excluding files, classes, methods, or variables from analysis.
///
/// Supports glob patterns like `lib/legacy/**` or `**/old_*.dart`.
///
/// **Phase 2 Enhancement (T009)**: Extended to support method-level patterns
/// (e.g., `ClassName.methodName`, `_private*`, `on*`).
class IgnorePattern {
  /// The glob pattern string.
  final String pattern;

  /// The source of this ignore pattern (for priority resolution).
  final IgnoreSource source;

  /// The type of pattern (file, class, or method) (T009).
  final IgnorePatternType type;

  /// The compiled glob matcher.
  final Glob _glob;

  /// Creates a new ignore pattern.
  ///
  /// Throws [FormatException] if the pattern is invalid.
  IgnorePattern({
    required this.pattern,
    required this.source,
    this.type = IgnorePatternType.file,
  }) : _glob = Glob(pattern);

  /// Checks if the given file path matches this pattern.
  ///
  /// Uses normalized paths for consistent matching across platforms.
  bool matches(String filePath) {
    return _glob.matches(filePath);
  }

  /// Checks if a method name matches this pattern (T009).
  ///
  /// For method patterns like:
  /// - `methodName` - exact match
  /// - `_private*` - prefix match
  /// - `on*` - event handler prefix
  /// - `ClassName.methodName` - fully qualified
  bool matchesMethod(String methodName, {String? className}) {
    if (type != IgnorePatternType.method) {
      return false;
    }

    // Handle fully qualified patterns (ClassName.methodName)
    if (pattern.contains('.')) {
      final parts = pattern.split('.');
      if (parts.length == 2) {
        final classPattern = parts[0];
        final methodPattern = parts[1];

        // Match class name if provided
        if (className != null) {
          if (!Glob(classPattern).matches(className)) {
            return false;
          }
        }

        // Match method name
        return Glob(methodPattern).matches(methodName);
      }
    }

    // Simple method name pattern
    return _glob.matches(methodName);
  }

  /// Checks if a variable name matches this pattern (T012).
  bool matchesVariableName(String variableName) {
    if (type != IgnorePatternType.variable) {
      return false;
    }
    return _glob.matches(variableName);
  }

  /// Checks if a parameter name matches this pattern (T012).
  bool matchesParameterName(String parameterName) {
    if (type == IgnorePatternType.parameter) {
      return _glob.matches(parameterName);
    }
    if (type == IgnorePatternType.variable) {
      // Variable patterns may be shared for parameters when no dedicated entry exists.
      return _glob.matches(parameterName);
    }
    return false;
  }

  /// Checks if a field matches this pattern (T010).
  ///
  /// For field patterns like:
  /// - `fieldName` - exact field name match
  /// - `_internal*` - prefix match (e.g., `_internalCache`, `_internalData`)
  /// - `serialization*` - pattern match
  /// - `**/*_cache` - any field ending with `_cache` in any class
  /// - `ClassName.fieldName` - fully qualified field pattern
  bool matchesField(FieldDeclaration field) {
    if (type != IgnorePatternType.field) {
      return false;
    }

    // Handle fully qualified patterns (ClassName.fieldName)
    if (pattern.contains('.')) {
      final parts = pattern.split('.');
      if (parts.length >= 2) {
        final classPattern = parts.take(parts.length - 1).join('.');
        final fieldPattern = parts.last;

        // Match class name
        if (!Glob(classPattern).matches(field.declaringType)) {
          return false;
        }

        // Match field name
        return Glob(fieldPattern).matches(field.name);
      }
    }

    // Simple field name pattern
    return _glob.matches(field.name);
  }

  /// Returns the priority of this pattern source.
  ///
  /// Higher priority patterns take precedence:
  /// - Annotation (@keepUnused): priority 3
  /// - Config file (flutter_prunekit.yaml): priority 2
  /// - CLI flag (--exclude): priority 1
  int get priority {
    switch (source) {
      case IgnoreSource.annotation:
        return 3;
      case IgnoreSource.configFile:
        return 2;
      case IgnoreSource.cliFlag:
        return 1;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IgnorePattern && runtimeType == other.runtimeType && pattern == other.pattern && source == other.source;

  @override
  int get hashCode => Object.hash(pattern, source);

  @override
  String toString() => 'IgnorePattern($pattern, source: ${source.name})';
}

/// The type of pattern (T009).
enum IgnorePatternType {
  /// Pattern matches file paths (e.g., `lib/legacy/**`).
  file,

  /// Pattern matches class names (e.g., `LegacyWidget`).
  classPattern,

  /// Pattern matches method names (e.g., `_private*`, `ClassName.methodName`).
  method,

  /// Pattern matches variable names (e.g., `temp_*`).
  variable,

  /// Pattern matches parameter names (e.g., `_unused*`).
  parameter,

  /// Pattern matches field names (e.g., `_internal*`, `serialization*`) (T010).
  field,
}

/// The source of an ignore pattern.
///
/// Used to resolve conflicts when multiple patterns apply.
/// Per T0A3, priority order is: annotation > config file > CLI flag.
enum IgnoreSource {
  /// From @keepUnused or @dead_code_ignore annotation (highest priority).
  annotation,

  /// From flutter_prunekit.yaml configuration file.
  configFile,

  /// From --exclude CLI flag (lowest priority).
  cliFlag,
}
