import 'package:analyzer/dart/ast/ast.dart';

/// Helper for identifying constructor parameters that initialize instance fields.
class ConstructorInitializerDetector {
  const ConstructorInitializerDetector();

  /// Returns true when the parameter uses `this.field` syntax.
  bool isFieldInitializer(FormalParameter parameter) => parameter is FieldFormalParameter;
}
