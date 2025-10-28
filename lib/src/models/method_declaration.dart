/// Represents a method or function declaration in Dart source code.
///
/// This model tracks method-level declarations for dead code analysis,
/// including top-level functions, instance methods, static methods,
/// getters, setters, operators, and extension methods.
class MethodDeclaration {
  /// The name of the method or function.
  final String name;

  /// The containing class name, if this is a class/extension method.
  /// Null for top-level functions.
  final String? containingClass;

  /// The file path where this method is declared.
  final String filePath;

  /// The line number where the declaration starts (1-indexed).
  final int lineNumber;

  /// The type of method (instance, static, getter, setter, etc.).
  final MethodType methodType;

  /// Whether this is a public or private declaration.
  final Visibility visibility;

  /// Annotations applied to this method (e.g., @keepUnused).
  final List<String> annotations;

  /// Whether this method overrides a parent class/interface method.
  final bool isOverride;

  /// Whether this is an abstract method (no implementation) (T101).
  final bool isAbstract;

  /// Whether this is a static method/getter/setter.
  final bool isStatic;

  /// Whether this is a Flutter lifecycle method (initState, dispose, etc.).
  final bool isLifecycleMethod;

  /// For extension methods: whether this is a getter.
  final bool isGetter;

  /// For extension methods: whether this is a setter.
  final bool isSetter;

  /// For extension methods: whether this is an operator.
  final bool isOperator;

  /// For extension methods: the target type name this extension applies to.
  final String? extensionTargetType;

  MethodDeclaration({
    required this.name,
    required this.filePath,
    required this.lineNumber,
    required this.methodType,
    required this.visibility,
    this.containingClass,
    this.annotations = const [],
    this.isOverride = false,
    this.isAbstract = false, // T101
    this.isStatic = false,
    this.isLifecycleMethod = false,
    this.isGetter = false,
    this.isSetter = false,
    this.isOperator = false,
    this.extensionTargetType,
  });

  /// Returns a unique identifier for this method.
  ///
  /// Format:
  /// - Top-level functions: `filePath#functionName`
  /// - Instance/static methods: `filePath#ClassName.methodName`
  /// - Getters: `filePath#ClassName.getterName`
  /// - Setters: `filePath#ClassName.setterName=`
  /// - Operators: `filePath#ClassName.operator<symbol>`
  String get uniqueId {
    final buffer = StringBuffer(filePath);
    buffer.write('#');

    if (containingClass != null) {
      buffer.write(containingClass);
      buffer.write('.');
    }

    buffer.write(name);

    // Add suffix for setters to distinguish from getters
    if (methodType == MethodType.setter) {
      buffer.write('=');
    }

    return buffer.toString();
  }

  /// Whether this method is private (name starts with underscore).
  bool get isPrivate => visibility == Visibility.private;

  /// Whether this method is public.
  bool get isPublic => visibility == Visibility.public;

  /// Whether this is a top-level function (not a class member).
  bool get isTopLevel => methodType == MethodType.topLevel;

  /// Whether this is an extension method.
  bool get isExtensionMethod => methodType == MethodType.extension;

  @override
  String toString() {
    return 'MethodDeclaration('
        'name: $name, '
        'containingClass: $containingClass, '
        'type: $methodType, '
        'file: $filePath:$lineNumber'
        '${extensionTargetType != null ? ', extensionTarget: $extensionTargetType' : ''}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MethodDeclaration && other.uniqueId == uniqueId;
  }

  @override
  int get hashCode => uniqueId.hashCode;
}

/// Types of methods/functions that can be declared.
enum MethodType {
  /// Instance method on a class.
  instance,

  /// Static method on a class.
  static,

  /// Getter property.
  getter,

  /// Setter property.
  setter,

  /// Operator method (operator+, operator[], etc.).
  operator,

  /// Top-level function (not a class member).
  topLevel,

  /// Extension method.
  extension,
}

/// Visibility of a method/function.
enum Visibility {
  /// Public declaration (does not start with underscore).
  public,

  /// Private declaration (starts with underscore).
  private,
}
