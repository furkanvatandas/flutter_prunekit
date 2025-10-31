import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Collects simple identifiers that appear inside string interpolation literals.
class StringInterpolationTracker {
  const StringInterpolationTracker();

  /// Returns every [SimpleIdentifier] referenced within the provided
  /// [StringInterpolation] node. The same identifier instance can appear
  /// multiple times when nested interpolations are present.
  List<SimpleIdentifier> collectIdentifiers(StringInterpolation interpolation) {
    final visitor = _InterpolationIdentifierVisitor();
    interpolation.accept(visitor);
    return visitor.identifiers;
  }
}

class _InterpolationIdentifierVisitor extends RecursiveAstVisitor<void> {
  final List<SimpleIdentifier> identifiers = [];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!node.inDeclarationContext()) {
      identifiers.add(node);
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    node.expression.accept(this);
  }
}
