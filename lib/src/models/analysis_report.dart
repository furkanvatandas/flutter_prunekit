import 'class_declaration.dart';
import 'method_declaration.dart';
import 'variable_declaration.dart';

/// The complete analysis report containing unused classes and metadata.
///
/// This is the top-level output structure for human-readable reports.
///
/// **Phase 2 Enhancement (T008)**: Extended to support method-level reporting
/// with nested structure (classes → methods, top-level functions).
class AnalysisReport {
  /// The version of the analyzer that produced this report.
  final String version;

  /// Timestamp when the analysis was performed (ISO 8601 format).
  final String timestamp;

  /// List of unused class declarations.
  final List<ClassDeclaration> unusedClasses;

  /// List of unused method/function declarations (T008).
  final List<MethodDeclaration> unusedMethods;

  /// List of unused variable declarations (US1).
  final List<VariableDeclaration> unusedVariables;

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
    List<MethodDeclaration>? unusedMethods,
    List<VariableDeclaration>? unusedVariables,
  })  : unusedMethods = unusedMethods ?? [],
        unusedVariables = unusedVariables ?? [];

  /// Whether the analysis completed successfully without errors.
  bool get isSuccess => warnings.isEmpty || warnings.every((w) => !w.isFatal);

  /// Whether any unused classes were found.
  bool get hasUnusedClasses => unusedClasses.isNotEmpty;

  /// Whether any unused methods were found (T008).
  bool get hasUnusedMethods => unusedMethods.isNotEmpty;

  /// Whether any unused variables were found (US1).
  bool get hasUnusedVariables => unusedVariables.isNotEmpty;

  /// Whether any unused code was found (classes or methods) (T008).
  bool get hasUnusedCode => hasUnusedClasses || hasUnusedMethods || hasUnusedVariables;

  /// Determines the appropriate exit code based on the report.
  ///
  /// Per T0A1 contract:
  /// - 0: Success and no unused code (classes or methods)
  /// - 1: Unused code detected (classes or methods)
  /// - 2: Partial analysis with warnings
  int get exitCode {
    if (warnings.any((w) => w.isFatal)) {
      return 2; // Partial analysis
    }
    if (hasUnusedCode) {
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

  /// Total number of method/function declarations found (T008).
  final int totalMethods;

  /// Number of unused methods detected (T008).
  final int unusedMethodCount;

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

  /// Number of methods excluded by annotations (T008).
  final int excludedMethods;

  /// Number of methods explicitly ignored via @keepUnused or lifecycle detection (T008).
  final int methodsExplicitlyIgnored;

  /// Total number of variables analyzed (US1).
  final int totalVariables;

  /// Number of unused variables detected (US1).
  final int unusedVariableCount;

  /// Total number of local variables analyzed (US1).
  final int totalLocalVariables;

  /// Number of unused local variables detected (US1).
  final int unusedLocalVariableCount;

  /// Total number of parameter variables analyzed (US2).
  final int totalParameterVariables;

  /// Number of unused parameter variables detected (US2).
  final int unusedParameterVariableCount;

  /// Total number of top-level variables analyzed (US3).
  final int totalTopLevelVariables;

  /// Number of unused top-level variables detected (US3).
  final int unusedTopLevelVariableCount;

  /// Total number of catch variables analyzed (US4).
  final int totalCatchVariables;

  /// Number of unused catch variables detected (US4).
  final int unusedCatchVariableCount;

  /// Number of variables explicitly ignored via annotations/comments (US5).
  final int variablesExplicitlyIgnored;

  /// Number of variables ignored due to underscore convention (US1).
  final int variablesIgnoredByConvention;

  /// Number of variables ignored by configuration patterns (US5).
  final int variablesIgnoredByPattern;

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
    this.totalMethods = 0,
    this.unusedMethodCount = 0,
    this.excludedMethods = 0,
    this.methodsExplicitlyIgnored = 0,
    this.filesExcludedAsGenerated = 0,
    this.filesExcludedByIgnorePatterns = 0,
    this.classesExplicitlyIgnored = 0,
    this.totalVariables = 0,
    this.unusedVariableCount = 0,
    this.totalLocalVariables = 0,
    this.unusedLocalVariableCount = 0,
    this.totalParameterVariables = 0,
    this.unusedParameterVariableCount = 0,
    this.totalTopLevelVariables = 0,
    this.unusedTopLevelVariableCount = 0,
    this.totalCatchVariables = 0,
    this.unusedCatchVariableCount = 0,
    this.variablesExplicitlyIgnored = 0,
    this.variablesIgnoredByConvention = 0,
    this.variablesIgnoredByPattern = 0,
    this.precisionRate,
    this.recallRate,
  });

  /// Usage rate (percentage of classes that are used).
  double get usageRate => totalClasses > 0 ? (totalClasses - unusedCount) / totalClasses : 0.0;

  /// Method usage rate (percentage of methods that are used) (T008).
  double get methodUsageRate => totalMethods > 0 ? (totalMethods - unusedMethodCount) / totalMethods : 0.0;

  /// Variable usage rate (percentage of variables that are used) (US1).
  double get variableUsageRate => totalVariables > 0 ? (totalVariables - unusedVariableCount) / totalVariables : 0.0;
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

  /// High percentage of dynamic method invocations detected (T092).
  ///
  /// Occurs when ≥5% of method calls have dynamic receiver types,
  /// which reduces static analysis precision and may hide unused code.
  highDynamicUsage,
}
