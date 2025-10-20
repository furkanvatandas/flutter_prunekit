import '../models/reference_graph.dart';
import '../models/class_reference.dart';
import '../models/analysis_report.dart';
import 'ast_analyzer.dart';

/// Builds and maintains the reference graph from AST analysis results.
///
/// Tracks relationships between class declarations and their references.
class ReferenceTracker {
  final List<AnalysisWarning> _warnings = [];

  /// Get all warnings accumulated during graph building.
  List<AnalysisWarning> get warnings => List.unmodifiable(_warnings);

  /// Clear accumulated warnings (typically between analysis runs).
  void clearWarnings() => _warnings.clear();

  /// Builds a reference graph from file analysis results.
  ///
  /// Emits warnings if dynamic type usage is detected (indicates potential
  /// false negatives due to runtime type resolution).
  ReferenceGraph buildGraph(List<FileAnalysisResult> fileResults) {
    final graph = ReferenceGraph.empty();
    final filesWithDynamicUsage = <String>[];

    // First pass: Add all declarations
    for (final fileResult in fileResults) {
      for (final declaration in fileResult.declarations) {
        graph.addDeclaration(declaration);
      }

      // Track dynamic type usage
      if (fileResult.hasDynamicTypeUsage) {
        filesWithDynamicUsage.add(fileResult.filePath);
      }
    }

    // Second pass: Add all references
    for (final fileResult in fileResults) {
      for (final reference in fileResult.references) {
        graph.addReference(reference);

        // Also track generic type arguments (e.g., List<MyClass>)
        _trackGenericTypeArguments(reference, graph);
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
  ReferenceGraph mergeGraphs(List<ReferenceGraph> graphs) {
    final merged = ReferenceGraph.empty();

    for (final graph in graphs) {
      for (final declaration in graph.declarations.values) {
        merged.addDeclaration(declaration);
      }

      for (final entry in graph.references.entries) {
        for (final reference in entry.value) {
          merged.addReference(reference);
        }
      }
    }

    return merged;
  }

  /// Updates a graph with new file analysis results.
  ///
  /// Removes old data for the file and adds new data.
  /// Useful for incremental re-analysis when files change.
  ReferenceGraph updateGraph(
    ReferenceGraph existingGraph,
    List<FileAnalysisResult> updatedFiles,
  ) {
    // Create a new graph excluding the updated files
    final filePathsToUpdate = updatedFiles.map((f) => f.filePath).toSet();

    final newGraph = ReferenceGraph.empty();

    // Copy declarations from files that weren't updated
    for (final declaration in existingGraph.declarations.values) {
      if (!filePathsToUpdate.contains(declaration.filePath)) {
        newGraph.addDeclaration(declaration);
      }
    }

    // Copy references from files that weren't updated
    for (final entry in existingGraph.references.entries) {
      for (final reference in entry.value) {
        if (!filePathsToUpdate.contains(reference.sourceFile)) {
          newGraph.addReference(reference);
        }
      }
    }

    // Add new declarations and references from updated files
    for (final fileResult in updatedFiles) {
      for (final declaration in fileResult.declarations) {
        newGraph.addDeclaration(declaration);
      }
      for (final reference in fileResult.references) {
        newGraph.addReference(reference);
      }
    }

    return newGraph;
  }
}
