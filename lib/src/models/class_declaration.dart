/// Represents a class declaration found in the codebase.
///
/// This model captures all metadata needed to identify and report unused classes.
class ClassDeclaration {
  /// The name of the class (without any prefixes or qualifiers).
  final String name;

  /// Absolute file path where the class is declared.
  final String filePath;

  /// Line number where the class declaration starts (1-indexed).
  final int lineNumber;

  /// The kind of class declaration (class, mixin, enum, extension).
  final ClassKind kind;

  /// Whether this is a private class (name starts with underscore).
  final bool isPrivate;

  /// Annotations applied to this class declaration.
  ///
  /// Used to detect @keepUnused and other ignore annotations.
  final List<String> annotations;

  /// Name of the superclass (if any).
  ///
  /// Used for inheritance-aware field access matching.
  /// Null for classes without explicit superclass or for Object superclass.
  final String? superclass;

  /// Creates a new class declaration.
  ClassDeclaration({
    required this.name,
    required this.filePath,
    required this.lineNumber,
    required this.kind,
    required this.isPrivate,
    required this.annotations,
    this.superclass,
  });

  /// Returns a unique identifier for this class declaration.
  ///
  /// Format: `packageRelativePath#ClassName`
  /// Example: `lib/models/user.dart#User`
  ///
  /// This enables deterministic sorting and deduplication.
  String get uniqueId => '$filePath#$name';

  /// Whether this class should be ignored based on annotations.
  ///
  /// Checks for @keepUnused, @dead_code_ignore, and similar annotations.
  bool get hasIgnoreAnnotation {
    return annotations
        .any((annotation) => annotation.contains('keepUnused') || annotation.contains('dead_code_ignore'));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassDeclaration &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          filePath == other.filePath &&
          lineNumber == other.lineNumber;

  @override
  int get hashCode => Object.hash(name, filePath, lineNumber);

  @override
  String toString() => 'ClassDeclaration($name at $filePath:$lineNumber, kind: $kind)';
}

/// The kind of class-like declaration.
enum ClassKind {
  /// Regular class declaration.
  class_,

  /// Abstract class declaration.
  abstractClass,

  /// Mixin declaration.
  mixin,

  /// Enum declaration.
  enum_,

  /// Extension declaration.
  extension,
}
