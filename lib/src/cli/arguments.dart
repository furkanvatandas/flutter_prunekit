import 'package:args/args.dart';

/// Parses command-line arguments for the flutter_prunekit tool.
class Arguments {
  /// The root path(s) to analyze.
  final List<String> paths;

  /// Glob patterns to exclude from analysis.
  final List<String> excludePatterns;

  /// Whether to include test files in analysis.
  final bool includeTests;

  /// Whether to include generated files in analysis.
  final bool includeGenerated;

  /// Whether to ignore analysis_options.yaml exclusions.
  final bool ignoreAnalysisOptions;

  /// Whether to suppress all output except errors.
  final bool quiet;

  /// Whether to show verbose output.
  final bool verbose;

  /// Whether to show help.
  final bool help;

  /// Whether to show version.
  final bool version;

  /// Whether to analyze only methods (not classes).
  final bool onlyMethods;

  /// Whether to output the report in JSON format.
  final bool json;

  /// Creates the parsed representation of CLI flags for `flutter_prunekit`.
  Arguments({
    required this.paths,
    required this.excludePatterns,
    required this.includeTests,
    required this.includeGenerated,
    required this.ignoreAnalysisOptions,
    required this.quiet,
    required this.verbose,
    required this.help,
    required this.version,
    required this.onlyMethods,
    required this.json,
  });

  /// Parses command-line arguments.
  ///
  /// Returns null if parsing fails.
  static Arguments? parse(List<String> args) {
    final parser = _buildParser();

    try {
      final results = parser.parse(args);

      // Extract paths from both --path flag and positional arguments
      final pathsFromFlag = results.multiOption('path');
      final positionalArgs = results.rest;

      // Combine paths: positional arguments take precedence, then --path flag, then default to 'lib'
      final List<String> finalPaths;
      if (positionalArgs.isNotEmpty) {
        finalPaths = positionalArgs;
      } else if (pathsFromFlag.isNotEmpty) {
        finalPaths = pathsFromFlag;
      } else {
        finalPaths = ['lib'];
      }

      return Arguments(
        paths: finalPaths,
        excludePatterns: results.multiOption('exclude'),
        includeTests: results.flag('include-tests'),
        includeGenerated: results.flag('include-generated'),
        ignoreAnalysisOptions: results.flag('ignore-analysis-options'),
        quiet: results.flag('quiet'),
        verbose: results.flag('verbose'),
        help: results.flag('help'),
        version: results.flag('version'),
        onlyMethods: results.flag('only-methods'),
        json: results.flag('json'),
      );
    } on FormatException {
      return null;
    }
  }

  /// Builds the argument parser.
  static ArgParser _buildParser() {
    return ArgParser()
      ..addMultiOption(
        'path',
        abbr: 'p',
        help: 'Path(s) to analyze (defaults to lib/)',
        valueHelp: 'path',
      )
      ..addMultiOption(
        'exclude',
        abbr: 'e',
        help: 'Glob pattern(s) to exclude from analysis',
        valueHelp: 'pattern',
      )
      ..addFlag(
        'include-tests',
        negatable: false,
        help: 'Include test files in analysis',
      )
      ..addFlag(
        'include-generated',
        negatable: false,
        help: 'Include generated files (*.g.dart, *.freezed.dart, etc.) in analysis',
      )
      ..addFlag(
        'ignore-analysis-options',
        negatable: false,
        help: 'Ignore exclusion rules from analysis_options.yaml',
      )
      ..addFlag(
        'quiet',
        abbr: 'q',
        negatable: false,
        help: 'Suppress all output except report and errors',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        negatable: false,
        help: 'Show verbose output',
      )
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Show this help message',
      )
      ..addFlag(
        'version',
        negatable: false,
        help: 'Show version information',
      )
      ..addFlag(
        'only-methods',
        negatable: false,
        help: 'Analyze only methods/functions (not classes)',
      )
      ..addFlag(
        'json',
        negatable: false,
        help: 'Output report in JSON format',
      );
  }

  /// Gets the usage/help text.
  static String getUsage() {
    final parser = _buildParser();
    return '''
Detect unused Dart and Flutter classes, methods, and variables in your codebase.

Usage: flutter_prunekit [options]

Options:
${parser.usage}

Exit Codes:
  0 - Success, no unused code found
  1 - Unused declarations detected
  2 - Partial analysis completed with warnings

Examples:
  flutter_prunekit
  flutter_prunekit --path lib --path test
  flutter_prunekit --exclude 'lib/legacy/**'
''';
  }

  /// Gets the version string.
  static String getVersion() {
    return 'flutter_prunekit version 2.1.0';
  }
}
