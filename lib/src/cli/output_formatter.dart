import 'dart:convert';
import 'package:ansi_styles/ansi_styles.dart';
import '../models/analysis_report.dart';
import '../models/class_declaration.dart';
import '../models/method_declaration.dart';
import '../models/variable_declaration.dart';
import '../models/variable_types.dart';

/// Formats analysis reports for different output modes.
class OutputFormatter {
  /// Formats the report based on the requested format.
  static String format(
    AnalysisReport report, {
    required bool quiet,
    bool includeTypes = true,
    bool includeMethods = true,
    bool includeVariables = true,
    bool asJson = false,
  }) {
    if (asJson) {
      return formatJson(
        report,
        includeTypes: includeTypes,
        includeMethods: includeMethods,
        includeVariables: includeVariables,
      );
    }
    return formatHuman(
      report,
      quiet: quiet,
      includeTypes: includeTypes,
      includeMethods: includeMethods,
      includeVariables: includeVariables,
    );
  }

  /// Formats the report for human reading.
  static String formatHuman(
    AnalysisReport report, {
    required bool quiet,
    bool includeTypes = true,
    bool includeMethods = true,
    bool includeVariables = true,
  }) {
    final buffer = StringBuffer();

    if (!quiet) {
      buffer.writeln(AnsiStyles.bold(AnsiStyles.cyan('═══ Flutter Dead Code Analysis ═══')));
      buffer.writeln();
    }

    if (includeTypes) {
      if (report.unusedClasses.isEmpty) {
        buffer.writeln(AnsiStyles.green('✓ No unused classes found!'));
      } else {
        // Group classes by kind
        final groupedByKind = <ClassKind, List<ClassDeclaration>>{};
        for (final unusedClass in report.unusedClasses) {
          groupedByKind.putIfAbsent(unusedClass.kind, () => []).add(unusedClass);
        }

        // Summary header
        final classLabel = report.unusedClasses.length == 1 ? 'declaration' : 'declarations';
        buffer.writeln(
          AnsiStyles.yellow('⚠ Found ${report.unusedClasses.length} unused class $classLabel:'),
        );
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
    }

    // Show unused methods (T035, T045 - Phase 5: static method support, T055 - Phase 6: extension method support)
    if (includeMethods && report.unusedMethods.isNotEmpty) {
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

      final methodLabel = report.unusedMethods.length == 1 ? 'method' : 'methods';
      buffer.writeln(AnsiStyles.yellow('⚠ Found ${report.unusedMethods.length} unused $methodLabel:'));
      buffer.writeln();

      // Show static methods grouped by class (T045 - Phase 5)
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

    // Show unused variables (US1)
    if (includeVariables && report.unusedVariables.isNotEmpty) {
      buffer.writeln(AnsiStyles.yellow('⚠ Found ${report.unusedVariables.length} unused variable(s):'));
      buffer.writeln();

      final grouped = <VariableType, List<VariableDeclaration>>{};
      for (final variable in report.unusedVariables) {
        grouped.putIfAbsent(variable.variableType, () => []).add(variable);
      }

      for (final type in _variableTypePriorityOrder) {
        final variables = grouped[type];
        if (variables == null || variables.isEmpty) {
          continue;
        }

        variables.sort((a, b) {
          final pathCompare = a.filePath.compareTo(b.filePath);
          if (pathCompare != 0) return pathCompare;
          final lineCompare = a.lineNumber.compareTo(b.lineNumber);
          if (lineCompare != 0) return lineCompare;
          final columnCompare = a.columnNumber.compareTo(b.columnNumber);
          if (columnCompare != 0) return columnCompare;
          return a.name.compareTo(b.name);
        });

        buffer.writeln(AnsiStyles.magenta('${_getVariableTypeLabel(type)}: ${variables.length}'));
        buffer.writeln();

        for (final variable in variables) {
          final location = '${variable.filePath}:${variable.lineNumber}:${variable.columnNumber}';
          buffer.writeln('  ${AnsiStyles.gray(location)}');
          buffer.writeln('    ${AnsiStyles.white(variable.name)}');
        }

        buffer.writeln();
      }
    }

    if (!quiet) {
      buffer.writeln(AnsiStyles.bold(AnsiStyles.cyan('─── Summary ───')));
      buffer.writeln();

      // Main statistics
      buffer.writeln(
        '  ${AnsiStyles.bold('Files analyzed:')} ${AnsiStyles.white(report.summary.totalFiles.toString())}',
      );

      if (includeTypes) {
        buffer.writeln(
          '  ${AnsiStyles.bold('Type declarations analyzed:')} ${AnsiStyles.white(report.summary.totalClasses.toString())}',
        );

        final unusedColor = report.summary.unusedCount > 0 ? AnsiStyles.yellow : AnsiStyles.green;
        buffer.writeln(
          '  ${AnsiStyles.bold('Unused type declarations:')} ${unusedColor(report.summary.unusedCount.toString())}',
        );

        final usageRate = (report.summary.usageRate * 100).toStringAsFixed(1);
        buffer.writeln('  ${AnsiStyles.bold('Type usage rate:')} ${AnsiStyles.green('$usageRate%')}');
      }

      // Show method statistics if methods were analyzed (T035)
      if (includeMethods && report.summary.totalMethods > 0) {
        buffer.writeln();
        buffer.writeln(
            '  ${AnsiStyles.bold('Methods analyzed:')} ${AnsiStyles.white(report.summary.totalMethods.toString())}');

        final methodUnusedColor = report.summary.unusedMethodCount > 0 ? AnsiStyles.yellow : AnsiStyles.green;
        buffer.writeln(
            '  ${AnsiStyles.bold('Unused methods:')} ${methodUnusedColor(report.summary.unusedMethodCount.toString())}');

        final methodUsageRate = (report.summary.methodUsageRate * 100).toStringAsFixed(1);
        buffer.writeln('  ${AnsiStyles.bold('Method usage rate:')} ${AnsiStyles.green('$methodUsageRate%')}');
      }

      if (includeVariables && report.summary.totalVariables > 0) {
        buffer.writeln();
        buffer.writeln(
            '  ${AnsiStyles.bold('Variables analyzed:')} ${AnsiStyles.white(report.summary.totalVariables.toString())}');

        final variableUnusedColor = report.summary.unusedVariableCount > 0 ? AnsiStyles.yellow : AnsiStyles.green;
        buffer.writeln(
            '  ${AnsiStyles.bold('Unused variables:')} ${variableUnusedColor(report.summary.unusedVariableCount.toString())}');

        final variableUsageRate = (report.summary.variableUsageRate * 100).toStringAsFixed(1);
        buffer.writeln('  ${AnsiStyles.bold('Variable usage rate:')} ${AnsiStyles.green('$variableUsageRate%')}');
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
  static String formatJson(
    AnalysisReport report, {
    bool includeTypes = true,
    bool includeMethods = true,
    bool includeVariables = true,
  }) {
    final map = <String, dynamic>{
      'version': report.version,
      'timestamp': report.timestamp,
      'exitCode': report.exitCode,
      'unusedClasses':
          includeTypes ? report.unusedClasses.map(_classDeclarationToJson).toList() : <Map<String, dynamic>>[],
      'unusedMethods':
          includeMethods ? report.unusedMethods.map(_methodDeclarationToJson).toList() : <Map<String, dynamic>>[],
      'unusedVariables':
          includeVariables ? report.unusedVariables.map(_variableDeclarationToJson).toList() : <Map<String, dynamic>>[],
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
      final classLabel = report.unusedClasses.length == 1 ? 'unused class declaration' : 'unused class declarations';
      parts.add('✗ ${report.unusedClasses.length} $classLabel');
    }

    if (report.unusedMethods.isNotEmpty) {
      final methodLabel = report.unusedMethods.length == 1 ? 'unused method' : 'unused methods';
      parts.add('${report.unusedMethods.length} $methodLabel');
    }

    if (report.unusedVariables.isNotEmpty) {
      parts.add('${report.unusedVariables.length} unused variable(s)');
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

  static Map<String, dynamic> _variableDeclarationToJson(VariableDeclaration declaration) {
    return {
      'name': declaration.name,
      'filePath': declaration.filePath,
      'lineNumber': declaration.lineNumber,
      'columnNumber': declaration.columnNumber,
      'variableType': declaration.variableType.name,
      'scopeId': declaration.scope.id,
      'scopeType': declaration.scope.scopeType.name,
      'enclosingDeclaration': declaration.scope.enclosingDeclaration,
      'mutability': declaration.mutability.name,
      'isIntentionallyUnused': declaration.isIntentionallyUnused,
      'isFieldInitializer': declaration.isFieldInitializer,
      'isPatternBinding': declaration.isPatternBinding,
      'patternType': declaration.patternType?.name,
      'annotations': declaration.annotations,
      'ignoreComments': declaration.ignoreComments,
      'staticType': declaration.staticType,
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
      'totalVariables': summary.totalVariables,
      'unusedVariableCount': summary.unusedVariableCount,
      'unusedVariables': summary.unusedVariableCount,
      'totalLocalVariables': summary.totalLocalVariables,
      'unusedLocalVariableCount': summary.unusedLocalVariableCount,
      'totalParameterVariables': summary.totalParameterVariables,
      'unusedParameterVariableCount': summary.unusedParameterVariableCount,
      'totalTopLevelVariables': summary.totalTopLevelVariables,
      'unusedTopLevelVariableCount': summary.unusedTopLevelVariableCount,
      'totalCatchVariables': summary.totalCatchVariables,
      'unusedCatchVariableCount': summary.unusedCatchVariableCount,
      'variablesExplicitlyIgnored': summary.variablesExplicitlyIgnored,
      'variablesIgnoredByConvention': summary.variablesIgnoredByConvention,
      'variablesIgnoredByPattern': summary.variablesIgnoredByPattern,
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
      'variableUsageRate': summary.variableUsageRate,
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

  static const List<VariableType> _variableTypePriorityOrder = [
    VariableType.local,
    VariableType.parameter,
    VariableType.topLevel,
    VariableType.catchClause,
  ];

  static String _getVariableTypeLabel(VariableType type) {
    switch (type) {
      case VariableType.local:
        return 'Local Variables';
      case VariableType.parameter:
        return 'Parameters';
      case VariableType.topLevel:
        return 'Top-Level Variables';
      case VariableType.catchClause:
        return 'Catch Variables';
    }
  }
}
