import 'dart:io';

import 'package:flutter_prunekit/flutter_prunekit.dart';
import 'package:path/path.dart' as p;

/// Runs a dead code analysis against a Dart/Flutter project.
///
/// Usage:
/// ```bash
/// dart run example/basic_usage.dart /path/to/project
/// ```
/// If no path argument is supplied, the current working directory is analyzed.
Future<void> main(List<String> args) async {
  final sampleProjectPath = p.join(Directory.current.path, 'example', 'sample_project');
  final usingBundledSample = args.isEmpty;
  final target = usingBundledSample ? sampleProjectPath : args.first;
  final rootDirectory = Directory(target).absolute;

  if (!rootDirectory.existsSync()) {
    stderr.writeln('Target directory does not exist: ${rootDirectory.path}');
    exitCode = 64;
    return;
  }

  if (usingBundledSample) {
    print('No path supplied. Using bundled sample project at '
        '${rootDirectory.path}');
  }

  final scanner = FileScanner(rootPath: rootDirectory.path);
  final dartFiles = await scanner.scan();

  if (dartFiles.isEmpty) {
    final libDir = p.join(rootDirectory.path, 'lib');
    print('No Dart files found under $libDir. Nothing to analyze.');
    return;
  }

  final analyzerWrapper = DartAnalyzerWrapper(rootDirectory.path);
  final astAnalyzer = ASTAnalyzer(analyzerWrapper);
  final analysisResults = await astAnalyzer.analyzeFiles(dartFiles);

  final tracker = ReferenceTracker();
  final referenceGraph = await tracker.buildGraph(analysisResults);

  final detector = UnusedDetector();
  final unusedDeclarations = detector.findUnused(referenceGraph);

  final warnings = [
    ...astAnalyzer.warnings,
    ...tracker.warnings,
  ];

  if (warnings.isNotEmpty) {
    stderr.writeln('Warnings during analysis:');
    for (final warning in warnings) {
      final location = _formatWarningLocation(warning);
      stderr.writeln('- ${warning.message}$location');
    }
  }

  if (unusedDeclarations.isEmpty) {
    print('No unused classes detected across ${dartFiles.length} file(s).');
  } else {
    print('Found ${unusedDeclarations.length} unused declaration(s):');
    for (final declaration in unusedDeclarations) {
      final relativePath = p.relative(declaration.filePath, from: rootDirectory.path);
      print('- ${declaration.name} ($relativePath:${declaration.lineNumber})');
    }
  }

  analyzerWrapper.dispose();
}

String _formatWarningLocation(AnalysisWarning warning) {
  if (warning.filePath == null) {
    return '';
  }

  final buffer = StringBuffer(' (');
  buffer.write(warning.filePath);
  if (warning.lineNumber != null) {
    buffer.write(':${warning.lineNumber}');
  }
  buffer.write(')');
  return buffer.toString();
}
