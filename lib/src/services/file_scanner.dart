import 'dart:io';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import '../utils/generated_code_detector.dart';
import '../utils/path_utils.dart';
import 'analysis_options_reader.dart';

/// Discovers Dart files in a project directory.
///
/// Applies exclusion rules from analysis_options.yaml and ignores generated code.
class FileScanner {
  /// The root directory to scan.
  final String rootPath;

  /// Glob patterns to exclude from scanning.
  final List<String> excludePatterns;

  /// Whether to include test files in the scan.
  final bool includeTests;

  /// Whether to include generated files in the scan.
  final bool includeGenerated;

  /// Whether to ignore analysis_options.yaml exclusions.
  final bool ignoreAnalysisOptions;

  /// Cached analysis options loaded from analysis_options.yaml.
  AnalysisOptions? _analysisOptions;

  /// Whether analysis options have been loaded yet.
  bool _analysisOptionsLoaded = false;

  /// Creates a new file scanner.
  FileScanner({
    required this.rootPath,
    this.excludePatterns = const [],
    this.includeTests = false,
    this.includeGenerated = false,
    this.ignoreAnalysisOptions = false,
  });

  /// Scans for all Dart files matching the criteria.
  ///
  /// Returns absolute file paths.
  Future<List<String>> scan() async {
    // Load analysis_options.yaml if not already loaded
    await _loadAnalysisOptions();

    final results = <String>[];
    final rootDir = Directory(rootPath);

    if (!await rootDir.exists()) {
      throw FileSystemException('Root directory does not exist', rootPath);
    }

    // Default to lib/ directory if no patterns specified
    final searchPath = p.join(rootPath, 'lib');
    final searchDir = Directory(searchPath);

    if (!await searchDir.exists()) {
      // No lib/ directory - return empty
      return results;
    }

    // Recursively find all .dart files
    await for (final entity in searchDir.list(recursive: true)) {
      if (entity is File && PathUtils.isDartFile(entity.path)) {
        final normalizedPath = PathUtils.normalize(entity.path);

        // Check exclusions
        if (_shouldExclude(normalizedPath)) {
          continue;
        }

        // Check generated code (unless --include-generated is set)
        if (!includeGenerated && GeneratedCodeDetector.isGeneratedByPath(normalizedPath)) {
          continue;
        }

        // Check test files
        if (!includeTests && PathUtils.isTestFile(normalizedPath)) {
          continue;
        }

        results.add(normalizedPath);
      }
    }

    return results..sort(); // Deterministic order
  }

  /// Scans specific directories for Dart files.
  ///
  /// Used when custom paths are provided via CLI.
  Future<List<String>> scanDirectories(List<String> directories) async {
    // Load analysis_options.yaml if not already loaded
    await _loadAnalysisOptions();

    final results = <String>[];

    for (final dirPath in directories) {
      final dir = Directory(dirPath);

      if (!await dir.exists()) {
        continue; // Skip non-existent directories
      }

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && PathUtils.isDartFile(entity.path)) {
          final normalizedPath = PathUtils.normalize(entity.path);

          // Check generated code FIRST (--include-generated should override exclusions)
          final isGenerated = GeneratedCodeDetector.isGeneratedByPath(normalizedPath);

          if (!includeGenerated && isGenerated) {
            continue;
          }

          // Now check exclusions (but generated files already handled above)
          if (!isGenerated && _shouldExclude(normalizedPath)) {
            continue;
          }

          if (!includeTests && PathUtils.isTestFile(normalizedPath)) {
            continue;
          }

          results.add(normalizedPath);
        }
      }
    }

    return results..sort();
  }

  /// Checks if a file path should be excluded based on patterns.
  bool _shouldExclude(String filePath) {
    // Skip pattern matching if --ignore-analysis-options is set
    if (ignoreAnalysisOptions) {
      return false;
    }

    final packageRelative = PathUtils.toPackageRelative(filePath, rootPath);

    // Check user-provided patterns
    for (final pattern in excludePatterns) {
      final glob = Glob(pattern);
      if (glob.matches(packageRelative) || glob.matches(filePath)) {
        return true;
      }
    }

    // Check analysis_options.yaml patterns (already loaded by scan())
    if (_analysisOptions != null) {
      for (final pattern in _analysisOptions!.excludePatterns) {
        final glob = Glob(pattern);
        if (glob.matches(packageRelative) || glob.matches(filePath)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Loads exclude patterns from analysis_options.yaml if not already loaded.
  ///
  /// This is called automatically by scan() and scanDirectories().
  Future<void> _loadAnalysisOptions() async {
    // Skip if already loaded or if user wants to ignore analysis_options.yaml
    if (_analysisOptionsLoaded || ignoreAnalysisOptions) {
      return;
    }

    _analysisOptionsLoaded = true;

    try {
      _analysisOptions = await AnalysisOptionsReader.read(rootPath);
    } catch (e) {
      // Silently ignore errors - analysis_options.yaml is optional
      _analysisOptions = null;
    }
  }

  /// Gets statistics about the scan.
  Future<ScanStatistics> getStatistics() async {
    final allDartFiles = <String>[];
    final excludedFiles = <String>[];
    final generatedFiles = <String>[];
    final testFiles = <String>[];

    final searchPath = p.join(rootPath, 'lib');
    final searchDir = Directory(searchPath);

    if (!await searchDir.exists()) {
      return ScanStatistics(
        totalDartFiles: 0,
        includedFiles: 0,
        excludedByPattern: 0,
        excludedAsGenerated: 0,
        excludedAsTest: 0,
      );
    }

    await for (final entity in searchDir.list(recursive: true)) {
      if (entity is File && PathUtils.isDartFile(entity.path)) {
        final normalizedPath = PathUtils.normalize(entity.path);
        allDartFiles.add(normalizedPath);

        if (_shouldExclude(normalizedPath)) {
          excludedFiles.add(normalizedPath);
        } else if (GeneratedCodeDetector.isGeneratedByPath(normalizedPath)) {
          generatedFiles.add(normalizedPath);
        }
      }
    }

    // Count test files in test/ directory if it exists
    final testPath = p.join(rootPath, 'test');
    final testDir = Directory(testPath);
    if (await testDir.exists()) {
      await for (final entity in testDir.list(recursive: true)) {
        if (entity is File && PathUtils.isDartFile(entity.path)) {
          testFiles.add(PathUtils.normalize(entity.path));
        }
      }
    }

    final scannedFiles = await scan();

    return ScanStatistics(
      totalDartFiles: allDartFiles.length,
      includedFiles: scannedFiles.length,
      excludedByPattern: excludedFiles.length,
      excludedAsGenerated: generatedFiles.length,
      excludedAsTest: testFiles.length,
    );
  }
}

/// Statistics about a file scan operation.
class ScanStatistics {
  /// Total number of .dart files found.
  final int totalDartFiles;

  /// Number of files included in analysis.
  final int includedFiles;

  /// Number of files excluded by glob patterns.
  final int excludedByPattern;

  /// Number of files excluded as generated code.
  final int excludedAsGenerated;

  /// Number of files excluded as test files.
  final int excludedAsTest;

  ScanStatistics({
    required this.totalDartFiles,
    required this.includedFiles,
    required this.excludedByPattern,
    required this.excludedAsGenerated,
    required this.excludedAsTest,
  });
}
