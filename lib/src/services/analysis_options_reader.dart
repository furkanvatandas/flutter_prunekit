import 'dart:io';
import 'package:yaml/yaml.dart';

/// Reads and parses analysis_options.yaml configuration files.
///
/// Extracts exclude rules and other analyzer settings relevant to dead code detection.
class AnalysisOptionsReader {
  /// Reads the analysis_options.yaml file from the given directory.
  ///
  /// Returns null if the file doesn't exist.
  static Future<AnalysisOptions?> read(String projectRoot) async {
    final optionsFile = File('$projectRoot/analysis_options.yaml');

    if (!await optionsFile.exists()) {
      return null;
    }

    try {
      final content = await optionsFile.readAsString();
      final yaml = loadYaml(content) as YamlMap?;

      if (yaml == null) {
        return null;
      }

      return AnalysisOptions._fromYaml(yaml);
    } catch (e) {
      // Return null on parsing errors - caller will handle
      return null;
    }
  }

  /// Parses analysis options from a YAML string.
  ///
  /// Used for testing without file I/O.
  static AnalysisOptions? parseYaml(String yamlContent) {
    try {
      final yaml = loadYaml(yamlContent) as YamlMap?;
      if (yaml == null) {
        return null;
      }
      return AnalysisOptions._fromYaml(yaml);
    } catch (e) {
      return null;
    }
  }
}

/// Represents parsed analysis_options.yaml configuration.
class AnalysisOptions {
  /// List of glob patterns to exclude from analysis.
  final List<String> excludePatterns;

  /// Whether to use strong mode (affects type inference).
  final bool strongMode;

  /// Creates analysis options.
  AnalysisOptions({
    required this.excludePatterns,
    this.strongMode = true,
  });

  /// Parses from a YAML map.
  factory AnalysisOptions._fromYaml(YamlMap yaml) {
    final excludePatterns = <String>[];

    // Extract exclude patterns from analyzer section
    if (yaml.containsKey('analyzer')) {
      final analyzer = yaml['analyzer'];
      if (analyzer is YamlMap && analyzer.containsKey('exclude')) {
        final exclude = analyzer['exclude'];
        if (exclude is YamlList) {
          excludePatterns.addAll(
            exclude.map((e) => e.toString()),
          );
        }
      }
    }

    return AnalysisOptions(
      excludePatterns: excludePatterns,
    );
  }

  /// Creates default options when no file exists.
  factory AnalysisOptions.defaults() {
    return AnalysisOptions(
      excludePatterns: [],
      strongMode: true,
    );
  }

  @override
  String toString() {
    return 'AnalysisOptions(excludePatterns: $excludePatterns, strongMode: $strongMode)';
  }
}
