import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/line_info.dart';

import '../models/pattern_variable.dart';
import '../models/scope_context.dart';
import '../models/variable_types.dart';
import '../utils/underscore_convention_checker.dart';

/// Extracts pattern-bound variables from Dart 3.0+ pattern matching constructs.
///
/// Supports destructuring declarations, switch/case patterns, and nested
/// pattern compositions (list, record, object, map, logical). The extractor
/// returns fully populated [PatternVariable] models ready for scope
/// registration and unused-variable tracking.
class PatternVariableExtractor {
  PatternVariableExtractor({
    required this.filePath,
    required this.lineInfo,
    required this.buildVariableId,
    UnderscoreConventionChecker? underscoreChecker,
  }) : underscoreChecker = underscoreChecker ?? const UnderscoreConventionChecker();

  /// Absolute path of the file being analyzed.
  final String filePath;

  /// Line information for mapping offsets to line/column pairs.
  final LineInfo lineInfo;

  /// Utility that flags intentionally unused identifiers (`_`, `_ignored`).
  final UnderscoreConventionChecker underscoreChecker;

  /// Callback that mirrors [_VariableCollectorVisitor._buildVariableId].
  final String Function(ScopeContext scope, String name) buildVariableId;

  static const Set<PatternType> _stickyPatternTypes = {
    PatternType.switchCase,
  };

  /// Extracts pattern variables produced by a destructuring declaration.
  List<PatternVariable> extractFromDestructuring({
    required PatternVariableDeclaration declaration,
    required ScopeContext scope,
    required Mutability baseMutability,
    List<String>? annotations,
    List<String>? ignoreComments,
  }) {
    return extractFromPattern(
      pattern: declaration.pattern,
      scope: scope,
      baseMutability: baseMutability,
      rootPatternType: null,
      annotations: annotations,
      ignoreComments: ignoreComments,
    );
  }

  /// Extracts pattern variables produced by a `switch` case pattern.
  List<PatternVariable> extractFromSwitchCase({
    required SwitchPatternCase node,
    required ScopeContext scope,
    required Mutability baseMutability,
    List<String>? annotations,
    List<String>? ignoreComments,
  }) {
    return extractFromPattern(
      pattern: node.guardedPattern.pattern,
      scope: scope,
      baseMutability: baseMutability,
      rootPatternType: PatternType.switchCase,
      annotations: annotations,
      ignoreComments: ignoreComments,
    );
  }

  /// Extracts pattern variables from a generic guarded pattern (if-case, etc.).
  List<PatternVariable> extractFromGuardedPattern({
    required GuardedPattern guardedPattern,
    required ScopeContext scope,
    required Mutability baseMutability,
    PatternType? rootPatternType,
    List<String>? annotations,
    List<String>? ignoreComments,
  }) {
    return extractFromPattern(
      pattern: guardedPattern.pattern,
      scope: scope,
      baseMutability: baseMutability,
      rootPatternType: rootPatternType,
      annotations: annotations,
      ignoreComments: ignoreComments,
    );
  }

  /// Core dispatcher that walks a pattern tree and returns its bindings.
  List<PatternVariable> extractFromPattern({
    required DartPattern pattern,
    required ScopeContext scope,
    required Mutability baseMutability,
    PatternType? rootPatternType,
    List<String>? annotations,
    List<String>? ignoreComments,
  }) {
    final context = _PatternExtractionContext(
      scope: scope,
      defaultMutability: baseMutability,
      patternType: _determineInitialPatternType(pattern, rootPatternType),
      patternSource: pattern.toSource(),
      annotations: annotations ?? const [],
      ignoreComments: ignoreComments ?? const [],
      buildVariableId: buildVariableId,
    );

    final results = <PatternVariable>[];
    _collectPattern(pattern, context, results);
    return results;
  }

  PatternType _determineInitialPatternType(DartPattern pattern, PatternType? override) {
    if (override != null) {
      return override;
    }
    return _inferPatternType(pattern) ?? PatternType.destructuring;
  }

  void _collectPattern(
    DartPattern pattern,
    _PatternExtractionContext context,
    List<PatternVariable> out, {
    bool isRestElement = false,
  }) {
    if (pattern is DeclaredVariablePattern) {
      final variable = _buildPatternVariable(pattern, context, isRestElement);
      if (variable != null) {
        out.add(variable);
      }
      return;
    }

    if (pattern is ListPattern) {
      final childContext = context.child(
        patternType: _deriveChildPatternType(context.patternType, pattern),
        patternSource: pattern.toSource(),
      );

      for (final element in pattern.elements) {
        if (element is RestPatternElement) {
          final nested = element.pattern;
          if (nested != null) {
            _collectPattern(nested, childContext, out, isRestElement: true);
          }
        } else if (element is DartPattern) {
          _collectPattern(element, childContext, out);
        }
      }
      return;
    }

    if (pattern is MapPattern) {
      final childContext = context.child(
        patternType: _deriveChildPatternType(context.patternType, pattern),
        patternSource: pattern.toSource(),
      );

      for (final element in pattern.elements) {
        if (element is RestPatternElement) {
          final nested = element.pattern;
          if (nested != null) {
            _collectPattern(nested, childContext, out, isRestElement: true);
          }
        } else if (element is MapPatternEntry) {
          _collectPattern(element.value, childContext, out);
        }
      }
      return;
    }

    if (pattern is RecordPattern) {
      final childContext = context.child(
        patternType: _deriveChildPatternType(context.patternType, pattern),
        patternSource: pattern.toSource(),
      );

      for (final field in pattern.fields) {
        _collectPattern(field.pattern, childContext, out);
      }
      return;
    }

    if (pattern is ObjectPattern) {
      final childContext = context.child(
        patternType: _deriveChildPatternType(context.patternType, pattern),
        patternSource: pattern.toSource(),
      );

      for (final field in pattern.fields) {
        _collectPattern(field.pattern, childContext, out);
      }
      return;
    }

    if (pattern is ParenthesizedPattern) {
      _collectPattern(pattern.pattern, context, out, isRestElement: isRestElement);
      return;
    }

    if (pattern is CastPattern) {
      _collectPattern(pattern.pattern, context, out, isRestElement: isRestElement);
      return;
    }

    if (pattern is NullCheckPattern) {
      _collectPattern(pattern.pattern, context, out, isRestElement: isRestElement);
      return;
    }

    if (pattern is NullAssertPattern) {
      _collectPattern(pattern.pattern, context, out, isRestElement: isRestElement);
      return;
    }

    if (pattern is LogicalAndPattern) {
      _collectPattern(pattern.leftOperand, context, out, isRestElement: isRestElement);
      _collectPattern(pattern.rightOperand, context, out, isRestElement: isRestElement);
      return;
    }

    if (pattern is LogicalOrPattern) {
      _collectPattern(pattern.leftOperand, context, out, isRestElement: isRestElement);
      _collectPattern(pattern.rightOperand, context, out, isRestElement: isRestElement);
      return;
    }

    // Remaining pattern kinds (constant, relational, wildcard, assigned variable)
    // either do not declare variables or are handled by other cases above.
  }

