/// Detects if a Dart file is generated code.
///
/// Per FR-002, generated files must be automatically excluded from analysis.
class GeneratedCodeDetector {
  /// Common patterns for generated file names.
  static const _generatedPatterns = [
    '.g.dart',
    '.freezed.dart',
    '.gr.dart',
    '.realm.dart', // Realm database models
    '.config.dart',
    '.pb.dart', // Protocol buffers
    '.pbenum.dart',
    '.pbserver.dart',
    '.pbjson.dart',
    '.gen.dart',
    '.mocks.dart', // Mockito generated mocks
  ];

  /// Header comments that indicate generated files.
  static const _generatedHeaders = [
    '// GENERATED CODE - DO NOT MODIFY BY HAND',
    '// coverage:ignore-file',
    '// ignore_for_file',
    '// **************************************************************************',
    '// Generator:',
    '// Built value generator',
  ];

  /// Checks if a file path indicates generated code by its name.
  ///
  /// This is a fast check that doesn't require reading the file.
  static bool isGeneratedByPath(String filePath) {
    return _generatedPatterns.any((pattern) => filePath.endsWith(pattern));
  }

  /// Checks if file content indicates generated code by its header.
  ///
  /// This requires reading the first ~20 lines of the file.
  /// Used as a fallback when path-based detection is insufficient.
  static bool isGeneratedByContent(String content) {
    // Only check first 500 characters for performance
    final header = content.length > 500 ? content.substring(0, 500) : content;

    return _generatedHeaders.any((marker) => header.contains(marker));
  }

  /// Comprehensive check combining both path and content detection.
  ///
  /// Returns true if the file is definitely generated code.
  static bool isGenerated(String filePath, String? content) {
    // Fast path check first
    if (isGeneratedByPath(filePath)) {
      return true;
    }

    // Content check if available
    if (content != null) {
      return isGeneratedByContent(content);
    }

    return false;
  }

  /// Returns a list of all supported generated file patterns.
  static List<String> getSupportedPatterns() {
    return List.unmodifiable(_generatedPatterns);
  }
}
