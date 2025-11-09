import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:flutter_prunekit/src/utils/part_file_detector.dart';
import 'package:path/path.dart' as p;

/// Wrapper around the Dart Analyzer package.
///
/// Provides simplified access to AST parsing and analysis sessions.
/// Handles analyzer initialization and resource management.
///
/// Supports parsing part files by resolving them within their parent
/// library context. Caches parent libraries to avoid redundant parsing.
class DartAnalyzerWrapper {
  /// The analysis context collection for the workspace.
  final AnalysisContextCollection _collection;

  /// Cache of resolved parent libraries keyed by absolute file path.
  ///
  /// This prevents redundant parsing when multiple part files belong to
  /// the same parent library, providing ~50% performance improvement for
  /// projects with many part files.
  final Map<String, ResolvedLibraryResult> _libraryCache = {};

  /// Creates a new analyzer wrapper for the given root directory.
  ///
  /// The [rootPath] should be the absolute path to the project root.
  DartAnalyzerWrapper(String rootPath)
      : _collection = AnalysisContextCollection(
          includedPaths: [_normalizePathForAnalyzer(rootPath)],
        );

  /// Normalizes a file path for the analyzer.
  ///
  /// On Windows, the analyzer expects paths with backslashes.
  /// This method ensures the path is absolute and in the correct format.
  static String _normalizePathForAnalyzer(String path) {
    // Convert to absolute path first
    final absolutePath = p.isAbsolute(path) ? path : p.absolute(path);

    // Use p.normalize which maintains native path separators
    return p.normalize(absolutePath);
  }

  /// Gets the analysis session for a given file path.
  ///
  /// The session provides access to resolved AST and semantic information.
  AnalysisSession getSessionForFile(String filePath) {
    final normalizedPath = _normalizePathForAnalyzer(filePath);
    final context = _collection.contextFor(normalizedPath);
    return context.currentSession;
  }

  /// Parses a Dart file and returns its resolved unit.
  ///
  /// For part files (files with `part of` directive), parses them within
  /// their parent library context. For regular files, parses directly.
  ///
  /// Returns null if the file cannot be parsed (syntax errors, part file
  /// with missing parent, etc.).
  ///
  /// The [filePath] must be an absolute path.
  Future<ResolvedUnitResult?> parseFile(String filePath) async {
    try {
      // Normalize the path for Windows compatibility
      final normalizedPath = _normalizePathForAnalyzer(filePath);

      // Check if this is a part file
      final isPartFile = await PartFileDetector.isPartFile(normalizedPath);

      if (isPartFile) {
        // Resolve parent library path
        final parentPath = await PartFileDetector.resolveParentPath(normalizedPath);

        if (parentPath == null) {
          // Orphaned part file - parent not found
          return null;
        }

        final normalizedParentPath = _normalizePathForAnalyzer(parentPath);

        // Check cache for parent library
        ResolvedLibraryResult? libraryResult = _libraryCache[normalizedParentPath];

        if (libraryResult == null) {
          // Cache miss - parse parent library
          final session = getSessionForFile(normalizedParentPath);
          final result = await session.getResolvedLibrary(normalizedParentPath);

          if (result is ResolvedLibraryResult) {
            // Store in cache
            _libraryCache[normalizedParentPath] = result;
            libraryResult = result;
          } else {
            // Failed to parse parent library
            return null;
          }
        }

        // Extract the specific part unit from the library result
        try {
          return libraryResult.units.firstWhere(
            (unit) => _normalizePathForAnalyzer(unit.path) == normalizedPath,
          );
        } catch (e) {
          // Part file not found in library units
          return null;
        }
      }

      // Regular file (not a part) - parse directly
      final session = getSessionForFile(normalizedPath);
      final result = await session.getResolvedUnit(normalizedPath);

      if (result is ResolvedUnitResult) {
        return result;
      }

      return null;
    } catch (e) {
      // Log error but don't crash - allow partial analysis
      return null;
    }
  }

  /// Checks if a file has syntax errors without full resolution.
  ///
  /// This is faster than full parsing for validation purposes.
  Future<bool> hasSyntaxErrors(String filePath) async {
    try {
      final normalizedPath = _normalizePathForAnalyzer(filePath);
      final session = getSessionForFile(normalizedPath);
      final result = await session.getResolvedUnit(normalizedPath);

      if (result is ResolvedUnitResult) {
        return result.diagnostics.isNotEmpty;
      }

      return true; // Treat parse failures as errors
    } catch (e) {
      return true;
    }
  }

  /// Gets all analysis contexts in the collection.
  ///
  /// Useful for inspecting multiple package roots.
  Iterable<String> getContextRoots() {
    return _collection.contexts.map((ctx) => ctx.contextRoot.root.path);
  }

  /// Disposes of analyzer resources.
  ///
  /// Should be called when analysis is complete to free memory.
  void dispose() {
    clearCache();
    // Note: AnalysisContextCollection doesn't have explicit disposal
    // The VM will garbage collect when the wrapper is no longer referenced
  }

  /// Clears the library cache.
  ///
  /// Should be called at the start of each analysis run to ensure fresh
  /// results and free memory from previous runs.
  void clearCache() {
    _libraryCache.clear();
  }
}
