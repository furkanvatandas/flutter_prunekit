import 'dart:io';
import 'package:path/path.dart' as p;

/// Utilities for path manipulation and normalization.
///
/// Provides cross-platform path handling and package-relative path resolution.
class PathUtils {
  /// Normalizes a file path to use forward slashes.
  ///
  /// Converts Windows backslashes to forward slashes for consistent output.
  static String normalize(String path) {
    return p.normalize(path).replaceAll(r'\', '/');
  }

  /// Converts an absolute path to a package-relative path.
  ///
  /// Example:
  /// - Input: `/Users/dev/myapp/lib/models/user.dart`
  /// - Output: `lib/models/user.dart`
  ///
  /// Returns the original path if it's not within the package root.
  static String toPackageRelative(String absolutePath, String packageRoot) {
    final normalized = normalize(absolutePath);
    final normalizedRoot = normalize(packageRoot);

    if (normalized.startsWith(normalizedRoot)) {
      final relative = normalized.substring(normalizedRoot.length);
      // Remove leading slash if present
      return relative.startsWith('/') ? relative.substring(1) : relative;
    }

    return normalized;
  }

  /// Converts a package-relative path to an absolute path.
  ///
  /// Example:
  /// - Input: `lib/models/user.dart`, `/Users/dev/myapp`
  /// - Output: `/Users/dev/myapp/lib/models/user.dart`
  static String toAbsolute(String packageRelativePath, String packageRoot) {
    return p.join(packageRoot, packageRelativePath);
  }

  /// Checks if a path is within a given directory.
  ///
  /// Uses normalized paths for consistent comparison.
  static bool isWithinDirectory(String path, String directory) {
    final normalizedPath = normalize(p.absolute(path));
    final normalizedDir = normalize(p.absolute(directory));

    return normalizedPath.startsWith('$normalizedDir/') || normalizedPath == normalizedDir;
  }

  /// Gets the package name from a pubspec.yaml file.
  ///
  /// Returns null if the file doesn't exist or doesn't contain a name field.
  static String? getPackageName(String packageRoot) {
    final pubspecPath = p.join(packageRoot, 'pubspec.yaml');
    final file = File(pubspecPath);

    if (!file.existsSync()) {
      return null;
    }

    try {
      final content = file.readAsStringSync();
      // Simple regex to extract package name (full YAML parsing done elsewhere)
      final match = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }

  /// Checks if a file path represents a test file.
  ///
  /// Uses common test file patterns:
  /// - Files in test/ directory
  /// - Files ending with _test.dart
  static bool isTestFile(String filePath) {
    final normalized = normalize(filePath);

    // Check if file has _test.dart suffix
    if (normalized.endsWith('_test.dart')) {
      return true;
    }

    // Check if file is under test/ directory but NOT under test/fixtures/
    // This allows test fixtures to be analyzed
    if (normalized.contains('/test/')) {
      return !normalized.contains('/test/fixtures/');
    }

    return false;
  }

  /// Gets the relative path between two paths.
  ///
  /// Returns a path that navigates from [from] to [to].
  static String relative(String to, {required String from}) {
    return p.relative(to, from: from);
  }

  /// Checks if a path has a Dart file extension.
  static bool isDartFile(String path) {
    return path.endsWith('.dart');
  }

  /// Gets the directory containing the given file path.
  static String dirname(String path) {
    return p.dirname(path);
  }

  /// Gets the filename from a path (without directory).
  static String basename(String path) {
    return p.basename(path);
  }

  /// Joins multiple path segments into a single path.
  static String join(String part1, [String? part2, String? part3, String? part4]) {
    final parts = [part1, part2, part3, part4].whereType<String>().toList();
    return p.joinAll(parts);
  }
}
