import 'dart:convert';
import 'package:ansi_styles/ansi_styles.dart';
import '../models/analysis_report.dart';
import '../models/class_declaration.dart';
import '../models/method_declaration.dart';

/// Formats analysis reports for different output modes.
class OutputFormatter {
  /// Formats the report based on the requested format.
  static String format(
    AnalysisReport report, {
    required bool quiet,
    bool onlyMethods = false,
    bool asJson = false,
  }) {
    if (asJson) {
      return formatJson(
        report,
        onlyMethods: onlyMethods,
      );
    }
    return formatHuman(report, quiet: quiet, onlyMethods: onlyMethods);
  }

  /// Formats the report for human reading.
  static String formatHuman(AnalysisReport report, {required bool quiet, bool onlyMethods = false}) {
    final buffer = StringBuffer();

    if (!quiet) {
      buffer.writeln(AnsiStyles.bold(AnsiStyles.cyan('═══ Flutter Dead Code Analysis ═══')));
      buffer.writeln();
    }

    // Skip class output if --only-methods
    if (!onlyMethods && report.unusedClasses.isEmpty) {
      buffer.writeln(AnsiStyles.green('✓ No unused classes found!'));
    } else if (!onlyMethods) {
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

    if (report.unusedMethods.isNotEmpty) {
      // Group methods by type and class
      final instanceMethodsByClass = <String, List<MethodDeclaration>>{};
      final staticMethodsByClass = <String, List<MethodDeclaration>>{};
      final extensionMethodsByExtension = <String, List<MethodDeclaration>>{};
      final topLevelMethods = <MethodDeclaration>[];

      for (final method in report.unusedMethods) {
        if (method.methodType == MethodType.topLevel) {
          topLevelMethods.add(method);
        } else if (method.methodType == MethodType.extension) {
          // Extension methods (T055 - Phase 6)
          if (method.containingClass != null) {
            extensionMethodsByExtension.putIfAbsent(method.containingClass!, () => []).add(method);
          }
        } else if (method.isStatic || method.methodType == MethodType.static) {
          // Static methods, static getters, static setters (T045 - Phase 5)
          if (method.containingClass != null) {
            staticMethodsByClass.putIfAbsent(method.containingClass!, () => []).add(method);
          }
        } else if (method.containingClass != null) {
          // Instance methods, instance getters, instance setters, operators
          instanceMethodsByClass.putIfAbsent(method.containingClass!, () => []).add(method);
        }
      }

      buffer.writeln(AnsiStyles.yellow('⚠ Found ${report.unusedMethods.length} unused method(s):'));
      buffer.writeln();

      if (staticMethodsByClass.isNotEmpty) {
        final totalStatic = staticMethodsByClass.values.fold(0, (sum, list) => sum + list.length);
        buffer.writeln(AnsiStyles.magenta('Static Methods: $totalStatic'));
        buffer.writeln();

        final sortedClasses = staticMethodsByClass.keys.toList()..sort();
        for (final className in sortedClasses) {
          final methods = staticMethodsByClass[className]!;
          buffer.writeln('  ${AnsiStyles.cyan(className)}:');

          for (final method in methods) {
            buffer.writeln('    ${AnsiStyles.gray('${method.filePath}:${method.lineNumber}')}');
            final methodName =
                method.visibility == Visibility.private ? AnsiStyles.dim(method.name) : AnsiStyles.white(method.name);

            // Add type indicator for getters/setters
            final typeIndicator = method.methodType == MethodType.getter
                ? ' (getter)'
                : method.methodType == MethodType.setter
                    ? ' (setter)'
                    : '';
            buffer.writeln('      $methodName$typeIndicator');
          }
          buffer.writeln();
        }
      }

      // Show instance methods grouped by class
      if (instanceMethodsByClass.isNotEmpty) {
        final totalInstance = instanceMethodsByClass.values.fold(0, (sum, list) => sum + list.length);
        buffer.writeln(AnsiStyles.magenta('Instance Methods: $totalInstance'));
        buffer.writeln();

        final sortedClasses = instanceMethodsByClass.keys.toList()..sort();
        for (final className in sortedClasses) {
          final methods = instanceMethodsByClass[className]!;
          buffer.writeln('  ${AnsiStyles.cyan(className)}:');

          for (final method in methods) {
            buffer.writeln('    ${AnsiStyles.gray('${method.filePath}:${method.lineNumber}')}');
            final methodName =
                method.visibility == Visibility.private ? AnsiStyles.dim(method.name) : AnsiStyles.white(method.name);

            // Add type indicator for getters/setters/operators
            final typeIndicator = method.methodType == MethodType.getter
                ? ' (getter)'
                : method.methodType == MethodType.setter
                    ? ' (setter)'
                    : method.methodType == MethodType.operator
                        ? ' (operator)'
                        : '';
            buffer.writeln('      $methodName$typeIndicator');
          }
          buffer.writeln();
        }
      }

      // Show extension methods grouped by extension (T055 - Phase 6)
      if (extensionMethodsByExtension.isNotEmpty) {
        final totalExtension = extensionMethodsByExtension.values.fold(0, (sum, list) => sum + list.length);
        buffer.writeln(AnsiStyles.magenta('Extension Methods: $totalExtension'));
        buffer.writeln();

        final sortedExtensions = extensionMethodsByExtension.keys.toList()..sort();
        for (final extensionName in sortedExtensions) {
          final methods = extensionMethodsByExtension[extensionName]!;
          buffer.writeln('  ${AnsiStyles.cyan(extensionName)}:');

          for (final method in methods) {
            buffer.writeln('    ${AnsiStyles.gray('${method.filePath}:${method.lineNumber}')}');
            final methodName =
                method.visibility == Visibility.private ? AnsiStyles.dim(method.name) : AnsiStyles.white(method.name);

            // Add type indicator for getters/setters/operators in extensions
            final typeIndicator = method.isGetter
                ? ' (getter)'
                : method.isSetter
                    ? ' (setter)'
                    : method.isOperator
                        ? ' (operator)'
                        : '';
            buffer.writeln('      $methodName$typeIndicator');
          }
          buffer.writeln();
        }
      }

      // Show top-level functions
      if (topLevelMethods.isNotEmpty) {
        buffer.writeln(AnsiStyles.magenta('Top-Level Functions: ${topLevelMethods.length}'));
        buffer.writeln();

        for (final method in topLevelMethods) {
          buffer.writeln('  ${AnsiStyles.gray('${method.filePath}:${method.lineNumber}')}');
          buffer.writeln('    ${AnsiStyles.white(method.name)}');
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

      // Show method statistics if methods were analyzed (T035)
      if (report.summary.totalMethods > 0) {
        buffer.writeln();
        buffer.writeln(
            '  ${AnsiStyles.bold('Methods analyzed:')} ${AnsiStyles.white(report.summary.totalMethods.toString())}');

        final methodUnusedColor = report.summary.unusedMethodCount > 0 ? AnsiStyles.yellow : AnsiStyles.green;
        buffer.writeln(
            '  ${AnsiStyles.bold('Unused methods:')} ${methodUnusedColor(report.summary.unusedMethodCount.toString())}');

        final methodUsageRate = (report.summary.methodUsageRate * 100).toStringAsFixed(1);
        buffer.writeln('  ${AnsiStyles.bold('Method usage rate:')} ${AnsiStyles.green('$methodUsageRate%')}');
      }

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

  /// Formats the report as JSON.
  static String formatJson(AnalysisReport report, {bool onlyMethods = false}) {
    final map = <String, dynamic>{
      'version': report.version,
      'timestamp': report.timestamp,
      'exitCode': report.exitCode,
      'unusedClasses':
          onlyMethods ? <Map<String, dynamic>>[] : report.unusedClasses.map(_classDeclarationToJson).toList(),
      'unusedMethods': report.unusedMethods.map(_methodDeclarationToJson).toList(),
      'summary': _summaryToJson(report.summary),
      'warnings': report.warnings.map(_warningToJson).toList(),
    };

    return jsonEncode(map);
  }

  /// Formats a compact single-line summary.
  static String formatCompact(AnalysisReport report) {
    final parts = <String>[];

    if (report.unusedClasses.isEmpty) {
      parts.add('✓ No unused classes');
    } else {
      parts.add('✗ ${report.unusedClasses.length} unused class declaration(s)');
    }

    if (report.unusedMethods.isNotEmpty) {
      parts.add('${report.unusedMethods.length} unused method(s)');
    }

    return parts.join(', ');
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

  static Map<String, dynamic> _classDeclarationToJson(ClassDeclaration declaration) {
    return {
      'className': declaration.name,
      'name': declaration.name,
      'filePath': declaration.filePath,
      'lineNumber': declaration.lineNumber,
      'kind': declaration.kind.name,
      'isPrivate': declaration.isPrivate,
      'annotations': declaration.annotations,
    };
  }

  static Map<String, dynamic> _methodDeclarationToJson(MethodDeclaration declaration) {
    return {
      'methodName': declaration.name,
      'name': declaration.name,
      'className': declaration.containingClass,
      'filePath': declaration.filePath,
      'lineNumber': declaration.lineNumber,
      'methodType': declaration.methodType.name,
      'visibility': declaration.visibility.name,
      'annotations': declaration.annotations,
      'isOverride': declaration.isOverride,
      'isAbstract': declaration.isAbstract,
      'isStatic': declaration.isStatic,
      'isLifecycleMethod': declaration.isLifecycleMethod,
      'isGetter': declaration.isGetter,
      'isSetter': declaration.isSetter,
      'isOperator': declaration.isOperator,
      'extensionTargetType': declaration.extensionTargetType,
    };
  }

  static Map<String, dynamic> _summaryToJson(AnalysisSummary summary) {
    final data = <String, dynamic>{
      'totalFiles': summary.totalFiles,
      'totalClasses': summary.totalClasses,
      'unusedCount': summary.unusedCount,
      'unusedClasses': summary.unusedCount,
      'totalMethods': summary.totalMethods,
      'unusedMethodCount': summary.unusedMethodCount,
      'unusedMethods': summary.unusedMethodCount,
      'filesExcluded': summary.excludedFiles,
      'filesExcludedAsGenerated': summary.filesExcludedAsGenerated,
      'filesExcludedByIgnorePatterns': summary.filesExcludedByIgnorePatterns,
      'excludedClasses': summary.excludedClasses,
      'classesExplicitlyIgnored': summary.classesExplicitlyIgnored,
      'excludedMethods': summary.excludedMethods,
      'methodsExplicitlyIgnored': summary.methodsExplicitlyIgnored,
      'durationMs': summary.durationMs,
      'usageRate': summary.usageRate,
      'methodUsageRate': summary.methodUsageRate,
    };

    if (summary.precisionRate != null) {
      data['precisionRate'] = summary.precisionRate;
    }
    if (summary.recallRate != null) {
      data['recallRate'] = summary.recallRate;
    }

    return data;
  }

  static Map<String, dynamic> _warningToJson(AnalysisWarning warning) {
    return {
      'type': warning.type.name,
      'message': warning.message,
      'filePath': warning.filePath,
      'lineNumber': warning.lineNumber,
      'isFatal': warning.isFatal,
    };
  }
}
