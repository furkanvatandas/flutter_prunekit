import 'package:analyzer/dart/element/element.dart';
import '../models/field_declaration.dart';

/// Distinguishes fields from variables using semantic resolution.
///
/// Fields are declared at class/mixin/enum level, while variables are
/// declared within function/method bodies or as parameters. This classifier
/// uses the Dart Analyzer's semantic model to make this distinction.
class FieldClassifier {
  const FieldClassifier();

  /// Checks if an element is a field (class/mixin/enum member).
  ///
  /// Returns true if the element is a FieldElement with a ClassElement,
  /// MixinElement, or EnumElement as its enclosing element.
  bool isField(Element? element) {
    if (element is! FieldElement) {
      return false;
    }

    final enclosing = element.enclosingElement;
    return enclosing is ClassElement ||
        enclosing is MixinElement ||
        enclosing is EnumElement ||
        enclosing is ExtensionTypeElement;
  }

  /// Checks if an element is a variable (local, parameter, or top-level).
  ///
  /// Returns true if the element is a LocalVariableElement or TopLevelVariableElement.
  /// Parameters are also considered variables but are represented differently.
  bool isVariable(Element? element) {
    return element is LocalVariableElement ||
        element is TopLevelVariableElement ||
        (element != null && element.kind == ElementKind.PARAMETER);
  }

  /// Gets the declaring type kind for a field element.
  ///
  /// Returns the type of context (class, mixin, enum, extension type) that
  /// declares this field.
  FieldDeclaringTypeKind getDeclaringTypeKind(FieldElement element) {
    final enclosing = element.enclosingElement;

    if (enclosing is ClassElement) {
      return FieldDeclaringTypeKind.classType;
    } else if (enclosing is MixinElement) {
      return FieldDeclaringTypeKind.mixin;
    } else if (enclosing is EnumElement) {
      return FieldDeclaringTypeKind.enum_;
    } else if (enclosing is ExtensionTypeElement) {
      return FieldDeclaringTypeKind.extensionType;
    }

    // Fallback to class type
    return FieldDeclaringTypeKind.classType;
  }

  /// Gets the declaring type name for a field element.
  ///
  /// Returns the name of the class/mixin/enum that declares this field.
  String? getDeclaringTypeName(FieldElement element) {
    final enclosing = element.enclosingElement;

    if (enclosing is InterfaceElement) {
      return enclosing.name;
    }

    return null;
  }

  /// Checks if a field is static (class-level).
  bool isStaticField(FieldElement element) {
    return element.isStatic;
  }

  /// Checks if a field is instance-level.
  bool isInstanceField(FieldElement element) {
    return !element.isStatic;
  }

  /// Checks if a field is an enum instance field (enhanced enums, Dart 2.17+).
  bool isEnumInstanceField(FieldElement element) {
    final enclosing = element.enclosingElement;
    return enclosing is EnumElement && !element.isStatic;
  }

  /// Checks if a field is an extension type representation field (Dart 3.3+).
  bool isExtensionTypeRepresentation(FieldElement element) {
    final enclosing = element.enclosingElement;
    if (enclosing is! ExtensionTypeElement) {
      return false;
    }

    // Representation field is the field used to store the underlying value
    // In Dart 3.3+, this is the field declared in the representation clause
    // For now, we check if it's the only field or marked specially
    // TODO: Improve this check with actual representation detection
    return enclosing.fields.length == 1 && enclosing.fields.first == element;
  }
}
