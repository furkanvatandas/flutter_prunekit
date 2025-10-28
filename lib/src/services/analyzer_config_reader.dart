import 'dart:io';
import 'package:yaml/yaml.dart';
import '../models/ignore_pattern.dart';

/// Reads and parses flutter_prunekit.yaml configuration files.
///
/// Supports ignore patterns and other configuration options.
class AnalyzerConfigReader {
  /// Creates a configuration reader utility; prefer the static helpers.
  const AnalyzerConfigReader();

  /// The default config filename to look for.
  static const String defaultConfigFilename = 'flutter_prunekit.yaml';

  /// Reads the configuration from a project directory.
  ///
  /// Returns null if no configuration file exists.
  static Future<AnalyzerConfig?> read(String projectRoot) async {
    final configPath = '$projectRoot/$defaultConfigFilename';
    final configFile = File(configPath);

    if (!await configFile.exists()) {
      return null;
    }

    try {
      final contents = await configFile.readAsString();
      final yaml = loadYaml(contents) as Map<dynamic, dynamic>?;

      if (yaml == null) {
        return null;
      }

      return AnalyzerConfig(
        ignoreAnnotations: _parseIgnoreAnnotations(yaml),
        excludePatterns: _parseExcludePatterns(yaml),
        ignoreMethodPatterns: _parseIgnoreMethodPatterns(yaml), // T064: Parse ignore_methods section
      );
    } catch (e) {
      // Invalid YAML or other errors - return null
      return null;
    }
  }

  static List<String> _parseIgnoreAnnotations(Map<dynamic, dynamic> yaml) {
    final annotations = yaml['ignore_annotations'];
    if (annotations is List) {
      return annotations.map((a) => a.toString()).toList();
    }
    return [];
  }

  static List<IgnorePattern> _parseExcludePatterns(Map<dynamic, dynamic> yaml) {
    final excludes = yaml['exclude'];
    if (excludes is List) {
      return excludes
          .map((pattern) => IgnorePattern(
                pattern: pattern.toString(),
                source: IgnoreSource.configFile,
              ))
          .toList();
    }
    return [];
  }

  // T064: Parse ignore_methods section for method-level patterns
  static List<IgnorePattern> _parseIgnoreMethodPatterns(Map<dynamic, dynamic> yaml) {
    final ignoreMethods = yaml['ignore_methods'];
    if (ignoreMethods is List) {
      return ignoreMethods
          .map((pattern) => IgnorePattern(
                pattern: pattern.toString(),
                source: IgnoreSource.configFile,
                type: IgnorePatternType.method, // T063: Mark as method pattern
              ))
          .toList();
    }
    return [];
  }
}

/// Parsed configuration from flutter_prunekit.yaml
class AnalyzerConfig {
  /// List of annotation names to treat as ignore markers.
  ///
  /// Example: ['keepUnused', 'dead_code_ignore', 'preserve']
  final List<String> ignoreAnnotations;

  /// List of glob patterns to exclude from analysis.
  final List<IgnorePattern> excludePatterns;

  /// List of method-level ignore patterns (T064).
  ///
  /// Example: ['test*', '_internal*', 'TestHelper.*', '*.cleanup']
  final List<IgnorePattern> ignoreMethodPatterns;

  /// Builds a configuration object using the provided ignore settings.
  AnalyzerConfig({
    required this.ignoreAnnotations,
    required this.excludePatterns,
    this.ignoreMethodPatterns = const [], // T064: Default to empty list
  });
}
