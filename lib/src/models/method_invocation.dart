/// Represents a method or function invocation in Dart source code.
///
/// This model tracks where methods are called/referenced to determine
/// which declarations are actually used.
class MethodInvocation {
  /// The name of the method being invoked.
  final String methodName;

  /// The target class/type name if this is a class method call.
  /// Null for top-level function calls.
  final String? targetClass;

  /// Absolute path of the file where the target declaration lives (if known).
  ///
  /// Used to disambiguate methods with identical names defined in different
  /// files/classes.
  final String? declarationFilePath;

  /// The file path where this invocation occurs.
  final String filePath;

  /// The line number where the invocation occurs (1-indexed).
  final int lineNumber;

  /// The type of invocation (instance call, static call, etc.).
  final InvocationType invocationType;

  /// Whether this is a dynamic call that cannot be statically resolved.
  final bool isDynamic;

  /// Whether this invocation is within a comment reference.
  final bool isCommentReference;

  /// Whether this invocation is a tear-off (method reference without call).
  final bool isTearOff;

  MethodInvocation({
    required this.methodName,
    required this.filePath,
    required this.lineNumber,
    required this.invocationType,
    this.targetClass,
    this.declarationFilePath,
    this.isDynamic = false,
    this.isCommentReference = false,
    this.isTearOff = false,
  });

  /// Returns a string identifier for this invocation target.
  ///
  /// Format:
  /// - Top-level functions: `functionName`
  /// - Instance/static methods: `ClassName.methodName`
  /// - Operators: `ClassName.operator<symbol>`
  ///
  /// Note: This is not necessarily unique (multiple calls can target the same method).
  String get targetId {
    final buffer = StringBuffer();

    if (targetClass != null) {
      buffer.write(targetClass);
      buffer.write('.');
    }

    buffer.write(methodName);

    return buffer.toString();
  }

  /// Whether this invocation can be statically resolved to a declaration.
  bool get isStaticallyResolvable => !isDynamic;

  @override
  String toString() {
    return 'MethodInvocation('
        'methodName: $methodName, '
        'targetClass: $targetClass, '
        'declarationFilePath: $declarationFilePath, '
        'type: $invocationType, '
        'file: $filePath:$lineNumber'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MethodInvocation &&
        other.methodName == methodName &&
        other.targetClass == targetClass &&
        other.declarationFilePath == declarationFilePath &&
        other.filePath == filePath &&
        other.lineNumber == lineNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      methodName,
      targetClass,
      declarationFilePath,
      filePath,
      lineNumber,
    );
  }
}

/// Types of method invocations.
enum InvocationType {
  /// Instance method call on an object.
  instance,

  /// Static method call on a class.
  static,

  /// Top-level function call.
  topLevel,

  /// Extension method call.
  extension,

  /// Getter access.
  getter,

  /// Setter access.
  setter,

  /// Operator invocation (arithmetic, indexing, etc.).
  operator,

  /// Function tear-off (reference without calling).
  tearOff,

  /// Dynamic call that cannot be statically resolved.
  dynamic,
}
