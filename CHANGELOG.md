# Changelog

All notable changes to this project will be documented in this file.

# [2.3.0]

### Fixed

- Fixed Windows path normalization issue causing "Failed to parse file (syntax errors or invalid Dart code)" errors on Windows systems
- Enhanced cross-platform compatibility by properly handling native path separators in the analyzer wrapper
- Ensured all file paths are converted to absolute paths before analysis for consistent behavior across platforms

# [2.2.1]

### Fixed

- Corrected command name references in documentation from `flutter_dead_code` to `flutter_prunekit` in README.md, example configuration, and CLI help text
- Updated version string in CLI arguments to 2.2.1

# [2.2.0]

### Added

- Category-scoped analysis switches: `--only-types`, `--only-methods`, and `--only-variables` let you focus reports on a single surface or mix-and-match combinations for custom scans.

### Changed

- CLI workflow now runs through an explicit subcommand: use `flutter_prunekit unused_code [...]` for all analyses, with updated help/usage messaging and README guidance.
- Default configuration filename renamed to `flutter_prunekit.yaml`; all loaders, fixtures, and documentation now look for the new name.
- Quick Start documentation now integrates the configuration walkthrough and highlights exclusion patterns in a single, action-oriented section.

## [2.1.0]

#### What's New

- **Local variables** – detects unused variables inside functions, methods, getters, and blocks.
- **Parameters** – tracks unused function, method, constructor, and closure parameters.
- **Top-level variables** – flags unused globals and constants (including `late` and `const`).
- **For-loop variables** – monitors loop counters and iterator variables.
- **Catch variables** – reports unused exception and stack trace bindings.
- **Pattern bindings** – supports switch/if-case/destructuring patterns from Dart 3.
- **Write-only detection** – highlights variables that are assigned but never read.
- **Smart conventions** – honours `_` placeholders, `this.field` initialisers, and other intentional ignores.

#### Variable-Level Features

- **@keepUnused Annotation** - Variable-level ignore support:

  ```dart
  @keepUnused
  final config = loadFromReflection();
  
  void process() {
    @keepUnused
    final secretKey = Platform.environment['SECRET'];
  }
  ```

- **Config-based Patterns** - Flexible variable exclusion:

  ```yaml
  ignore_variables:
    - 'temp*'      # Ignore temporary variables
    - 'debug*'     # Ignore debug variables
    
  ignore_parameters:
    - 'context'    # Often required but unused
    - '_*'         # Intentionally unused
  ```

## [2.0.0]

### Added - Method Detection

**Complete method and function analysis** - The biggest feature since v1.0!

#### What's New

- **Top-level Functions** - Detects unused global functions
- **Instance Methods** - Tracks method usage including inherited calls (classes and enums)
- **Static Methods** - Factory constructors and static method detection (classes and enums)
- **Extension Methods** - Full extension method tracking with semantic resolution
- **Getters & Setters** - Property accessor detection (top-level, class-level, and enum-level)
- **Operators** - Overloaded operator tracking (`+`, `==`, `[]`, etc.)
- **Private Methods** - Unused private method detection
- **Override Detection** - Correctly handles `@override` and inheritance chains
- **Abstract Methods** - Smart handling of abstract methods with implementations
- **Lifecycle Methods** - Auto-excludes Flutter lifecycle methods (`initState`, `dispose`, `build`, etc.)
- **Enum Methods** - Full support for enum instance methods, static methods, getters, and setters

### Fixed

- Singleton property access (e.g., `Logger.instance.log()`) now correctly tracked
- Inherited method calls via implicit `this` properly detected
- Abstract methods with `@override` implementations not flagged
- Property chains across inheritance hierarchies resolved correctly

---

## [1.1.1]

### Added

- **Part file analysis** - Full support for `part` and `part of` directives with zero false positives
- **Cross-part references** - Correctly tracks class usage across part boundaries
- **Code generation support** - Works with Realm, Freezed, and other generators
- **Warning system** - Non-fatal warnings for part file issues with actionable suggestions
- **122 new tests** - Comprehensive part file test coverage (208 total tests)

### Fixed

- Realm `$ClassName` models no longer falsely reported when using `--include-generated`
- Freezed generated classes correctly detected across part boundaries
- Generated code in part files properly analyzed

---

## [1.0.0]

### Initial Release

Production-ready dead code analyzer for Dart & Flutter with **100% precision and 100% recall**.

### Core Features

- **Detects unused:** Classes, abstract classes, mixins, enums, extensions
- **Smart analysis:** Tracks instantiation, type annotations, inheritance, generics, static methods
- **Flexible ignoring:** `@keepUnused` annotation, config file patterns, CLI exclusions
- **Generated code aware:** Auto-excludes `*.g.dart`, `*.freezed.dart`, `*.realm.dart`
- **Fast:** <5s for 10k LOC, <30s for 50k LOC
- **Cross-platform:** macOS, Linux, Windows

---

[2.2.1]: https://github.com/furkanvatandas/flutter_prunekit/releases/tag/v2.2.1
[2.2.0]: https://github.com/furkanvatandas/flutter_prunekit/releases/tag/v2.2.0
[2.1.0]: https://github.com/furkanvatandas/flutter_prunekit/releases/tag/v2.1.0
[2.0.0]: https://github.com/furkanvatandas/flutter_prunekit/releases/tag/v2.0.0
[1.1.1]: https://github.com/furkanvatandas/flutter_prunekit/releases/tag/v1.1.1
[1.0.0]: https://github.com/furkanvatandas/flutter_prunekit/releases/tag/v1.0.0