  PatternVariable? _buildPatternVariable(
    DeclaredVariablePattern node,
    _PatternExtractionContext context,
    bool isRestElement,
  ) {
    final nameToken = node.name;
    final name = nameToken.lexeme;
    if (name.isEmpty) {
      return null;
    }

    final location = lineInfo.getLocation(nameToken.offset);
    final mutability = _resolveMutability(node, context.defaultMutability);
    final fragmentElement = node.declaredFragment?.element;
    final staticType = fragmentElement?.type.getDisplayString(withNullability: true);

    return PatternVariable(
      id: context.buildVariableId(context.scope, name),
      name: name,
      filePath: filePath,
      lineNumber: location.lineNumber,
      columnNumber: location.columnNumber - 1,
      scope: context.scope,
      mutability: mutability,
      patternExpression: context.patternSource,
      bindingPosition: context.nextBindingIndex(),
      isRestElement: isRestElement,
      patternType: context.patternType,
      annotations: context.annotations,
      ignoreComments: context.ignoreComments,
      staticType: staticType,
      isIntentionallyUnused: underscoreChecker.isIntentionallyUnused(name),
    );
  }

  Mutability _resolveMutability(DeclaredVariablePattern pattern, Mutability fallback) {
    final keyword = pattern.keyword?.keyword;
    if (keyword == Keyword.FINAL) {
      return Mutability.final_;
    }
    if (keyword == Keyword.VAR) {
      return Mutability.mutable;
    }
    return fallback;
  }

  PatternType _deriveChildPatternType(PatternType current, DartPattern child) {
    if (_stickyPatternTypes.contains(current)) {
      return current;
    }
    return _inferPatternType(child) ?? current;
  }

  PatternType? _inferPatternType(DartPattern pattern) {
    final effective = _unwrapPattern(pattern);
    if (effective is ListPattern) {
      return PatternType.list;
    }
    if (effective is RecordPattern) {
      return PatternType.record;
    }
    if (effective is ObjectPattern) {
      return PatternType.object;
    }
    if (effective is MapPattern) {
      return PatternType.map;
    }
    if (effective is LogicalAndPattern) {
      return _inferPatternType(effective.leftOperand) ?? _inferPatternType(effective.rightOperand);
    }
    if (effective is LogicalOrPattern) {
      return _inferPatternType(effective.leftOperand) ?? _inferPatternType(effective.rightOperand);
    }
    return null;
  }

  DartPattern _unwrapPattern(DartPattern pattern) {
    if (pattern is ParenthesizedPattern) {
      return _unwrapPattern(pattern.pattern);
    }
    if (pattern is CastPattern) {
      return _unwrapPattern(pattern.pattern);
    }
    if (pattern is NullCheckPattern) {
      return _unwrapPattern(pattern.pattern);
    }
    if (pattern is NullAssertPattern) {
      return _unwrapPattern(pattern.pattern);
    }
    return pattern;
  }
}

/// Captures the state while walking a single pattern tree.
class _PatternExtractionContext {
  _PatternExtractionContext({
    required this.scope,
    required this.defaultMutability,
    required this.patternType,
    required this.patternSource,
    required List<String> annotations,
    required List<String> ignoreComments,
    required this.buildVariableId,
  })  : annotations = List.unmodifiable(annotations),
        ignoreComments = List.unmodifiable(ignoreComments);

  final ScopeContext scope;
  final Mutability defaultMutability;
  final PatternType patternType;
  final String patternSource;
  final List<String> annotations;
  final List<String> ignoreComments;
  final String Function(ScopeContext scope, String name) buildVariableId;

  int _bindingIndex = 0;

  int nextBindingIndex() => _bindingIndex++;

  _PatternExtractionContext child({
    required PatternType patternType,
    required String patternSource,
    Mutability? defaultMutability,
  }) {
    return _PatternExtractionContext(
      scope: scope,
      defaultMutability: defaultMutability ?? this.defaultMutability,
      patternType: patternType,
      patternSource: patternSource,
      annotations: annotations,
      ignoreComments: ignoreComments,
      buildVariableId: buildVariableId,
    );
  }
}
