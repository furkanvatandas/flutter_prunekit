import 'package:ansi_styles/ansi_styles.dart';
import '../models/analysis_report.dart';
import '../models/class_declaration.dart';

/// Formats analysis reports for different output modes.
class OutputFormatter {
  /// Formats the report based on the requested format.
  static String format(AnalysisReport report, {required bool quiet}) {
    return formatHuman(report, quiet: quiet);
  }

  /// Formats the report for human reading.
  static String formatHuman(AnalysisReport report, {required bool quiet}) {
    final buffer = StringBuffer();

    if (!quiet) {
      buffer.writeln(AnsiStyles.bold(AnsiStyles.cyan('═══ Flutter Dead Code Analysis ═══')));
      buffer.writeln();
    }

    if (report.unusedClasses.isEmpty) {
      buffer.writeln(AnsiStyles.green('✓ No unused classes found!'));
    } else {
      // Group classes by kind
      final groupedByKind = <ClassKind, List<ClassDeclaration>>{};
      for (final unusedClass in report.unusedClasses) {
        groupedByKind.putIfAbsent(unusedClass.kind, () => []).add(unusedClass);
      }

      // Summary header
      buffer.writeln(AnsiStyles.yellow('⚠ Found ${report.unusedClasses.length} unused declaration(s):'));
      buffer.writeln();

      // Show counts by kind
      final sortedKinds = groupedByKind.keys.toList()..sort((a, b) => a.name.compareTo(b.name));

      for (final kind in sortedKinds) {
        final items = groupedByKind[kind]!;
        final kindColor = _getKindColor(kind);

        buffer.writeln(kindColor('${_getKindLabel(kind)}: ${items.length}'));
        buffer.writeln();

        for (final unusedClass in items) {
          buffer.writeln('  ${AnsiStyles.gray('${unusedClass.filePath}:${unusedClass.lineNumber}')}');
          buffer.writeln('    ${AnsiStyles.white(unusedClass.name)}');
        }

        buffer.writeln();
      }
    }

    if (!quiet) {
      buffer.writeln(AnsiStyles.bold(AnsiStyles.cyan('─── Summary ───')));
      buffer.writeln();

      // Main statistics
      buffer
          .writeln('  ${AnsiStyles.bold('Files analyzed:')} ${AnsiStyles.white(report.summary.totalFiles.toString())}');
      buffer.writeln(
          '  ${AnsiStyles.bold('Total declarations:')} ${AnsiStyles.white(report.summary.totalClasses.toString())}');

      final unusedColor = report.summary.unusedCount > 0 ? AnsiStyles.yellow : AnsiStyles.green;
      buffer.writeln('  ${AnsiStyles.bold('Unused:')} ${unusedColor(report.summary.unusedCount.toString())}');

      final usageRate = (report.summary.usageRate * 100).toStringAsFixed(1);
      buffer.writeln('  ${AnsiStyles.bold('Usage rate:')} ${AnsiStyles.green('$usageRate%')}');

      // Show exclusion details if any files were excluded
      if (report.summary.filesExcludedAsGenerated > 0 || report.summary.filesExcludedByIgnorePatterns > 0) {
        buffer.writeln();
        buffer.writeln('  ${AnsiStyles.bold('Excluded files:')}');
        if (report.summary.filesExcludedAsGenerated > 0) {
          buffer.writeln('    ${AnsiStyles.gray('Generated code:')} ${report.summary.filesExcludedAsGenerated}');
        }
        if (report.summary.filesExcludedByIgnorePatterns > 0) {
          buffer.writeln('    ${AnsiStyles.gray('Ignore patterns:')} ${report.summary.filesExcludedByIgnorePatterns}');
        }
      }

      buffer.writeln();
      buffer.writeln('  ${AnsiStyles.bold('Analysis time:')} ${AnsiStyles.cyan('${report.summary.durationMs}ms')}');

      // Show precision/recall if available
      if (report.summary.precisionRate != null || report.summary.recallRate != null) {
        buffer.writeln();
        if (report.summary.precisionRate != null) {
          final precision = (report.summary.precisionRate! * 100).toStringAsFixed(1);
          final precisionColor = report.summary.precisionRate! >= 0.99 ? AnsiStyles.green : AnsiStyles.yellow;
          buffer.writeln('  ${AnsiStyles.bold('Precision:')} ${precisionColor('$precision%')}');
        }
        if (report.summary.recallRate != null) {
          final recall = (report.summary.recallRate! * 100).toStringAsFixed(1);
          final recallColor = report.summary.recallRate! >= 0.80 ? AnsiStyles.green : AnsiStyles.yellow;
          buffer.writeln('  ${AnsiStyles.bold('Recall:')} ${recallColor('$recall%')}');
        }
      }
    }

    // Show warnings if any
    if (report.warnings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(AnsiStyles.bold(AnsiStyles.yellow('─── Warnings ───')));
      buffer.writeln();

      for (final warning in report.warnings) {
        final icon = warning.isFatal ? '✗' : '⚠';
        final color = warning.isFatal ? AnsiStyles.red : AnsiStyles.yellow;

        buffer.writeln('  ${color('$icon ${warning.type.name}')}: ${warning.message}');
        if (warning.filePath != null) {
          buffer.write('    ${AnsiStyles.gray('at ${warning.filePath}')}');
          if (warning.lineNumber != null) {
            buffer.write(AnsiStyles.gray(':${warning.lineNumber}'));
          }
          buffer.writeln();
        }
      }
    }

    return buffer.toString();
  }

  /// Formats a compact single-line summary.
  static String formatCompact(AnalysisReport report) {
    if (report.unusedClasses.isEmpty) {
      return '✓ No unused classes';
    }
    return '✗ ${report.unusedClasses.length} unused class(es) found';
  }

  /// Returns a color function for the given class kind.
  static String Function(String) _getKindColor(ClassKind kind) {
    switch (kind) {
      case ClassKind.class_:
        return AnsiStyles.blue.call;
      case ClassKind.abstractClass:
        return AnsiStyles.blue.call;
      case ClassKind.enum_:
        return AnsiStyles.magenta.call;
      case ClassKind.mixin:
        return AnsiStyles.cyan.call;
      case ClassKind.extension:
        return AnsiStyles.green.call;
    }
  }

  /// Returns a human-readable label for the given class kind.
  static String _getKindLabel(ClassKind kind) {
    switch (kind) {
      case ClassKind.class_:
        return 'Classes';
      case ClassKind.abstractClass:
        return 'Abstract Classes';
      case ClassKind.enum_:
        return 'Enums';
      case ClassKind.mixin:
        return 'Mixins';
      case ClassKind.extension:
        return 'Extensions';
    }
  }
}
