import '../models/reference_graph.dart';
import '../models/class_declaration.dart' as model;
import '../models/ignore_pattern.dart';

/// Detects unused classes in a reference graph.
///
/// Applies ignore patterns and filters to determine which classes are truly unused.
class UnusedDetector {
  /// List of ignore patterns to apply.
  final List<IgnorePattern> ignorePatterns;

  UnusedDetector({this.ignorePatterns = const []});

  /// Finds all unused classes in the graph.
  ///
  /// Returns classes that have zero incoming references and are not ignored.
  /// Results are sorted by uniqueId for deterministic output.
  List<model.ClassDeclaration> findUnused(ReferenceGraph graph) {
    final unused = graph.getUnusedDeclarations();

    // Filter out ignored classes
    final filtered = unused.where((declaration) {
      return !_shouldIgnore(declaration);
    }).toList();

    // Already sorted in ReferenceGraph.getUnusedDeclarations()
    return filtered;
  }

  /// Checks if a class declaration should be ignored.
  ///
  /// Applies ignore pattern priority per T0A3:
  /// 1. @keepUnused annotation (highest priority)
  /// 2. flutter_prunekit.yaml config patterns
  /// 3. --exclude CLI flag patterns
  bool _shouldIgnore(model.ClassDeclaration declaration) {
    // Check annotation-based ignoring (highest priority)
    if (declaration.hasIgnoreAnnotation) {
      return true;
    }

    // Check ignore patterns by priority
    final matchingPatterns = ignorePatterns.where((pattern) => pattern.matches(declaration.filePath)).toList();

    if (matchingPatterns.isEmpty) {
      return false;
    }

    // Sort by priority (highest first) and return true if any match
    matchingPatterns.sort((a, b) => b.priority.compareTo(a.priority));
    return true;
  }

  /// Gets statistics about unused detection.
  UnusedStatistics getStatistics(ReferenceGraph graph) {
    final allUnused = graph.getUnusedDeclarations();
    final filteredUnused = findUnused(graph);

    return UnusedStatistics(
      totalClasses: graph.declarations.length,
      unusedBeforeFiltering: allUnused.length,
      unusedAfterFiltering: filteredUnused.length,
      ignoredByAnnotation: allUnused.where((d) => d.hasIgnoreAnnotation).length,
      ignoredByPattern: allUnused.length - filteredUnused.length - allUnused.where((d) => d.hasIgnoreAnnotation).length,
    );
  }
}

/// Statistics about unused class detection.
class UnusedStatistics {
  /// Total number of class declarations in the graph.
  final int totalClasses;

  /// Number of unused classes before applying ignore filters.
  final int unusedBeforeFiltering;

  /// Number of unused classes after applying ignore filters.
  final int unusedAfterFiltering;

  /// Number of classes ignored by @keepUnused annotation.
  final int ignoredByAnnotation;

  /// Number of classes ignored by glob patterns.
  final int ignoredByPattern;

  UnusedStatistics({
    required this.totalClasses,
    required this.unusedBeforeFiltering,
    required this.unusedAfterFiltering,
    required this.ignoredByAnnotation,
    required this.ignoredByPattern,
  });
}
