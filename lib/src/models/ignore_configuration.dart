import 'dart:io';
import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart';

/// Configuration for ignoring variables and parameters based on patterns.
///
/// Supports loading from flutter_prunekit.yaml with sections:
/// - ignore_variables: List of glob patterns for variable names to ignore
/// - ignore_parameters: List of glob patterns for parameter names to ignore
/// - check_catch_variables: Whether to check unused catch block variables (default: false)
/// - check_build_context_parameters: Whether to check unused BuildContext parameters (default: false)
class IgnoreConfiguration {
  /// Patterns for ignoring variables.
  final List<String> variablePatterns;

  /// Patterns for ignoring parameters.
  final List<String> parameterPatterns;

  /// Whether to check for unused catch block variables.
  /// Default is false because catch variables are often intentionally unused
  /// (e.g., `catch (e) { rethrow; }` or `catch (_) { ... }`).
  final bool checkCatchVariables;

  /// Whether to check for unused BuildContext parameters.
  /// Default is false because BuildContext is often required by Flutter APIs
  /// but not always used in the widget implementation.
  final bool checkBuildContextParameters;

  /// Creates an ignore configuration.
  IgnoreConfiguration({
    this.variablePatterns = const [],
    this.parameterPatterns = const [],
    this.checkCatchVariables = false,
    this.checkBuildContextParameters = false,
  });

  /// Loads ignore configuration from flutter_dead_code.yaml in the project root.
  ///
  /// Returns null if the file doesn't exist or parsing fails.
  static Future<IgnoreConfiguration?> load(String projectRoot) async {
    final configFile = File('$projectRoot/flutter_dead_code.yaml');

    if (!await configFile.exists()) {
      return null;
    }

    try {
      final content = await configFile.readAsString();
      final yaml = loadYaml(content) as YamlMap?;

      if (yaml == null) {
        return null;
      }

      return IgnoreConfiguration._fromYaml(yaml);
    } catch (e) {
      // Return null on parsing errors
      return null;
    }
  }

  /// Parses ignore configuration from a YAML map.
  factory IgnoreConfiguration._fromYaml(YamlMap yaml) {
    final variablePatterns = <String>[];
    final parameterPatterns = <String>[];
    bool checkCatchVariables = false;
    bool checkBuildContextParameters = false;

    // Extract variable patterns
    if (yaml.containsKey('ignore_variables')) {
      final patterns = yaml['ignore_variables'];
      if (patterns is YamlList) {
        variablePatterns.addAll(
          patterns.map((p) => p.toString()),
        );
      }
    }

    // Extract parameter patterns
    if (yaml.containsKey('ignore_parameters')) {
      final patterns = yaml['ignore_parameters'];
      if (patterns is YamlList) {
        parameterPatterns.addAll(
          patterns.map((p) => p.toString()),
        );
      }
    }

    // Extract check_catch_variables option
    if (yaml.containsKey('check_catch_variables')) {
      final value = yaml['check_catch_variables'];
      if (value is bool) {
        checkCatchVariables = value;
      }
    }

    // Extract check_build_context_parameters option
    if (yaml.containsKey('check_build_context_parameters')) {
      final value = yaml['check_build_context_parameters'];
      if (value is bool) {
        checkBuildContextParameters = value;
      }
    }

    return IgnoreConfiguration(
      variablePatterns: variablePatterns,
      parameterPatterns: parameterPatterns,
      checkCatchVariables: checkCatchVariables,
      checkBuildContextParameters: checkBuildContextParameters,
    );
  }

  /// Creates an empty configuration with no ignore patterns.
  factory IgnoreConfiguration.empty() {
    return IgnoreConfiguration(
      variablePatterns: [],
      parameterPatterns: [],
      checkCatchVariables: false,
      checkBuildContextParameters: false,
    );
  }

  /// Checks if a variable name matches any variable ignore pattern.
  bool matchesVariablePattern(String variableName) {
    for (final pattern in variablePatterns) {
      final glob = Glob(pattern);
      if (glob.matches(variableName)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if a parameter name matches any parameter ignore pattern.
  bool matchesParameterPattern(String parameterName) {
    for (final pattern in parameterPatterns) {
      final glob = Glob(pattern);
      if (glob.matches(parameterName)) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() {
    return 'IgnoreConfiguration('
        'variablePatterns: $variablePatterns, '
        'parameterPatterns: $parameterPatterns, '
        'checkCatchVariables: $checkCatchVariables, '
        'checkBuildContextParameters: $checkBuildContextParameters)';
  }
}
