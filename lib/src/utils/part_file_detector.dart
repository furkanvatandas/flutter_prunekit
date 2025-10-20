/// Utility for detecting Dart part files and resolving their parent library paths.
///
/// Part files are Dart files that begin with a `part of` directive and belong
/// to a parent library file. This class provides methods to:
/// - Detect if a file is a part file
/// - Resolve the parent library path from the `part of` directive
library;

import 'dart:io';
import 'package:path/path.dart' as path;

/// Detector for Dart part files and their parent libraries.
class PartFileDetector {
  /// Regex to match URI-based `part of` directives.
  ///
  /// Matches: `part of 'parent.dart';` or `part of "parent.dart";`
  static final _partOfUriRegex = RegExp(
    r'''^\s*part\s+of\s+['"]([^'"]+)['"];''',
    multiLine: true,
  );

  /// Regex to match library-based `part of` directives (legacy).
  ///
  /// Matches: `part of my.library.name;`
  static final _partOfLibraryRegex = RegExp(
    r'^\s*part\s+of\s+([a-zA-Z_][\w.]*);',
    multiLine: true,
  );

  /// Regex to match single-line comments (`//`).
  static final _singleLineCommentRegex = RegExp(r'//.*$', multiLine: true);

  /// Regex to match multi-line comments (`/* */`).
  static final _multiLineCommentRegex = RegExp(r'/\*[\s\S]*?\*/', multiLine: true);

  /// Checks if a file is a Dart part file.
  ///
  /// A file is considered a part file if it contains a `part of` directive
  /// after removing comments.
  ///
  /// Returns `true` if the file is a part file, `false` otherwise.
  /// Returns `false` if the file cannot be read or does not exist.
  ///
  /// Performance: Completes in <50ms per file (early-exits after finding directive).
  static Future<bool> isPartFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final content = await file.readAsString();
      final withoutComments = _removeComments(content);

      // Check for either URI-based or library-based part directive
      return _partOfUriRegex.hasMatch(withoutComments) || _partOfLibraryRegex.hasMatch(withoutComments);
    } catch (e) {
      // File read error, invalid UTF-8, or other IO errors
      return false;
    }
  }

  /// Resolves the parent library path from a part file's `part of` directive.
  ///
  /// Returns the absolute path to the parent library if it can be resolved,
  /// or `null` if:
  /// - The file is not a part file
  /// - The directive is malformed
  /// - The parent file does not exist
  /// - The parent cannot be resolved (legacy library identifier without match)
  ///
  /// Performance: Completes in <100ms per file.
  static Future<String?> resolveParentPath(String partFilePath) async {
    try {
      final file = File(partFilePath);
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final withoutComments = _removeComments(content);

      // Try URI-based directive first (modern Dart)
      final uriMatch = _partOfUriRegex.firstMatch(withoutComments);
      if (uriMatch != null) {
        final relativePath = uriMatch.group(1)!;
        final partDir = path.dirname(partFilePath);
        final resolvedPath = path.normalize(path.join(partDir, relativePath));

        // Verify parent file exists
        if (await File(resolvedPath).exists()) {
          return resolvedPath;
        }
        return null; // Parent doesn't exist
      }

      // Try library-based directive (legacy Dart)
      final libMatch = _partOfLibraryRegex.firstMatch(withoutComments);
      if (libMatch != null) {
        final libraryName = libMatch.group(1)!;
        // Search for library with matching name in same directory
        return await _findLibraryByName(libraryName, partFilePath);
      }

      return null; // No valid directive found
    } catch (e) {
      return null;
    }
  }

  /// Removes comments from Dart code.
  ///
  /// Removes both single-line (`//`) and multi-line (`/* */`) comments
  /// to avoid false matches in commented code.
  static String _removeComments(String content) {
    // Remove multi-line comments first
    var result = content.replaceAll(_multiLineCommentRegex, '');
    // Then remove single-line comments
    result = result.replaceAll(_singleLineCommentRegex, '');
    return result;
  }

  /// Searches for a library file with the given library name.
  ///
  /// Looks for files in the same directory as the part file that might
  /// contain a `library` directive with the matching name.
  ///
  /// This is a heuristic for legacy `part of library.name;` syntax.
  /// Returns the first matching file, or `null` if no match found.
  static Future<String?> _findLibraryByName(
    String libraryName,
    String partFilePath,
  ) async {
    try {
      final partDir = path.dirname(partFilePath);
      final dir = Directory(partDir);

      if (!await dir.exists()) {
        return null;
      }

      // List all .dart files in the same directory
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          // Skip the part file itself
          if (entity.path == partFilePath) {
            continue;
          }

          // Check if this file declares the library
          try {
            final content = await entity.readAsString();
            final withoutComments = _removeComments(content);

            // Match `library library.name;` directive
            final libRegex = RegExp(
              r'^\s*library\s+' + RegExp.escape(libraryName) + r'\s*;',
              multiLine: true,
            );

            if (libRegex.hasMatch(withoutComments)) {
              return entity.path;
            }
          } catch (e) {
            // Skip files that can't be read
            continue;
          }
        }
      }

      return null; // No matching library found
    } catch (e) {
      return null;
    }
  }
}
