/// Metadata about a Dart part file and its relationship to its parent library.
///
/// This class represents information extracted from a part file's `part of`
/// directive and is used during analysis to resolve part files within their
/// parent library context.
class PartFileInfo {
  /// Absolute path to the part file.
  final String partFilePath;

  /// Absolute path to the parent library file.
  ///
  /// This is `null` if the parent library could not be resolved (orphaned part).
  final String? parentLibraryPath;

  /// The raw `part of` directive extracted from the file.
  ///
  /// Examples:
  /// - `"part of 'user_model.dart';"`
  /// - `"part of my.library.name;"`
  final String partOfDirective;

  /// Creates a new [PartFileInfo] instance.
  PartFileInfo({
    required this.partFilePath,
    required this.partOfDirective,
    this.parentLibraryPath,
  });

  /// Whether this part file's parent library could not be resolved.
  ///
  /// A part file is considered orphaned if:
  /// - The parent file specified in the `part of` directive doesn't exist
  /// - The `part of` directive is malformed
  /// - The library identifier (legacy syntax) cannot be resolved
  bool get isOrphaned => parentLibraryPath == null;

  /// Whether this part file has a resolved parent.
  bool get hasParent => parentLibraryPath != null;

  @override
  String toString() {
    return 'PartFileInfo(partFilePath: $partFilePath, '
        'parentLibraryPath: $parentLibraryPath, '
        'isOrphaned: $isOrphaned)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PartFileInfo &&
        other.partFilePath == partFilePath &&
        other.parentLibraryPath == parentLibraryPath &&
        other.partOfDirective == partOfDirective;
  }

  @override
  int get hashCode {
    return partFilePath.hashCode ^ parentLibraryPath.hashCode ^ partOfDirective.hashCode;
  }
}
