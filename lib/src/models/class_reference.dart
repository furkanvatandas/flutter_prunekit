/// Represents a reference to a class found in the codebase.
///
/// This model captures where and how a class is being used.
class ClassReference {
  /// The name of the class being referenced.
  final String className;

  /// Absolute file path where the reference occurs.
  final String sourceFile;

  /// Line number where the reference occurs (1-indexed).
  final int lineNumber;

  /// The kind of reference (how the class is being used).
  final ReferenceKind kind;

  /// Whether this reference is through dynamic typing.
  ///
  /// Dynamic references cannot be statically verified and may indicate
  /// potential false negatives if the class is only used dynamically.
  final bool isDynamic;

  /// Creates a new class reference.
  ClassReference({
    required this.className,
    required this.sourceFile,
    required this.lineNumber,
    required this.kind,
    this.isDynamic = false,
  });

  /// Creates a copy with a different source file path.
  ///
  /// Used by ReferenceGraph for string interning optimization (T071).
  ClassReference copyWith({String? sourceFile}) {
    return ClassReference(
      className: className,
      sourceFile: sourceFile ?? this.sourceFile,
      lineNumber: lineNumber,
      kind: kind,
      isDynamic: isDynamic,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassReference &&
          runtimeType == other.runtimeType &&
          className == other.className &&
          sourceFile == other.sourceFile &&
          lineNumber == other.lineNumber &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(className, sourceFile, lineNumber, kind);

  @override
  String toString() => 'ClassReference($className at $sourceFile:$lineNumber, kind: ${kind.name})';
}

/// The kind of class reference (how the class is being used).
///
/// Per FR-005, this enum defines all supported reference types.
enum ReferenceKind {
  /// Direct instantiation: `SomeClass()` or `new SomeClass()`
  instantiation,

  /// Type annotation: `SomeClass variable` or `List<SomeClass>`
  typeAnnotation,

  /// Inheritance: `extends SomeClass`, `implements SomeClass`, `with SomeMixin`
  inheritance,

  /// Static member access: `SomeClass.staticMethod()`
  staticAccess,

  /// Import/export: `import 'package:foo/bar.dart' show SomeClass;`
  importExport,

  /// Type check: `obj is SomeClass`, `obj as SomeClass`
  typeCheck,

  /// Generic type argument: `<SomeClass>[]` in generic contexts
  genericTypeArgument,

  /// Factory constructor: `factory SomeClass.named()`
  factoryConstructor,

  /// Metadata/annotation: `@SomeClass()` or `@SomeClass`
  annotation,

  /// Extension member usage: `object.extensionMethod()`, `object.extensionGetter`, `object1 + object2` (extension operator)
  extensionMember,
}
