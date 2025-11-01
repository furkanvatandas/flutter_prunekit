import 'dart:io';
import 'package:path/path.dart' as p;
import '../cli/arguments.dart';
import '../cli/output_formatter.dart';
import '../services/file_scanner.dart';
import '../services/ast_analyzer.dart';
import '../services/reference_tracker.dart';
import '../services/unused_detector.dart';
import '../services/analysis_options_reader.dart';
import '../services/analyzer_config_reader.dart';
import '../models/class_declaration.dart';
import '../models/ignore_pattern.dart';
import '../models/ignore_configuration.dart';
import '../models/analysis_report.dart';
import '../models/method_declaration.dart';
import '../models/variable_types.dart';
import '../models/variable_declaration.dart';
import '../utils/dart_analyzer_wrapper.dart';

String _getGlobalUsage() => '''
Usage: flutter_prunekit <command>

Available commands:
  unused_code    Detect unused Dart and Flutter code.

Run "flutter_prunekit unused_code --help" for more information.
'''
    .trimRight();

/// Finds the project root by walking up the directory tree to find pubspec.yaml.
///
/// This is needed when analyzing a subdirectory path (e.g., lib/feature/auth)
/// to ensure the analyzer has the correct context.
Future<String?> _findProjectRoot(String startPath) async {
  var currentPath = startPath;

  for (var i = 0; i < 10; i++) {
    final pubspecFile = File(p.join(currentPath, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      return currentPath;
    }

    final parentPath = p.dirname(currentPath);
    if (parentPath == currentPath) break; // Reached filesystem root

    currentPath = parentPath;
  }

  return null;
}

/// Main entry point for the flutter_prunekit CLI tool.
Future<int> run(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Error: No command provided.');
    stderr.writeln(_getGlobalUsage());
    return 2; // Partial/error
  }

  final command = args.first;

  if (command == '--help' || command == '-h') {
    print(_getGlobalUsage());
    return 0;
  }

  if (command == '--version') {
    print(Arguments.getVersion());
    return 0;
  }

  if (command != 'unused_code') {
    stderr.writeln('Error: Unknown command "$command".');
    stderr.writeln(_getGlobalUsage());
    return 2; // Partial/error
  }

  final commandArgs = args.sublist(1);

  // Parse arguments
  final arguments = Arguments.parse(commandArgs);

  if (arguments == null) {
    stderr.writeln('Error: Invalid arguments');
    stderr.writeln(Arguments.getUsage());
    return 2; // Partial/error
  }

  // Handle --help
  if (arguments.help) {
    print(Arguments.getUsage());
    return 0;
  }

  // Handle --version
  if (arguments.version) {
    print(Arguments.getVersion());
    return 0;
  }

  try {
    final startTime = DateTime.now();

    final hasCategoryFilter = arguments.onlyTypes || arguments.onlyMethods || arguments.onlyVariables;
    final includeTypes = !hasCategoryFilter || arguments.onlyTypes;
    final includeMethods = !hasCategoryFilter || arguments.onlyMethods;
    final includeVariables = !hasCategoryFilter || arguments.onlyVariables;

    // Determine project root and scan paths
    String projectRoot = Directory.current.path;
    List<String> scanPaths = arguments.paths;

    if (arguments.paths.length == 1) {
      final singlePath = arguments.paths.first;
      final absolutePath = singlePath.startsWith('/') ? singlePath : p.join(Directory.current.path, singlePath);

      final dir = Directory(absolutePath);
      final libDir = Directory(p.join(absolutePath, 'lib'));

      if (await dir.exists() && await libDir.exists()) {
        // Path is a project root with lib/ directory
        projectRoot = absolutePath;
        scanPaths = ['lib'];
      } else if (await dir.exists()) {
        // Path is a subdirectory - find project root for analyzer context
        projectRoot = await _findProjectRoot(absolutePath) ?? Directory.current.path;
        scanPaths = [absolutePath];
      }
    }

    if (!arguments.quiet && arguments.verbose) {
      print('Analyzing project at: $projectRoot');
    }

    // Read analysis_options.yaml for exclude patterns
    final analysisOptions = await AnalysisOptionsReader.read(projectRoot);

    // Read flutter_prunekit.yaml for custom ignore patterns (T045-T046)
    final analyzerConfig = await AnalyzerConfigReader.read(projectRoot);

    // T092: Load ignore configuration for variables/parameters
    final ignoreConfig = await IgnoreConfiguration.load(projectRoot);

    final excludePatterns = <String>[
      ...?analysisOptions?.excludePatterns,
      // Add patterns from flutter_prunekit.yaml (T046)
      ...?analyzerConfig?.excludePatterns.map((p) => p.pattern),
      ...arguments.excludePatterns,
    ];

    // Create ignore patterns with proper priority
    final ignorePatterns = <IgnorePattern>[
      // Config file patterns (priority 2)
      ...?analyzerConfig?.excludePatterns,
      // T065: Add method-level ignore patterns from config
      ...?analyzerConfig?.ignoreMethodPatterns,
      // CLI flag patterns (priority 1 - lowest)
      ...arguments.excludePatterns.map((pattern) => IgnorePattern(
            pattern: pattern,
            source: IgnoreSource.cliFlag,
          )),
    ];

    // Scan for Dart files
    final scanner = FileScanner(
      rootPath: projectRoot,
      excludePatterns: excludePatterns,
      includeTests: arguments.includeTests,
      includeGenerated: arguments.includeGenerated,
      ignoreAnalysisOptions: arguments.ignoreAnalysisOptions,
    );

    // Use scan() for default lib/ or scanDirectories() for custom paths
    final filesToAnalyze = scanPaths.contains('lib') ? await scanner.scan() : await scanner.scanDirectories(scanPaths);

    if (!arguments.quiet && arguments.verbose) {
      print('Found ${filesToAnalyze.length} files to analyze');
    }

    if (filesToAnalyze.isEmpty) {
      if (!arguments.quiet) {
        print('No Dart files found to analyze');
      }
      return 0; // No files = success
    }

    // Initialize analyzer
    final analyzerWrapper = DartAnalyzerWrapper(projectRoot);
    final astAnalyzer = ASTAnalyzer(analyzerWrapper);

    // Analyze files
    final fileResults = await astAnalyzer.analyzeFiles(filesToAnalyze);

    if (!arguments.quiet && arguments.verbose) {
      print('Successfully analyzed ${fileResults.length} files');
    }

    // Build reference graph (T033: now includes override detection)
    final tracker = ReferenceTracker();
    final graph = await tracker.buildGraph(fileResults);

    // Detect unused classes and methods with shared detector
    final detector = UnusedDetector(
      ignorePatterns: ignorePatterns,
      ignoreConfiguration: ignoreConfig, // T092: Pass ignore configuration
      verbose: arguments.verbose && !arguments.quiet, // T066: Pass verbose flag
    );

    // T066: Print verbose diagnostic header (only once)
    if (!arguments.quiet && arguments.verbose) {
      print('\n─── Ignore Pattern Diagnostics ───');
    }

    final List<ClassDeclaration> unusedClasses = includeTypes ? detector.findUnused(graph) : <ClassDeclaration>[];
    final List<MethodDeclaration> unusedMethods =
        includeMethods ? detector.findUnusedMethods(graph) : <MethodDeclaration>[];
    final List<VariableDeclaration> unusedVariables =
        includeVariables ? detector.detectUnusedVariables(graph) : <VariableDeclaration>[];

    if (!arguments.quiet && arguments.verbose) {
      print('─────────────────────────────────\n');
    }

    // Get scanner statistics
    final scanStats = await scanner.getStatistics();

    // Get unused detection statistics (T066: pass cached results to avoid re-running verbose logging)
    final unusedStats = detector.getStatisticsWithCachedResults(
      graph,
      unusedClasses,
      unusedMethods,
      unusedVariables: unusedVariables,
    );

    // Calculate duration
    final duration = DateTime.now().difference(startTime);

    // Get statistics (T092: needed for dynamic warning check)
    final stats = graph.getStatistics();

    // Variable totals by type
    final totalVariables = includeVariables ? graph.variableDeclarations.values.length : 0;
    var totalLocalVariables = 0;
    var totalParameterVariables = 0;
    var totalTopLevelVariables = 0;
    var totalCatchVariables = 0;

    if (includeVariables) {
      for (final declaration in graph.variableDeclarations.values) {
        switch (declaration.variableType) {
          case VariableType.local:
            totalLocalVariables++;
            break;
          case VariableType.parameter:
            totalParameterVariables++;
            break;
          case VariableType.topLevel:
            totalTopLevelVariables++;
            break;
          case VariableType.catchClause:
            totalCatchVariables++;
            break;
        }
      }
    }

    var unusedLocalVariables = 0;
    var unusedParameterVariables = 0;
    var unusedTopLevelVariables = 0;
    var unusedCatchVariables = 0;

    if (includeVariables) {
      for (final declaration in unusedVariables) {
        switch (declaration.variableType) {
          case VariableType.local:
            unusedLocalVariables++;
            break;
          case VariableType.parameter:
            unusedParameterVariables++;
            break;
          case VariableType.topLevel:
            unusedTopLevelVariables++;
            break;
          case VariableType.catchClause:
            unusedCatchVariables++;
            break;
        }
      }
    }

    // Collect all warnings from analysis
    final allWarnings = <AnalysisWarning>[
      ...astAnalyzer.warnings,
      ...tracker.warnings,
    ];

    // T092: Add dynamic invocation warning if threshold exceeded
    if (stats.hasDynamicWarning) {
      allWarnings.add(
        AnalysisWarning(
          type: WarningType.highDynamicUsage,
          message: 'High dynamic method invocation rate detected: '
              '${stats.dynamicInvocationPercentage.toStringAsFixed(1)}% '
              '(${stats.dynamicInvocationCount}/${stats.totalMethodInvocations} calls). '
              'Consider adding type annotations to improve static analysis precision and reduce false negatives.',
          isFatal: false,
        ),
      );
    }

    // Create report (T035: includes unused methods)
    final report = AnalysisReport(
      version: '1.0.0',
      timestamp: DateTime.now().toIso8601String(),
      unusedClasses: unusedClasses,
      unusedMethods: unusedMethods, // T035: Add method reporting
      unusedVariables: unusedVariables,
      summary: AnalysisSummary(
        totalFiles: filesToAnalyze.length,
        totalClasses: includeTypes ? stats.totalDeclarations : 0,
        unusedCount: includeTypes ? unusedClasses.length : 0,
        excludedFiles: scanStats.excludedByPattern + scanStats.excludedAsGenerated,
        excludedClasses: includeTypes ? stats.totalDeclarations - unusedClasses.length : 0,
        filesExcludedAsGenerated: scanStats.excludedAsGenerated,
        filesExcludedByIgnorePatterns: scanStats.excludedByPattern,
        classesExplicitlyIgnored: includeTypes ? unusedStats.ignoredByAnnotation + unusedStats.ignoredByPattern : 0,
        durationMs: duration.inMilliseconds,
        totalMethods: includeMethods ? graph.methodDeclarations.length : 0, // T035
        unusedMethodCount: includeMethods ? unusedMethods.length : 0, // T035
        totalVariables: totalVariables,
        unusedVariableCount: unusedVariables.length,
        totalLocalVariables: totalLocalVariables,
        unusedLocalVariableCount: unusedLocalVariables,
        totalParameterVariables: totalParameterVariables,
        unusedParameterVariableCount: unusedParameterVariables,
        totalTopLevelVariables: totalTopLevelVariables,
        unusedTopLevelVariableCount: unusedTopLevelVariables,
        totalCatchVariables: totalCatchVariables,
        unusedCatchVariableCount: unusedCatchVariables,
        variablesExplicitlyIgnored: includeVariables ? unusedStats.variablesIgnoredByExplicitIgnore : 0,
        variablesIgnoredByConvention: includeVariables ? unusedStats.variablesIgnoredByConvention : 0,
        variablesIgnoredByPattern: includeVariables ? unusedStats.variablesIgnoredByPattern : 0,
      ),
      warnings: allWarnings,
    );

    // Output report
    final output = OutputFormatter.format(
      report,
      quiet: arguments.quiet,
      includeTypes: includeTypes,
      includeMethods: includeMethods,
      includeVariables: includeVariables,
      asJson: arguments.json,
    );
    print(output);

    // Return exit code per T0A1 contract
    return report.exitCode;
  } catch (e, stackTrace) {
    stderr.writeln('Error during analysis: $e');
    if (arguments.verbose) {
      stderr.writeln(stackTrace);
    }
    return 2; // Partial analysis/error
  }
}
