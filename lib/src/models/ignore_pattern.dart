import 'package:glob/glob.dart';

/// Represents a pattern for excluding files or classes from analysis.
///
/// Supports glob patterns like `lib/legacy/**` or `**/old_*.dart`.
class IgnorePattern {
  /// The glob pattern string.
  final String pattern;

  /// The source of this ignore pattern (for priority resolution).
  final IgnoreSource source;

  /// The compiled glob matcher.
  final Glob _glob;

  /// Creates a new ignore pattern.
  ///
  /// Throws [FormatException] if the pattern is invalid.
  IgnorePattern({
    required this.pattern,
    required this.source,
  }) : _glob = Glob(pattern);

  /// Checks if the given file path matches this pattern.
  ///
  /// Uses normalized paths for consistent matching across platforms.
  bool matches(String filePath) {
    return _glob.matches(filePath);
  }

  /// Returns the priority of this pattern source.
  ///
  /// Higher priority patterns take precedence:
  /// - Annotation (@keepUnused): priority 3
  /// - Config file (flutter_prunekit.yaml): priority 2
  /// - CLI flag (--exclude): priority 1
  int get priority {
    switch (source) {
      case IgnoreSource.annotation:
        return 3;
      case IgnoreSource.configFile:
        return 2;
      case IgnoreSource.cliFlag:
        return 1;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IgnorePattern && runtimeType == other.runtimeType && pattern == other.pattern && source == other.source;

  @override
  int get hashCode => Object.hash(pattern, source);

  @override
  String toString() => 'IgnorePattern($pattern, source: ${source.name})';
}

/// The source of an ignore pattern.
///
/// Used to resolve conflicts when multiple patterns apply.
/// Per T0A3, priority order is: annotation > config file > CLI flag.
enum IgnoreSource {
  /// From @keepUnused or @dead_code_ignore annotation (highest priority).
  annotation,

  /// From flutter_prunekit.yaml configuration file.
  configFile,

  /// From --exclude CLI flag (lowest priority).
  cliFlag,
}
