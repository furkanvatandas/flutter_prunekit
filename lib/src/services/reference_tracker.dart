import '../models/reference_graph.dart';
import '../models/class_reference.dart';
import '../models/analysis_report.dart';
import 'ast_analyzer.dart';
import 'override_detector.dart';

/// Builds and maintains the reference graph from AST analysis results.
///
/// Tracks relationships between class declarations and their references.
///
/// **T033**: Integrated OverrideDetector to mark method overrides during graph building.
class ReferenceTracker {
  final List<AnalysisWarning> _warnings = [];
  final OverrideDetector _overrideDetector = OverrideDetector();

  /// Get all warnings accumulated during graph building.
  List<AnalysisWarning> get warnings => List.unmodifiable(_warnings);

  /// Clear accumulated warnings (typically between analysis runs).
  void clearWarnings() => _warnings.clear();

  /// Builds a reference graph from file analysis results.
  ///
  /// Emits warnings if dynamic type usage is detected (indicates potential
  /// false negatives due to runtime type resolution).
  ///
  /// **T019**: Extended to track method-level declarations and invocations.
  /// **T033**: Integrated OverrideDetector to mark method overrides.
  Future<ReferenceGraph> buildGraph(List<FileAnalysisResult> fileResults) async {
    final graph = ReferenceGraph.empty();
    final filesWithDynamicUsage = <String>[];

    // First pass: Add all declarations (classes and methods)
    for (final fileResult in fileResults) {
      // Add class declarations
      for (final declaration in fileResult.declarations) {
        graph.addDeclaration(declaration);
      }

      // Track dynamic type usage
      if (fileResult.hasDynamicTypeUsage) {
        filesWithDynamicUsage.add(fileResult.filePath);
      }
    }

    // Collect all method declarations for override detection (T033)
    final allMethodDeclarations = <dynamic>[];
    for (final fileResult in fileResults) {
      allMethodDeclarations.addAll(fileResult.methodDeclarations);
    }

    // Mark overrides using OverrideDetector (T033)
    final markedMethods = await _overrideDetector.markOverrides(
      allMethodDeclarations.cast(),
    );

    // Add method declarations with override flags set (T033)
    for (final methodDeclaration in markedMethods) {
      graph.addMethodDeclaration(methodDeclaration);
    }

    // Second pass: Add all references (classes and method invocations)
    for (final fileResult in fileResults) {
      // Add class references
      for (final reference in fileResult.references) {
        graph.addReference(reference);

        // Also track generic type arguments (e.g., List<MyClass>)
        _trackGenericTypeArguments(reference, graph);
      }

      // Add method invocations (T019)
      for (final invocation in fileResult.methodInvocations) {
        graph.addMethodInvocation(invocation);
      }
    }

    // Emit warnings for dynamic type usage
    if (filesWithDynamicUsage.isNotEmpty) {
      _warnings.add(AnalysisWarning(
        type: WarningType.performanceWarning,
        message: 'Dynamic type usage detected in ${filesWithDynamicUsage.length} file(s). '
            'Classes may be referenced via runtime type resolution that cannot be statically tracked. '
            'Results may have false negatives.',
        isFatal: false,
      ));
    }

    return graph;
  }

  /// Extracts and tracks class references from generic type arguments.
  ///
  /// For example, in `List<MyClass>`, this extracts `MyClass` as a reference.
  /// Handles nested generics like `Map<String, List<MyClass>>`.
  void _trackGenericTypeArguments(
    ClassReference reference,
    ReferenceGraph graph,
  ) {
    // This is a placeholder for generic type tracking
    // The actual implementation would need to parse type argument strings
    // from the AST, which requires additional visitor logic

    // For now, the basic reference tracking in visitNamedType
    // will capture most type arguments since they appear as NamedType nodes
  }

  /// Merges multiple reference graphs into one.
  ///
  /// Useful for incremental analysis where partial graphs are combined.
  ///
  /// **T019**: Extended to merge method-level data.
  ReferenceGraph mergeGraphs(List<ReferenceGraph> graphs) {
    final merged = ReferenceGraph.empty();

    for (final graph in graphs) {
      // Merge class declarations
      for (final declaration in graph.declarations.values) {
        merged.addDeclaration(declaration);
      }

      // Merge class references
      for (final entry in graph.references.entries) {
        for (final reference in entry.value) {
          merged.addReference(reference);
        }
      }

      // Merge method declarations (T019)
      for (final methodDecl in graph.methodDeclarations.values) {
        merged.addMethodDeclaration(methodDecl);
      }

      // Merge method invocations (T019)
      for (final entry in graph.methodInvocations.entries) {
        for (final invocation in entry.value) {
          merged.addMethodInvocation(invocation);
        }
      }
    }

    return merged;
  }

  /// Updates a graph with new file analysis results.
  ///
  /// Removes old data for the file and adds new data.
  /// Useful for incremental re-analysis when files change.
  ///
  /// **T019**: Extended to update method-level data.
  /// **T033**: Integrated OverrideDetector for updated methods.
  Future<ReferenceGraph> updateGraph(
    ReferenceGraph existingGraph,
    List<FileAnalysisResult> updatedFiles,
  ) async {
    // Create a new graph excluding the updated files
    final filePathsToUpdate = updatedFiles.map((f) => f.filePath).toSet();

    final newGraph = ReferenceGraph.empty();

    // Copy class declarations from files that weren't updated
    for (final declaration in existingGraph.declarations.values) {
      if (!filePathsToUpdate.contains(declaration.filePath)) {
        newGraph.addDeclaration(declaration);
      }
    }

    // Copy class references from files that weren't updated
    for (final entry in existingGraph.references.entries) {
      for (final reference in entry.value) {
        if (!filePathsToUpdate.contains(reference.sourceFile)) {
          newGraph.addReference(reference);
        }
      }
    }

    // Copy method declarations from files that weren't updated (T019)
    for (final methodDecl in existingGraph.methodDeclarations.values) {
      if (!filePathsToUpdate.contains(methodDecl.filePath)) {
        newGraph.addMethodDeclaration(methodDecl);
      }
    }

    // Copy method invocations from files that weren't updated (T019)
    for (final entry in existingGraph.methodInvocations.entries) {
      for (final invocation in entry.value) {
        if (!filePathsToUpdate.contains(invocation.filePath)) {
          newGraph.addMethodInvocation(invocation);
        }
      }
    }

    // Collect method declarations from updated files for override detection (T033)
    final updatedMethodDeclarations = <dynamic>[];
    for (final fileResult in updatedFiles) {
      updatedMethodDeclarations.addAll(fileResult.methodDeclarations);
    }

    // Mark overrides using OverrideDetector (T033)
    final markedUpdatedMethods = await _overrideDetector.markOverrides(
      updatedMethodDeclarations.cast(),
    );

    // Add new declarations and references from updated files
    for (final fileResult in updatedFiles) {
      // Add class declarations
      for (final declaration in fileResult.declarations) {
        newGraph.addDeclaration(declaration);
      }
      // Add class references
      for (final reference in fileResult.references) {
        newGraph.addReference(reference);
      }
      // Add method invocations (T019)
      for (final invocation in fileResult.methodInvocations) {
        newGraph.addMethodInvocation(invocation);
      }
    }

    // Add method declarations with override flags (T033)
    for (final methodDecl in markedUpdatedMethods) {
      newGraph.addMethodDeclaration(methodDecl);
    }

    return newGraph;
  }
}
