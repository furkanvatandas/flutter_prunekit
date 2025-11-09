# Flutter PruneKit

<p align="center">
  <img src="https://github.com/furkanvatandas/flutter_prunekit/blob/main/assets/prunekit_image.png?raw=true" alt="Flutter PruneKit" width="100%" >
</p>

[![Pub Version](https://img.shields.io/pub/v/flutter_prunekit.svg)](https://pub.dev/packages/flutter_prunekit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue.svg)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-Compatible-02569B.svg)](https://flutter.dev/)

<p align="start">
  <strong>Ship leaner Dart & Flutter apps by removing unused classes, methods, and variables.</strong>
</p>

---

## Why flutter_prunekit?

`flutter_prunekit` is a static analysis companion that finds unused declarations across your Dart and Flutter projects. The analyzer inspects classes, methods, top-level functions, parameters, local variables, mixins, enums, and extensions, helping you ship faster and maintain a lean codebase.

The CLI runs fully offline, requires zero configuration to get started, and is backed by an extensive automated test suite to keep detection noise low.

## ✨ Key Capabilities

- **Comprehensive coverage** – detects unused classes, enums, mixins, extensions, top-level functions, class/enum methods (instance & static), getters/setters, operators, parameters, pattern bindings, and local variables.
- **Precision-first analysis** – over 520 automated tests guard against false positives. Lifecycle hooks (`initState`, `dispose`, etc.) and override chains are respected when `@override` annotations are present.
- **Fast single-pass traversal** – optimized AST walking keeps run times short even on medium/large apps.
- **Flexible ignore strategies** – use `@keepUnused`, config-driven patterns, CLI excludes, or underscores.
- **Offline & cross-platform** – works on macOS, Linux, and Windows without talking to external services.

## ⚠️ Important Notes

Before removing code flagged by this tool, keep these best practices in mind:

1. **Manual verification is essential** – Always review suggestions before deletion. The analyzer cannot detect dynamic type usage (e.g., `dynamic`, `Map<String, dynamic>`), which is common in request/response models, JSON serialization, and reflection-based frameworks.

2. **Follow the recommended cleanup order** – Start with **classes and types** first, then move to **functions and methods**, and finally **variables**. This order minimizes cascading false positives as removing unused classes naturally eliminates their methods and fields.

3. **Use version control** – Always perform cleanup in a **separate branch** (e.g., `refactor/remove-dead-code`) so you can easily revert changes if needed. Run your full test suite before merging to catch any incorrectly removed code.

4. **Test before you delete** – Run your complete test suite after each batch of removals. Missing test coverage might mean the analyzer correctly identified unused code, or that you need more tests to verify the code is actually used.

5. **Incremental approach for large projects** – Don't try to clean everything at once. Break the work into smaller PRs (e.g., one module at a time) to make reviews easier and reduce the risk of breaking changes.

6. **Platform-specific code** – Be cautious with platform channels and native integrations. Code accessed via method channels or platform-specific implementations may not be detected by static analysis.

## 🔍 What It Detects

### ✅ Classes & Types

- Regular and abstract classes
- Enums
- Mixins
- Named extensions (unnamed extensions are grouped per file)

### ✅ Functions & Methods

- Top-level functions
- Instance and static methods (including factory constructors)
- Getters, setters, and operators
- Extension methods
- Lifecycle methods (`initState`, `dispose`, etc.) excluded automatically

### ✅ Variables & Parameters

- Local variables and pattern bindings
- Function, method, and constructor parameters
- Top-level variables and constants
- Catch clause variables (opt-in)
- Write-only detection for assigned-but-never-read variables

### ✅ Fields & Properties

- **Instance fields** – public and private fields in classes, enums, and mixins
- **Static fields** – const, final, and var class/enum fields
- **Getter-only properties** – computed properties without backing fields
- **Field-backed properties** – transitive detection when both field and getter/setter are unused
- **Write-only field detection** – fields assigned but never read
- **Enhanced enum fields** – instance and static fields in Dart 2.17+ enums
- **Mixin field tracking** – fields declared in mixins across application sites
- **Advanced patterns** – string interpolation (`$field`), cascade operations (`obj..field`), equality operators (`operator==`, `hashCode`), compound assignments (`+=`, `*=`, etc.)

## 🔜 Roadmap

- Smarter override detection without requiring explicit `@override`
- Unused type alias (`typedef`) detection
- Incremental analysis mode for large monorepos

Have an idea? [Open an issue](https://github.com/furkanvatandas/flutter_prunekit/issues)

---

## 📦 Installation

### Project (dev dependency)

```bash
dart pub add --dev flutter_prunekit
```

or manually in `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_prunekit: ^2.4.0
```

Then fetch dependencies:

```bash
dart pub get
```

### Global activation

```bash
dart pub global activate flutter_prunekit
```

## Quick Start & Configuration

### Run a Scan

Analyze the default `lib/` directory with the `unused_code` command:

```bash
dart run flutter_prunekit unused_code
```

If you installed globally:

```bash
flutter_prunekit unused_code
```

### Focus the Analysis

- `--verbose` surfaces per-file progress.
- `--json` emits machine-readable output.
- Combine `--only-types`, `--only-methods`, and `--only-variables` to focus on specific findings.

### Project Configuration

The analyzer respects `analysis_options.yaml` excludes automatically. For deeper control, create `flutter_prunekit.yaml` at your project root:

```yaml
# flutter_prunekit.yaml

exclude:
  - 'lib/legacy/**'
  - '**/generated/**'
  - '**/*.g.dart'

# Treat custom annotations as "keep" markers
ignore_annotations:
  - 'deprecated'
  - 'experimental'

# Ignore method patterns (glob syntax)
ignore_methods:
  - 'TestHelper.*'
  - '*Controller.dispose'
  - '_debug*'

# Variable & parameter patterns
ignore_variables:
  - 'debug*'
  - 'temp*'

ignore_parameters:
  - 'context'
  - '_*'

# Optional checks disabled by default
check_catch_variables: false
check_build_context_parameters: false
```

### Command-line Excludes

Use `--exclude` for quick experiments without touching configuration files:

```bash
dart run flutter_prunekit unused_code \
  --exclude 'lib/legacy/**' \
  --exclude '**/experimental_*.dart'
```

## Example Output

```text
═══ Flutter Dead Code Analysis ═══

⚠ Found 3 unused class declarations:

Classes: 2

  lib/models/old_user.dart:12
    OldUser

  lib/widgets/legacy_button.dart:8
    LegacyButton

Enums: 1

  lib/utils/deprecated_helper.dart:5
    DeprecatedStatus

⚠ Found 2 unused methods:

Instance Methods: 1

  UserService:
    lib/services/user_service.dart:23
      processLegacyUser

Top-Level Functions: 1

  lib/helpers/formatter.dart:45
    formatLegacyData

─── Summary ───

  Files analyzed: 156
  Type declarations analyzed: 89
  Unused type declarations: 3
  Type usage rate: 96.6%

  Methods analyzed: 234
  Unused methods: 2
  Method usage rate: 99.1%

  Variables analyzed: 612
  Unused variables: 0
  Variable usage rate: 100.0%

  Analysis time: 2.3s
```

> **Tip:** Exit code `1` signals unused declarations were found. Perfectly clean runs exit with `0`. Partial runs with fatal warnings exit with `2`.

---

## Command Reference

Run `flutter_prunekit unused_code --help` to see the full list of options. Highlights:

| Flag | Purpose | Notes |
|------|---------|-------|
| `--path <dir>` | Analyze specific paths | Repeatable; defaults to `lib/` when omitted. |
| `--exclude <pattern>` | Glob-based ignore | Evaluated after path resolution. |
| `--include-tests` | Include `test/` files | Disabled by default. |
| `--include-generated` | Scan generated code | Intended for `.g.dart`, `.freezed.dart`, etc. |
| `--ignore-analysis-options` | Skip analyzer excludes | Useful for one-off deep scans. |
| `--only-methods` | Skip class detection | Methods & variables are still analyzed. |
| `--only-types` | Analyze only classes, enums, mixins, and extensions | Combine with other `--only-*` flags when needed. |
| `--only-methods` | Analyze only functions and methods | Combine with other `--only-*` flags when needed. |
| `--only-variables` | Analyze only variables and parameters | Combine with other `--only-*` flags when needed. |
| `--json` | Emit JSON report | Matches CLI formatter schema. |
| `--quiet` | Reduce console noise | Outputs only findings. |
| `--verbose` | Per-file diagnostics | Great for CI troubleshooting. |

Omitting all `--only-*` flags runs the full analysis across types, methods, and variables.

### Command-line excludes

Use `--exclude` for quick experiments:

```bash
dart run flutter_prunekit \
  --exclude 'lib/legacy/**' \
  --exclude '**/experimental_*.dart'
```

## Ignoring Intentional Usages

Some code is meant to look unused (reflection, dynamic calls, DI). Choose the approach that fits best:

1. **`@keepUnused` annotation** – highest priority. Works on classes, methods, variables, and parameters.
2. **Configuration patterns** – add glob patterns to `flutter_prunekit.yaml` under `ignore_methods`, `ignore_variables`, or `ignore_parameters`.
3. **Underscore convention** – identifiers named `_` or prefixed with `_` are treated as intentionally unused.
4. **CLI excludes** – skip entire files/folders on the command line.

Combine these methods when necessary. Verbose mode logs why declarations were ignored to help fine-tune patterns.

## Detection Notes & Limitations

- **Override chains** – override detection relies on explicit `@override` annotations. Omitting the annotation may cause false positives.
- **Flutter lifecycle methods** – common hooks (`initState`, `dispose`, `build`, etc.) are automatically treated as used.
- **Dynamic or reflective access** – analyzer cannot prove usage; mark members with `@keepUnused` when accessed dynamically.
- **Unnamed extensions** – currently grouped under a synthetic identifier per file. Prefer named extensions for granular reports.
- **Generated code** – skipped by default. Use `--include-generated` when you want to scan generated outputs.

## CI & Automation

Add a script to your workflow to keep dead code out of main branches:

```yaml
# example GitHub Actions step
- name: Dead code audit
  run: dart run flutter_prunekit unused_code --include-generated --quiet
```

Exit code `1` will fail the job if any unused declarations remain.

## Contributing

We welcome feature requests, bug reports, documentation improvements, and pull requests. Please review [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

## Support

- Issues: [GitHub Issues](https://github.com/furkanvatandas/flutter_prunekit/issues)
- Discussions: [GitHub Discussions](https://github.com/furkanvatandas/flutter_prunekit/discussions)
- Email: <m.furkanvatandas@gmail.com>

If `flutter_prunekit` helped clean up your codebase, consider:

- ⭐ Starring the repo
- 🐦 Sharing on social media
- 📝 Writing a blog post about it

## License

MIT License - see [LICENSE](LICENSE) file for details.
