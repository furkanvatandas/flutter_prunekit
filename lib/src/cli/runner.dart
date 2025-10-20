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
import '../models/ignore_pattern.dart';
import '../models/analysis_report.dart';
import '../utils/dart_analyzer_wrapper.dart';

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
  // Parse arguments
  final arguments = Arguments.parse(args);

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

    // Build reference graph
    final tracker = ReferenceTracker();
    final graph = tracker.buildGraph(fileResults);

    // Detect unused classes
    final detector = UnusedDetector(ignorePatterns: ignorePatterns);
    final unusedClasses = detector.findUnused(graph);

    // Get scanner statistics
    final scanStats = await scanner.getStatistics();

    // Get unused detection statistics
    final unusedStats = detector.getStatistics(graph);

    // Calculate duration
    final duration = DateTime.now().difference(startTime);

    // Collect all warnings from analysis
    final allWarnings = <AnalysisWarning>[
      ...astAnalyzer.warnings,
      ...tracker.warnings,
    ];

    // Create report
    final stats = graph.getStatistics();
    final report = AnalysisReport(
      version: '1.0.0',
      timestamp: DateTime.now().toIso8601String(),
      unusedClasses: unusedClasses,
      summary: AnalysisSummary(
        totalFiles: filesToAnalyze.length,
        totalClasses: stats.totalDeclarations,
        unusedCount: unusedClasses.length,
        excludedFiles: scanStats.excludedByPattern + scanStats.excludedAsGenerated,
        excludedClasses: stats.totalDeclarations - unusedClasses.length,
        filesExcludedAsGenerated: scanStats.excludedAsGenerated,
        filesExcludedByIgnorePatterns: scanStats.excludedByPattern,
        classesExplicitlyIgnored: unusedStats.ignoredByAnnotation + unusedStats.ignoredByPattern,
        durationMs: duration.inMilliseconds,
      ),
      warnings: allWarnings,
    );

    // Output report
    final output = OutputFormatter.format(
      report,
      quiet: arguments.quiet,
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
