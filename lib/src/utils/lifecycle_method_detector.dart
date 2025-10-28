/// Detects Flutter/Dart lifecycle methods that should not be flagged as unused.
///
/// Lifecycle methods are automatically called by the framework and may appear
/// unused in static analysis.
class LifecycleMethodDetector {
  /// List of Flutter State lifecycle method names.
  static const List<String> flutterLifecycleMethods = [
    'initState',
    'dispose',
    'didUpdateWidget',
    'didChangeDependencies',
    'deactivate',
    'reassemble',
    'build',
  ];

  /// List of Flutter StatefulWidget lifecycle method names.
  static const List<String> statefulWidgetMethods = [
    'createState',
  ];

  /// List of other framework lifecycle method names.
  static const List<String> otherLifecycleMethods = [
    'main', // Entry point
  ];

  /// Checks if a method name is a known lifecycle method.
  ///
  /// Returns true if the method is a Flutter State lifecycle method,
  /// StatefulWidget method, or other framework lifecycle method.
  bool isLifecycleMethod(String methodName, {String? containingClass}) {
    // Check if it's a known lifecycle method name
    if (flutterLifecycleMethods.contains(methodName) ||
        statefulWidgetMethods.contains(methodName) ||
        otherLifecycleMethods.contains(methodName)) {
      return true;
    }

    // Additional heuristic checks based on class naming conventions
    if (containingClass != null) {
      if (isStateClass(containingClass) && flutterLifecycleMethods.contains(methodName)) {
        return true;
      }
      if (isStatefulWidgetClass(containingClass) && statefulWidgetMethods.contains(methodName)) {
        return true;
      }
    }

    return false;
  }

  /// Checks if a class is likely a Flutter State class.
  ///
  /// Uses naming convention heuristics to identify State classes.
  /// In practice, most State classes follow the pattern of ending with 'State'.
  bool isStateClass(String? className) {
    if (className == null) return false;
    return className.endsWith('State');
  }

  /// Checks if a class is likely a StatefulWidget class.
  ///
  /// Uses naming convention heuristics to identify StatefulWidget classes.
  /// Most Flutter widget classes contain 'Widget' or 'Screen' in their names.
  bool isStatefulWidgetClass(String? className) {
    if (className == null) return false;
    return className.contains('Widget') || className.contains('Screen');
  }
}
