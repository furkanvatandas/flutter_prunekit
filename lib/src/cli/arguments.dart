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

  /// Whether to analyze only functions and methods.
  final bool onlyMethods;

  /// Whether to analyze only classes, enums, mixins, and extensions.
  final bool onlyTypes;

  /// Whether to analyze only variables and parameters.
  final bool onlyVariables;

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
    required this.onlyTypes,
    required this.onlyMethods,
    required this.onlyVariables,
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
        onlyTypes: results.flag('only-types'),
        onlyMethods: results.flag('only-methods'),
        onlyVariables: results.flag('only-variables'),
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
        help: 'Analyze only functions and methods',
      )
      ..addFlag(
        'only-types',
        negatable: false,
        help: 'Analyze only classes, enums, mixins, and extensions',
      )
      ..addFlag(
        'only-variables',
        negatable: false,
        help: 'Analyze only variables and parameters',
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

Usage: flutter_prunekit unused_code [options]

Options:
${parser.usage}

Exit Codes:
  0 - Success, no unused code found
  1 - Unused declarations detected
  2 - Partial analysis completed with warnings

Examples:
  flutter_prunekit unused_code
  flutter_prunekit unused_code --path lib --path test
  flutter_prunekit unused_code --exclude 'lib/legacy/**'
  flutter_prunekit unused_code --only-types
  flutter_prunekit unused_code --only-methods
  flutter_prunekit unused_code --only-variables
''';
  }

  /// Gets the version string.
  static String getVersion() {
    return 'flutter_dead_code version 2.4.0';
  }
}
