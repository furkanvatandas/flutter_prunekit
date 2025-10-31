import '../models/reference_graph.dart';
import '../models/class_declaration.dart' as model;
import '../models/method_declaration.dart' as method_model;
import '../models/ignore_pattern.dart';
import '../models/ignore_configuration.dart';
import '../models/variable_declaration.dart' as variable_model;
import '../models/parameter_declaration.dart' as parameter_model;
import '../models/variable_types.dart';

/// Detects unused classes and methods in a reference graph.
///
/// Applies ignore patterns and filters to determine which declarations are truly unused.
///
/// **T020**: Extended to support method-level detection.
/// **T066**: Added verbose diagnostic output for ignore reasons.
/// **T092**: Added IgnoreConfiguration support for variable/parameter patterns.
class UnusedDetector {
  /// List of ignore patterns to apply.
  final List<IgnorePattern> ignorePatterns;

  /// Configuration for ignoring variables/parameters by name pattern (T092).
  final IgnoreConfiguration? ignoreConfiguration;

  /// Enable verbose diagnostic output (T066).
  final bool verbose;

  UnusedDetector({
    this.ignorePatterns = const [],
    this.ignoreConfiguration,
    this.verbose = false, // T066: Verbose flag
  });

  /// Finds all unused classes in the graph.
  ///
  /// Returns classes that have zero incoming references and are not ignored.
  /// Results are sorted by uniqueId for deterministic output.
  List<model.ClassDeclaration> findUnused(ReferenceGraph graph) {
    final unused = graph.getUnusedDeclarations();

    // Filter out ignored classes
    final filtered = unused.where((declaration) {
      return !_shouldIgnore(declaration);
    }).toList();

    // Already sorted in ReferenceGraph.getUnusedDeclarations()
    return filtered;
  }

  /// Checks if a class declaration should be ignored.
  ///
  /// Applies ignore pattern priority per T0A3:
  /// 1. @keepUnused annotation (highest priority)
  /// 2. flutter_dead_code.yaml config patterns
  /// 3. --exclude CLI flag patterns
  bool _shouldIgnore(model.ClassDeclaration declaration) {
    // Check annotation-based ignoring (highest priority)
    if (declaration.hasIgnoreAnnotation) {
      return true;
    }

    // Check ignore patterns by priority
    final matchingPatterns = ignorePatterns.where((pattern) => pattern.matches(declaration.filePath)).toList();

    if (matchingPatterns.isEmpty) {
      return false;
    }

    // Sort by priority (highest first) and return true if any match
    matchingPatterns.sort((a, b) => b.priority.compareTo(a.priority));
    return true;
  }

  /// Finds all unused methods/functions in the graph (T020).
  ///
  /// Returns methods that have zero invocations and are not ignored.
  /// Excludes:
  /// - Methods with @keepUnused annotation
  /// - Override methods (already handled in ReferenceGraph)
  /// - Lifecycle methods (already handled in ReferenceGraph)
  /// - Methods matching ignore patterns
  ///
  /// Results are sorted by uniqueId for deterministic output.
  /// **T066**: When verbose=true, prints diagnostic info for ignored methods.
  List<method_model.MethodDeclaration> findUnusedMethods(ReferenceGraph graph) {
    final unused = graph.getUnusedMethodDeclarations();

    // T066: Log annotation-based ignores (methods that were filtered by ReferenceGraph)
    if (verbose) {
      final allMethods = graph.methodDeclarations.values;
      final annotatedIgnored = allMethods.where((m) => m.annotations.contains('keepUnused')).where((m) {
        // Only log if method would otherwise be unused
        final invocations = graph.methodInvocations[m.name] ?? [];
        if (m.containingClass == null) {
          return invocations.isEmpty;
        }
        return !invocations.any((inv) => inv.targetClass == m.containingClass);
      }).toList();

      for (final method in annotatedIgnored) {
        final methodId = method.containingClass != null ? '${method.containingClass}.${method.name}' : method.name;
        print('  [IGNORE] $methodId - Has @keepUnused annotation');
      }
    }

    // Filter out ignored methods (pattern-based)
    final filtered = unused.where((declaration) {
      return !_shouldIgnoreMethod(declaration);
    }).toList();

    // Already sorted in ReferenceGraph.getUnusedMethodDeclarations()
    return filtered;
  }

