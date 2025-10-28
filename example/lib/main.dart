import 'dart:io';

import 'package:flutter_prunekit/flutter_prunekit.dart';
import 'package:path/path.dart' as p;

/// Demonstrates how to run flutter_prunekit against a project.
///
/// Run with:
/// ```bash
/// dart run example
/// ```
/// With no arguments the bundled sample project is analyzed. You can pass a
/// target directory as the first argument to analyze your own project instead.
Future<void> main(List<String> args) async {
  final sampleProject = p.join(Directory.current.path, 'example', 'sample_project');
  final analyzeSample = args.isEmpty;
  final targetPath = analyzeSample ? sampleProject : args.first;
  final rootDirectory = Directory(targetPath).absolute;

  if (!rootDirectory.existsSync()) {
    stderr.writeln('Target directory does not exist: ${rootDirectory.path}');
    exitCode = 64;
    return;
  }

  if (analyzeSample) {
    stdout.writeln('Analyzing bundled sample project at: ${rootDirectory.path}');
  } else {
    stdout.writeln('Analyzing project at: ${rootDirectory.path}');
  }

  final scanner = FileScanner(rootPath: rootDirectory.path);
  final dartFiles = await scanner.scan();

  if (dartFiles.isEmpty) {
    stdout.writeln('No Dart files found under ${rootDirectory.path}. Nothing to analyze.');
    return;
  }

  final analyzerWrapper = DartAnalyzerWrapper(rootDirectory.path);
  final astAnalyzer = ASTAnalyzer(analyzerWrapper);
  final analysisResults = await astAnalyzer.analyzeFiles(dartFiles);

  final tracker = ReferenceTracker();
  final referenceGraph = await tracker.buildGraph(analysisResults);

  final detector = UnusedDetector();
  final unusedDeclarations = detector.findUnused(referenceGraph);
  final unusedMethods = detector.findUnusedMethods(referenceGraph);

  final warnings = [
    ...astAnalyzer.warnings,
    ...tracker.warnings,
  ];

  if (warnings.isNotEmpty) {
    stderr.writeln('\nWarnings during analysis:');
    for (final warning in warnings) {
      final location = _formatWarningLocation(warning);
      stderr.writeln('- ${warning.message}$location');
    }
  }

  if (unusedDeclarations.isEmpty && unusedMethods.isEmpty) {
    stdout.writeln('\nNo unused classes or methods detected across ${dartFiles.length} file(s).');
  } else {
    stdout.writeln('\nUnused declarations found:');
    for (final declaration in unusedDeclarations) {
      final relativePath = p.relative(declaration.filePath, from: rootDirectory.path);
      stdout.writeln('- ${declaration.name} ($relativePath:${declaration.lineNumber})');
    }

    if (unusedMethods.isNotEmpty) {
      stdout.writeln('\nUnused methods/functions:');
      for (final method in unusedMethods) {
        final relativePath = p.relative(method.filePath, from: rootDirectory.path);
        final scope = method.containingClass != null ? '${method.containingClass}.${method.name}' : method.name;
        stdout.writeln('- $scope ($relativePath:${method.lineNumber})');
      }
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
