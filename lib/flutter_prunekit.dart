/// Flutter Dead Code Analyzer
///
/// A static analysis tool for detecting unused classes in Dart and Flutter projects.
///
/// ## Usage
///
/// ```dart
/// import 'package:flutter_prunekit/flutter_prunekit.dart';
///
/// void main() async {
///   final analyzer = DeadCodeAnalyzer();
///   final report = await analyzer.analyze('/path/to/project');
///
///   print('Found ${report.unusedClasses.length} unused classes');
/// }
/// ```
library;

// Core models
export 'src/models/class_declaration.dart';
export 'src/models/class_reference.dart';
export 'src/models/reference_graph.dart';
export 'src/models/analysis_report.dart';
export 'src/models/ignore_pattern.dart';

// Services
export 'src/services/file_scanner.dart';
export 'src/services/ast_analyzer.dart';
export 'src/services/reference_tracker.dart';
export 'src/services/unused_detector.dart';
export 'src/services/analysis_options_reader.dart';
export 'src/services/analyzer_config_reader.dart';

// CLI components (for programmatic usage)
export 'src/cli/arguments.dart';
export 'src/cli/output_formatter.dart';
export 'src/cli/runner.dart';

// Utilities
export 'src/utils/dart_analyzer_wrapper.dart';
export 'src/utils/generated_code_detector.dart';
export 'src/utils/path_utils.dart';
