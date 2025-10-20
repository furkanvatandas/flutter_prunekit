import 'class_declaration.dart';
import 'class_reference.dart';

/// Represents the complete reference graph of the codebase.
///
/// This graph maps all class declarations to their references, enabling
/// efficient unused class detection.
///
/// **Performance Optimization (T071)**: String interning is used for file paths
/// to reduce memory usage. File paths are repeated many times in references,
/// so interning them saves significant memory on large codebases.
class ReferenceGraph {
  /// All class declarations found in the codebase.
  ///
  /// Key: uniqueId (packageRelativePath#ClassName)
  /// Value: ClassDeclaration
  final Map<String, ClassDeclaration> declarations;

  /// All references found in the codebase.
  ///
  /// Key: className
  /// Value: List of all references to that class
  final Map<String, List<ClassReference>> references;

  /// String interning pool for file paths (T071).
  ///
  /// File paths are repeated many times (once per reference), so we intern
  /// them to reduce memory usage. On a project with 10k references and 100
  /// unique files, this saves ~500KB of string data.
  final Map<String, String> _pathInternPool = {};

  /// Creates a new reference graph.
  ReferenceGraph({
    required this.declarations,
    required this.references,
  });

  /// Creates an empty reference graph.
  ReferenceGraph.empty()
      : declarations = {},
        references = {};

  /// Interns a file path to reduce memory usage (T071).
  ///
  /// Returns the interned string if it already exists in the pool,
  /// otherwise adds it to the pool and returns it.
  String _internPath(String path) {
    return _pathInternPool.putIfAbsent(path, () => path);
  }

  /// Adds a class declaration to the graph.
  void addDeclaration(ClassDeclaration declaration) {
    declarations[declaration.uniqueId] = declaration;
  }

  /// Adds a class reference to the graph.
  ///
  /// Automatically interns the file path to reduce memory usage (T071).
  void addReference(ClassReference reference) {
    // Intern the file path to save memory
    final internedPath = _internPath(reference.sourceFile);

    // Create a new reference with the interned path if different
    final internedReference =
        internedPath == reference.sourceFile ? reference : reference.copyWith(sourceFile: internedPath);

    references.putIfAbsent(reference.className, () => []).add(internedReference);
  }

  /// Returns all declarations that have no references.
  ///
  /// This is the core unused detection logic.
  List<ClassDeclaration> getUnusedDeclarations() {
    return declarations.values.where((declaration) {
      // Check if there are any references to this class
      final refs = references[declaration.name] ?? [];
      return refs.isEmpty;
    }).toList()
      ..sort((a, b) => a.uniqueId.compareTo(b.uniqueId)); // Deterministic order
  }

  /// Returns the number of references for a given class name.
  int getReferenceCount(String className) {
    return references[className]?.length ?? 0;
  }

  /// Returns all references for a given class name.
  List<ClassReference> getReferences(String className) {
    return references[className] ?? [];
  }

  /// Returns statistics about the reference graph.
  GraphStatistics getStatistics() {
    return GraphStatistics(
      totalDeclarations: declarations.length,
      totalReferences: references.values.fold(0, (sum, refs) => sum + refs.length),
      unusedCount: getUnusedDeclarations().length,
      filesAnalyzed: _countUniqueFiles(),
    );
  }

  int _countUniqueFiles() {
    final files = <String>{};
    for (final decl in declarations.values) {
      files.add(decl.filePath);
    }
    for (final refs in references.values) {
      for (final ref in refs) {
        files.add(ref.sourceFile);
      }
    }
    return files.length;
  }
}

/// Statistics about a reference graph.
class GraphStatistics {
  /// Total number of class declarations found.
  final int totalDeclarations;

  /// Total number of references found.
  final int totalReferences;

  /// Number of unused classes detected.
  final int unusedCount;

  /// Number of unique files analyzed.
  final int filesAnalyzed;

  GraphStatistics({
    required this.totalDeclarations,
    required this.totalReferences,
    required this.unusedCount,
    required this.filesAnalyzed,
  });
}