  /// Detects variable declarations with no read references (US1).
  List<variable_model.VariableDeclaration> detectUnusedVariables(ReferenceGraph graph) {
    final unusedDeclarations = graph.variableDeclarations.values.where((declaration) {
      if (declaration is parameter_model.ParameterDeclaration && declaration.isFieldInitializer) {
        return false;
      }
      final references = graph.variableReferences[declaration.id];
      final hasReadableReference = references?.any(
            (reference) =>
                reference.referenceType == ReferenceType.read || reference.referenceType == ReferenceType.readWrite,
          ) ??
          false;
      return !hasReadableReference;
    }).toList();

    final filtered = <variable_model.VariableDeclaration>[];

    for (final declaration in unusedDeclarations) {
      if (_shouldIgnoreVariable(declaration)) {
        continue;
      }
      filtered.add(declaration);
    }

    filtered.sort((a, b) {
      final fileCompare = a.filePath.compareTo(b.filePath);
      if (fileCompare != 0) {
        return fileCompare;
      }
      final lineCompare = a.lineNumber.compareTo(b.lineNumber);
      if (lineCompare != 0) {
        return lineCompare;
      }
      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  /// Checks if a method declaration should be ignored (T020, T066).
  ///
  /// Applies ignore pattern priority:
  /// 1. @keepUnused annotation (already checked in ReferenceGraph)
  /// 2. flutter_dead_code.yaml config patterns for methods
  /// 3. --exclude CLI flag patterns
  ///
  /// When verbose=true, prints diagnostic information about why methods are ignored.
  bool _shouldIgnoreMethod(method_model.MethodDeclaration declaration) {
    final methodId =
        declaration.containingClass != null ? '${declaration.containingClass}.${declaration.name}' : declaration.name;

    // Check file-level ignore patterns first
    final filePatterns = ignorePatterns
        .where((p) => p.type == IgnorePatternType.file)
        .where((p) => p.matches(declaration.filePath))
        .toList();

    if (filePatterns.isNotEmpty) {
      if (verbose) {
        final pattern = filePatterns.first;
        print('  [IGNORE] $methodId - File excluded by ${_getSourceName(pattern.source)}: ${pattern.pattern}');
      }
      return true;
    }

    // Check method-level ignore patterns
    final methodPatterns = ignorePatterns
        .where((p) => p.type == IgnorePatternType.method)
        .where((p) => p.matchesMethod(
              declaration.name,
              className: declaration.containingClass,
            ))
        .toList();

    if (methodPatterns.isEmpty) {
      return false;
    }

    // Sort by priority (highest first)
    methodPatterns.sort((a, b) => b.priority.compareTo(a.priority));

    // T066: Verbose diagnostic output
    if (verbose) {
      final pattern = methodPatterns.first; // Highest priority match
      print('  [IGNORE] $methodId - Matched ${_getSourceName(pattern.source)}: ${pattern.pattern}');
    }

    return true;
  }

  bool _shouldIgnoreVariable(variable_model.VariableDeclaration declaration) {
    final label = declaration.displayLabel;

    // SC-004: Single underscore convention (highest priority)
    if (declaration.isIntentionallyUnused) {
      if (verbose) {
        print('  [IGNORE] $label - Uses intentional underscore convention');
      }
      return true;
    }

    // SC-006: Catch variables ignored by default unless explicitly enabled
    if (declaration.variableType == VariableType.catchClause) {
      final shouldCheck = ignoreConfiguration?.checkCatchVariables ?? false;
      if (!shouldCheck) {
        if (verbose) {
          print('  [IGNORE] $label - Catch variable (check_catch_variables: false)');
        }
        return true;
      }
    }

    // SC-007: BuildContext parameters ignored by default unless explicitly enabled
    if (declaration is parameter_model.ParameterDeclaration) {
      if (_isBuildContextParameter(declaration)) {
        final shouldCheck = ignoreConfiguration?.checkBuildContextParameters ?? false;
        if (!shouldCheck) {
          if (verbose) {
            print('  [IGNORE] $label - BuildContext parameter (check_build_context_parameters: false)');
          }
          return true;
        }
      }
    }

    // Check explicit ignore comments/annotations
    if (declaration.hasExplicitIgnore) {
      if (verbose) {
        print('  [IGNORE] $label - Explicit ignore via annotation/comment');
      }
      return true;
    }

    // Check IgnoreConfiguration patterns (T092)
    if (ignoreConfiguration != null) {
      if (declaration is parameter_model.ParameterDeclaration) {
        if (ignoreConfiguration!.matchesParameterPattern(declaration.name)) {
          if (verbose) {
            print('  [IGNORE] ${declaration.enclosingCallable}.${declaration.name} - '
                'Matched config parameter pattern');
          }
          return true;
        }
      } else {
        if (ignoreConfiguration!.matchesVariablePattern(declaration.name)) {
          if (verbose) {
            print('  [IGNORE] $label - Matched config variable pattern');
          }
          return true;
        }
      }
    }

    // Check file-level ignore patterns
    IgnorePattern? filePattern;
    for (final pattern in ignorePatterns) {
      if (pattern.type == IgnorePatternType.file && pattern.matches(declaration.filePath)) {
        filePattern = pattern;
        break;
      }
    }

    if (filePattern != null) {
      if (verbose) {
        print('  [IGNORE] $label - File excluded by ${_getSourceName(filePattern.source)}: ${filePattern.pattern}');
      }
      return true;
    }

    // Check parameter-specific patterns
    if (declaration is parameter_model.ParameterDeclaration) {
      IgnorePattern? parameterPattern;
      for (final pattern in ignorePatterns) {
        final matches = (pattern.type == IgnorePatternType.parameter || pattern.type == IgnorePatternType.variable) &&
            pattern.matchesParameterName(declaration.name);
        if (matches) {
          parameterPattern = pattern;
          break;
        }
      }

      if (parameterPattern != null) {
        if (verbose) {
          print('  [IGNORE] ${declaration.enclosingCallable}.${declaration.name} - Matched '
              '${_getSourceName(parameterPattern.source)}: ${parameterPattern.pattern}');
        }
        return true;
      }
    } else {
      // Check variable-specific patterns
      IgnorePattern? variablePattern;
      for (final pattern in ignorePatterns) {
        if (pattern.type == IgnorePatternType.variable && pattern.matchesVariableName(declaration.name)) {
          variablePattern = pattern;
          break;
        }
      }

      if (variablePattern != null) {
        if (verbose) {
          print('  [IGNORE] $label - Matched ${_getSourceName(variablePattern.source)}: ${variablePattern.pattern}');
        }
        return true;
      }
    }

    return false;
  }

  /// T066: Get human-readable name for pattern source
  String _getSourceName(IgnoreSource source) {
    switch (source) {
      case IgnoreSource.annotation:
        return 'annotation';
      case IgnoreSource.configFile:
        return 'config pattern';
      case IgnoreSource.cliFlag:
        return 'CLI flag';
    }
  }

  /// Gets statistics about unused detection.
  UnusedStatistics getStatistics(ReferenceGraph graph) {
    final allUnused = graph.getUnusedDeclarations();
    final filteredUnused = findUnused(graph);

    // Method statistics (T020)
    final allUnusedMethods = graph.getUnusedMethodDeclarations();
    final filteredUnusedMethods = findUnusedMethods(graph);

    // Variable statistics (US1)
    final allUnusedVariables = graph.getUnusedVariableDeclarations();
    final filteredUnusedVariables = detectUnusedVariables(graph);
    final conventionIgnored = allUnusedVariables.where((d) => d.isIntentionallyUnused).length;
    final explicitIgnored = allUnusedVariables.where((d) => d.hasExplicitIgnore).length;
    final computedPatternIgnored =
        allUnusedVariables.length - filteredUnusedVariables.length - conventionIgnored - explicitIgnored;
    final patternIgnored = computedPatternIgnored < 0 ? 0 : computedPatternIgnored;

    return UnusedStatistics(
      totalClasses: graph.declarations.length,
      unusedBeforeFiltering: allUnused.length,
      unusedAfterFiltering: filteredUnused.length,
      ignoredByAnnotation: allUnused.where((d) => d.hasIgnoreAnnotation).length,
      ignoredByPattern: allUnused.length - filteredUnused.length - allUnused.where((d) => d.hasIgnoreAnnotation).length,
      totalMethods: graph.methodDeclarations.length,
      unusedMethodsBeforeFiltering: allUnusedMethods.length,
      unusedMethodsAfterFiltering: filteredUnusedMethods.length,
      methodsIgnoredByAnnotation: allUnusedMethods.where((m) => m.annotations.contains('keepUnused')).length,
      methodsIgnoredByPattern: allUnusedMethods.length -
          filteredUnusedMethods.length -
          allUnusedMethods.where((m) => m.annotations.contains('keepUnused')).length,
      totalVariables: graph.variableDeclarations.length,
      unusedVariablesBeforeFiltering: allUnusedVariables.length,
      unusedVariablesAfterFiltering: filteredUnusedVariables.length,
      variablesIgnoredByConvention: conventionIgnored,
      variablesIgnoredByExplicitIgnore: explicitIgnored,
      variablesIgnoredByPattern: patternIgnored,
    );
  }

  /// T066: Gets statistics using pre-calculated results (avoids duplicate verbose logging).
  UnusedStatistics getStatisticsWithCachedResults(
    ReferenceGraph graph,
    List<model.ClassDeclaration> unusedClasses,
    List<method_model.MethodDeclaration> unusedMethods, {
    List<variable_model.VariableDeclaration>? unusedVariables,
  }) {
    final allUnused = graph.getUnusedDeclarations();
    final allUnusedMethods = graph.getUnusedMethodDeclarations();
    final allUnusedVariables = graph.getUnusedVariableDeclarations();

    final filteredUnusedVariables = unusedVariables ?? detectUnusedVariables(graph);
    final conventionIgnored = allUnusedVariables.where((d) => d.isIntentionallyUnused).length;
    final explicitIgnored = allUnusedVariables.where((d) => d.hasExplicitIgnore).length;
    final computedPatternIgnored =
        allUnusedVariables.length - filteredUnusedVariables.length - conventionIgnored - explicitIgnored;
    final patternIgnored = computedPatternIgnored < 0 ? 0 : computedPatternIgnored;

    return UnusedStatistics(
      totalClasses: graph.declarations.length,
      unusedBeforeFiltering: allUnused.length,
      unusedAfterFiltering: unusedClasses.length,
      ignoredByAnnotation: allUnused.where((d) => d.hasIgnoreAnnotation).length,
      ignoredByPattern: allUnused.length - unusedClasses.length - allUnused.where((d) => d.hasIgnoreAnnotation).length,
      totalMethods: graph.methodDeclarations.length,
      unusedMethodsBeforeFiltering: allUnusedMethods.length,
      unusedMethodsAfterFiltering: unusedMethods.length,
      methodsIgnoredByAnnotation: allUnusedMethods.where((m) => m.annotations.contains('keepUnused')).length,
      methodsIgnoredByPattern: allUnusedMethods.length -
          unusedMethods.length -
          allUnusedMethods.where((m) => m.annotations.contains('keepUnused')).length,
      totalVariables: graph.variableDeclarations.length,
      unusedVariablesBeforeFiltering: allUnusedVariables.length,
      unusedVariablesAfterFiltering: filteredUnusedVariables.length,
      variablesIgnoredByConvention: conventionIgnored,
      variablesIgnoredByExplicitIgnore: explicitIgnored,
      variablesIgnoredByPattern: patternIgnored,
    );
  }

  /// Checks if a parameter is a BuildContext type (SC-007).
  ///
  /// Only uses static type information from the analyzer.
  /// Does NOT use naming conventions as fallback to avoid false positives
  /// (e.g., user might name parameter 'ctx', 'c', or something else entirely).
  bool _isBuildContextParameter(parameter_model.ParameterDeclaration declaration) {
    // Only check static type - no naming convention fallback
    if (declaration.staticType != null) {
      final type = declaration.staticType!;
      // Check for BuildContext or subtypes
      if (type == 'BuildContext' || type.endsWith('.BuildContext') || type.contains('BuildContext')) {
        return true;
      }
    }

    return false;
  }
}

/// Statistics about unused class, method, and variable detection.
///
/// **T020**: Extended to include method statistics.
/// **US1**: Extended to include variable statistics.
class UnusedStatistics {
  /// Total number of class declarations in the graph.
  final int totalClasses;

  /// Number of unused classes before applying ignore filters.
  final int unusedBeforeFiltering;

  /// Number of unused classes after applying ignore filters.
  final int unusedAfterFiltering;

  /// Number of classes ignored by @keepUnused annotation.
  final int ignoredByAnnotation;

  /// Number of classes ignored by glob patterns.
  final int ignoredByPattern;

  /// Total number of method declarations in the graph (T020).
  final int totalMethods;

  /// Number of unused methods before applying ignore filters (T020).
  final int unusedMethodsBeforeFiltering;

  /// Number of unused methods after applying ignore filters (T020).
  final int unusedMethodsAfterFiltering;

  /// Number of methods ignored by @keepUnused annotation (T020).
  final int methodsIgnoredByAnnotation;

  /// Number of methods ignored by glob patterns (T020).
  final int methodsIgnoredByPattern;

  /// Total number of variable declarations in the graph (US1).
  final int totalVariables;

  /// Number of unused variables before applying ignore filters (US1).
  final int unusedVariablesBeforeFiltering;

  /// Number of unused variables after applying ignore filters (US1).
  final int unusedVariablesAfterFiltering;

  /// Number of variables ignored via underscore convention (US1).
  final int variablesIgnoredByConvention;

  /// Number of variables ignored via explicit annotations/comments (US1).
  final int variablesIgnoredByExplicitIgnore;

  /// Number of variables ignored via glob/configuration patterns (US1).
  final int variablesIgnoredByPattern;

  UnusedStatistics({
    required this.totalClasses,
    required this.unusedBeforeFiltering,
    required this.unusedAfterFiltering,
    required this.ignoredByAnnotation,
    required this.ignoredByPattern,
    this.totalMethods = 0,
    this.unusedMethodsBeforeFiltering = 0,
    this.unusedMethodsAfterFiltering = 0,
    this.methodsIgnoredByAnnotation = 0,
    this.methodsIgnoredByPattern = 0,
    this.totalVariables = 0,
    this.unusedVariablesBeforeFiltering = 0,
    this.unusedVariablesAfterFiltering = 0,
    this.variablesIgnoredByConvention = 0,
    this.variablesIgnoredByExplicitIgnore = 0,
    this.variablesIgnoredByPattern = 0,
  });
}
