# Changelog

All notable changes to this project will be documented in this file.

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

[2.0.0]: https://github.com/furkanvatandas/flutter_prunekit/releases/tag/v2.0.0
[1.1.1]: https://github.com/furkanvatandas/flutter_prunekit/releases/tag/v1.1.1
[1.0.0]: https://github.com/furkanvatandas/flutter_prunekit/releases/tag/v1.0.0
