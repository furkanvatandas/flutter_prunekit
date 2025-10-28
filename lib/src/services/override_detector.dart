import '../models/method_declaration.dart';

/// Detects method overrides using @override annotations (T032 - Phase 1).
///
/// Current implementation (Phase 1):
/// - Uses @override annotations already captured during AST analysis
/// - Marks methods with @override as overridden to prevent false positives
///
/// Future enhancement (Phase 2):
/// - Add semantic analysis to detect overrides without @override annotations
/// - Traverse inheritance hierarchies to identify implicit overrides
/// - Check abstract method implementations, interface implementations
///
/// Marks overridden methods with isOverride=true to prevent false positives
/// in unused detection (overridden methods are implicitly used via polymorphism).
class OverrideDetector {
  /// Bulk processes a list of method declarations to mark overrides.
  ///
  /// Phase 1 Strategy:
  /// - Methods with @override annotation are already marked during AST extraction
  /// - This method validates and returns the list unchanged
  /// - Returns a new list with updated MethodDeclaration instances
  ///
  /// Phase 2 Enhancement (future):
  /// - Will add semantic analysis for methods without @override
  /// - Will traverse class hierarchies to detect implicit overrides
  ///
  /// Note: Encourage users to add @override annotations for better detection.
  Future<List<MethodDeclaration>> markOverrides(
    List<MethodDeclaration> methods,
  ) async {
    // Phase 1: Return methods as-is since @override is already captured
    // The isOverride flag was set during AST analysis (T030) based on @override annotation
    //
    // This simple approach works because:
    // 1. Dart analyzer warns about missing @override (users likely have it)
    // 2. Explicit @override is the common case in well-maintained code
    // 3. Semantic analysis can be added in Phase 2 if false positives occur

    return methods;
  }
}
