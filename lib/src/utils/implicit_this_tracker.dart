import 'package:analyzer/dart/element/element.dart';

/// Tracks enclosing class context during AST traversal to identify implicit
/// `this` field access.
///
/// In Dart, fields can be accessed without an explicit `this.` prefix when
/// referenced within the same class. This tracker maintains a class context
/// stack to determine when a SimpleIdentifier actually refers to a field
/// of the enclosing class.
///
/// Example:
/// ```dart
/// class Example {
///   String name = 'test';
///
///   void method() {
///     print(name);  // Implicit this - name is a field
///   }
/// }
/// ```
class ImplicitThisTracker {
  /// Stack of enclosing class/mixin/enum elements.
  ///
  /// The top of the stack represents the current class context.
  final List<ClassElement> _classStack = [];

  /// Pushes a class context onto the stack.
  ///
  /// Call this when entering a class/mixin/enum declaration.
  void pushClass(ClassElement classElement) {
    _classStack.add(classElement);
  }

  /// Pops the current class context from the stack.
  ///
  /// Call this when exiting a class/mixin/enum declaration.
  void popClass() {
    if (_classStack.isNotEmpty) {
      _classStack.removeLast();
    }
  }

  /// Returns the current enclosing class element, if any.
  ///
  /// Returns null if not currently inside a class/mixin/enum.
  ClassElement? get currentClass {
    return _classStack.isEmpty ? null : _classStack.last;
  }

  /// Checks if the given field element belongs to the current class context.
  ///
  /// This is used to determine if a field access is an implicit `this`
  /// reference (accessed without explicit qualifier).
  bool isFieldInCurrentClass(FieldElement fieldElement) {
    final current = currentClass;
    if (current == null) {
      return false;
    }

    // Check if the field's enclosing element matches the current class
    return fieldElement.enclosingElement == current;
  }

  /// Checks if currently inside any class context.
  bool get isInClassContext => _classStack.isNotEmpty;

  /// Returns the depth of the current class nesting.
  ///
  /// 0 = not in any class, 1 = in top-level class, 2+ = nested classes
  int get classDepth => _classStack.length;

  /// Clears the entire class stack.
  ///
  /// Useful for resetting state between file analyses.
  void clear() {
    _classStack.clear();
  }

  @override
  String toString() {
    if (_classStack.isEmpty) {
      return 'ImplicitThisTracker(no context)';
    }
    final classNames = _classStack.map((c) => c.name).join(' > ');
    return 'ImplicitThisTracker(context: $classNames)';
  }
}
