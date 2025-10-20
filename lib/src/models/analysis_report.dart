import 'class_declaration.dart';

/// The complete analysis report containing unused classes and metadata.
///
/// This is the top-level output structure for human-readable reports.
class AnalysisReport {
  /// The version of the analyzer that produced this report.
  final String version;

  /// Timestamp when the analysis was performed (ISO 8601 format).
  final String timestamp;

  /// List of unused class declarations.
  final List<ClassDeclaration> unusedClasses;

  /// Summary statistics and metrics.
  final AnalysisSummary summary;

  /// Warnings encountered during analysis (non-fatal issues).
  final List<AnalysisWarning> warnings;

  /// Creates a new analysis report.
  AnalysisReport({
    required this.version,
    required this.timestamp,
    required this.unusedClasses,
    required this.summary,
    required this.warnings,
  });

  /// Whether the analysis completed successfully without errors.
  bool get isSuccess => warnings.isEmpty || warnings.every((w) => !w.isFatal);

  /// Whether any unused classes were found.
  bool get hasUnusedClasses => unusedClasses.isNotEmpty;

  /// Determines the appropriate exit code based on the report.
  ///
  /// Per T0A1 contract:
  /// - 0: Success and no unused classes
  /// - 1: Unused classes detected
  /// - 2: Partial analysis with warnings
  int get exitCode {
    if (warnings.any((w) => w.isFatal)) {
      return 2; // Partial analysis
    }
    if (hasUnusedClasses) {
      return 1; // Unused found
    }
    return 0; // Clean
  }
}

/// Summary statistics for the analysis.
class AnalysisSummary {
  /// Total number of files analyzed.
  final int totalFiles;

  /// Total number of class declarations found.
  final int totalClasses;

  /// Number of unused classes detected.
  final int unusedCount;

  /// Number of files excluded by ignore patterns.
  final int excludedFiles;

  /// Number of files excluded as generated code.
  final int filesExcludedAsGenerated;

  /// Number of files excluded by ignore patterns from config/CLI.
  final int filesExcludedByIgnorePatterns;

  /// Number of classes excluded by annotations.
  final int excludedClasses;

  /// Number of classes explicitly ignored via @keepUnused annotation or config patterns.
  final int classesExplicitlyIgnored;

  /// Total analysis duration in milliseconds.
  final int durationMs;

  /// Precision rate (1 - false positive rate).
  ///
  /// Per T091, this should be ≥0.99 (99% precision target).
  final double? precisionRate;

  /// Recall rate (1 - false negative rate).
  ///
  /// Per T091, this should be ≥0.80 (80% recall target).
  final double? recallRate;

  /// Creates a new analysis summary.
  AnalysisSummary({
    required this.totalFiles,
    required this.totalClasses,
    required this.unusedCount,
    required this.excludedFiles,
    required this.excludedClasses,
    required this.durationMs,
    this.filesExcludedAsGenerated = 0,
    this.filesExcludedByIgnorePatterns = 0,
    this.classesExplicitlyIgnored = 0,
    this.precisionRate,
    this.recallRate,
  });

  /// Usage rate (percentage of classes that are used).
  double get usageRate => totalClasses > 0 ? (totalClasses - unusedCount) / totalClasses : 0.0;
}

/// A warning encountered during analysis.
class AnalysisWarning {
  /// The type of warning.
  final WarningType type;

  /// Human-readable warning message.
  final String message;

  /// File path where the warning occurred (if applicable).
  final String? filePath;

  /// Line number where the warning occurred (if applicable).
  final int? lineNumber;

  /// Whether this warning is fatal (prevents complete analysis).
  final bool isFatal;

  /// Creates a new analysis warning.
  AnalysisWarning({
    required this.type,
    required this.message,
    this.filePath,
    this.lineNumber,
    this.isFatal = false,
  });
}

/// Types of warnings that can occur during analysis.
enum WarningType {
  /// Syntax error in a Dart file (prevents AST parsing).
  syntaxError,

  /// Configuration file error (flutter_prunekit.yaml).
  configError,

  /// Invalid ignore pattern (glob syntax error).
  invalidPattern,

  /// File read error (permissions, missing file).
  fileReadError,

  /// Cache read/write error (non-fatal).
  cacheError,

  /// Performance warning (analysis exceeded time budget).
  performanceWarning,

  /// Part file's parent library could not be found.
  ///
  /// Occurs when a file has `part of 'parent.dart'` directive but
  /// parent.dart doesn't exist or is not in the expected location.
  partFileMissingParent,

  /// Part file has an invalid or malformed `part of` directive.
  ///
  /// Occurs when the `part of` syntax is incorrect or cannot be parsed.
  partFileInvalidDirective,

  /// Part file uses legacy library identifier that could not be resolved.
  ///
  /// Occurs when a file has `part of library.name` but the library
  /// with that name cannot be found in the workspace.
  partFileUnresolvedLibrary,
}
