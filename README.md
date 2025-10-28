<p align="center">
  <img src="https://github.com/furkanvatandas/flutter_prunekit/blob/main/assets/prunekit_image.png?raw=true" alt="Flutter PruneKit" width="100%" >
</p>

# flutter_prunekit

🎯 Find and remove dead (unused) code in Dart & Flutter projects — classes, enums, mixins, extensions, methods and more.

[![Pub Version](https://img.shields.io/pub/v/flutter_prunekit.svg)](https://pub.dev/packages/flutter_prunekit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue.svg)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-Compatible-02569B.svg)](https://flutter.dev/)

Short, fast, zero-config static analysis to detect dead code and help keep your codebase small and maintainable.

[Highlights](#-highlights) • [Installation](#-installation) • [Quick Start](#-quick-start) • [Documentation](#-usage-guide)

---

## 🚀 Why flutter_prunekit?

Dead code bloats your app, confuses developers, and slows down builds. **flutter_prunekit** uses advanced static analysis to find unused classes, enums, mixins, and extensions—so you can ship faster, cleaner code.

## ✨ Highlights

- 🎯 High precision results backed by 370+ automated tests and production pilots (last validated Oct 2024).
- ⚡ Analysis finishes in seconds for medium Flutter apps thanks to parallel AST traversal.
- 🧠 Understands modern Dart features: extensions, mixins, part files, generics, override chains.
- 🛠️ Zero-config defaults with flexible ignore annotations, config, and glob patterns.
- 🌍 Offline CLI that runs on macOS, Linux, and Windows with no external services.

## 🔍 What it Detects

**Classes & Types:**

- ✅ **Classes** - Regular and abstract classes
- ✅ **Enums** - All enum declarations
- ✅ **Mixins** - Mixin declarations
- ✅ **Extensions** - Named and unnamed extensions with full semantic analysis
  - Extension methods, getters, operators
  - Cross-file extension usage tracking
  - Generic type-parameterized extensions

**Functions & Methods:** 🆕

- ✅ **Top-level Functions** - Global function declarations
- ✅ **Instance Methods** - Class and enum instance methods with override detection
- ✅ **Static Methods** - Class and enum static methods and factory constructors
- ✅ **Extension Methods** - Methods on extension types
- ✅ **Getters & Setters** - Property accessors (both top-level, class-level, and enum-level)
- ✅ **Operators** - Overloaded operators (`+`, `==`, `[]`, etc.)
- ✅ **Private Methods** - Unused private methods detection
- ✅ **Lifecycle Methods** - Automatic exclusion of Flutter lifecycle methods (`initState`, `dispose`, etc.)

### 🚀 Coming Soon (Roadmap)

We're actively working on detecting unused:

- 🔜 **Fields & Properties** - Unused class fields
- 🔜 **Variables** - Unused top-level and local variables
- 🔜 **Type aliases** - Unused typedef declarations
- 🔜 **Constructor parameters** - Unused named parameters

Want a feature? [Open an issue](https://github.com/furkanvatandas/flutter_prunekit/issues)!

## 📦 Installation

### Option 1: Add to Your Project (Recommended)

```bash
dart pub add --dev flutter_prunekit
```

Or manually add to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_prunekit: ^2.0.0
```

Then run:

```bash
dart pub get
```

### Option 2: Global Installation

```bash
dart pub global activate flutter_prunekit
```

## 🚀 Quick Start

### Basic Usage

```bash
# Analyze your project (scans lib/ by default)
dart run flutter_prunekit

# Or if globally installed
flutter_prunekit
```

**That's it!** The tool will scan your code and show you any unused classes, enums, mixins, or extensions.

### Example Output

```text
═══ Flutter Dead Code Analysis ═══

⚠ Found 5 unused declaration(s):

Classes: 2
Enums: 1

  lib/models/old_user.dart:12
    OldUser

  lib/widgets/legacy_button.dart:8
    LegacyButton

  lib/utils/deprecated_helper.dart:5
    DeprecatedStatus

Top-Level Functions: 1

  lib/helpers/formatter.dart:45
    formatLegacyData

Instance Methods: 1

  UserService (lib/services/user_service.dart:23)
    processLegacyUser [instance]

─── Summary ───

  Files analyzed: 156
  Total declarations: 89
  Total methods: 234
  Unused: 5
  Class usage rate: 96.6%
  Method usage rate: 99.1%

  Analysis time: 2.3s
```

### Programmatic Usage

Prefer to drive the analyzer from Dart code? Check out `example/basic_usage.dart`
for a minimal script that wires together the public APIs to scan any project
directory. Running it without arguments analyzes the bundled sample project:

```bash
dart run example/basic_usage.dart
```

This points the analyzer at `example/sample_project`, which deliberately contains
unused classes, mixins, enums, and extensions so you can see the tool in action.

## 🛠️ CLI Reference

| Flag | Description | Default / Notes |
|------|-------------|-----------------|
| `--path <dir>` | Analyze specific directories instead of auto-detecting `lib/`. | Repeatable; accepts globs. |
| `--exclude <pattern>` | Ignore paths that match a glob (e.g. `lib/legacy/**`). | Evaluated after `--path`. |
| `--json` | Emit the full analysis report in JSON (matches formatter schema). | Returns both class & method findings unless `--only-methods`. |
| `--only-methods` | Skip class detection and report methods/functions only. | Useful when classes are already clean. |
| `--include-tests` | Analyze `test/` alongside `lib/`. | Default is disabled. |
| `--include-generated` | Opt-in to scanning generated files (e.g. `.g.dart`). | Works with `flutter_prunekit.yaml` excludes. |
| `--ignore-analysis-options` | Ignore excludes from `analysis_options.yaml`. | Handy for temporary deep scans. |
| `--quiet` | Suppress banners and summaries; outputs only findings. | Helpful for CI logs. |
| `--verbose` | Print per-file progress and timing. | Pair with CI to debug slow runs. |
| `--help` / `-h` | Show the full help text with all options. | Does not run analysis. |
| `--version` | Print the current package version. | Exits immediately. |

## 📖 Usage Guide

### Common Scenarios

```bash
# Scope the scan
dart run flutter_prunekit --path packages/core/lib

# Exclude legacy modules
dart run flutter_prunekit --exclude 'lib/legacy/**'

# Include tests and generated code for a deep audit
dart run flutter_prunekit --include-tests --include-generated

# Debug a slow analysis
dart run flutter_prunekit --verbose
```

## ⚙️ Configuration

### Method 1: Config File (Recommended)

Create `flutter_prunekit.yaml` in your project root:

```yaml
# Exclude entire directories or specific files
exclude:
  - 'lib/legacy/**'           # All files in legacy folder
  - 'lib/generated/**'        # Generated code folder
  - '**/old_*.dart'          # Files starting with 'old_'
  - 'lib/deprecated.dart'    # Specific file

# Custom annotations to treat as "keep" markers
ignore_annotations:
  - 'deprecated'    # Classes with @deprecated won't be flagged
  - 'experimental'  # Your custom @experimental annotation
```

### Method 2: Use Existing analysis_options.yaml

The tool automatically respects your analyzer excludes:

```yaml
analyzer:
  exclude:
    - 'lib/generated/**'
    - '**/*.g.dart'
    - '**/*.freezed.dart'
```

No additional configuration needed!

## 🎯 Ignoring False Positives

Sometimes you need to keep code that appears unused (reflection, dynamic loading, etc.). Here's how:

### Ignore Priority Order

When multiple ignore methods conflict:

1. **`@keepUnused` annotation** (highest)
2. **`flutter_prunekit.yaml` patterns**
3. **`--exclude` CLI flag** (lowest)

### Option 1: Annotate Specific Classes & Methods ⭐ Recommended

Perfect for individual classes or methods that should never be removed:

```dart
@keepUnused  // ← Add this annotation
class LegacyWidget extends StatelessWidget {
  // Won't be flagged as unused
}

@keepUnused
mixin ReflectionMixin {
  // Used via reflection - keep it!
}

@keepUnused
enum PlatformStatus { active, inactive }

@keepUnused
extension StringHelpers on String {
  // Extension used in other packages
}

class Calculator {
  @keepUnused  // Method-level annotation
  int complexCalculation() {
    // Used via reflection or dynamic invocation
    return 42;
  }
  
  int simpleAdd(int a, int b) => a + b;  // Normal method
}
```

### Option 2: Pattern-Based Exclusion

Use config file for excluding multiple files or specific methods:

```yaml
# flutter_prunekit.yaml
exclude:
  - 'lib/legacy/**'              # Entire folder
  - '**/experimental_*.dart'     # Name pattern
  - 'lib/platform_specific.dart' # Single file

# Ignore specific methods by pattern
ignore_methods:
  - 'test*'                 # Ignore all test helper methods
  - '_internal*'            # Ignore internal methods
  - 'TestHelper.*'          # Ignore all TestHelper methods
  - '*.cleanup'             # Ignore cleanup in any class
  - 'debugPrint'            # Ignore specific method
```

### Option 3: Runtime Exclusion (Temporary)

Use CLI flags for one-off analyses:

```bash
# Test excluding certain code
dart run flutter_prunekit --exclude 'lib/legacy/**' --exclude '**/old_*.dart'
```

### ⚠️ Known Limitations (Edge Cases)

These are rare but worth knowing:

#### 1. Dynamic Type Usage

```dart
dynamic obj = getObject();
obj.method(); // ⚠️ Cannot statically determine class type
```

**Solution:** Avoid `dynamic` where possible, or use `@keepUnused`

#### 2. Reflection & Mirrors

```dart
Type type = reflectClass(MyClass); // ⚠️ Runtime-only reference
```

**Solution:** Add `@keepUnused` to reflected classes

#### 3. Conditional Imports (Platform-Specific Code)

```dart
import 'stub.dart' 
  if (dart.library.io) 'io_impl.dart'
  if (dart.library.html) 'web_impl.dart';
```

**Solution:** Annotate platform-specific classes with `@keepUnused`

#### 4. Unnamed Extensions (Analyzer API Limitation)

```dart
// If ANY unnamed extension is used, ALL get marked as used
extension on String { ... }  // Shares identifier with below
extension on int { ... }     // Shares identifier with above
```

**Solution:** Use named extensions for better tracking:

```dart
extension StringHelpers on String { ... }
extension IntHelpers on int { ... }
```

## 🏗️ Code Generation Support

### ✅ Fully Supported

- **Freezed** - `*.freezed.dart` part files fully analyzed
- **Realm** - `*.realm.dart` with `$Model` / `_Model` pattern
- **json_serializable** - `*.g.dart` files
- **built_value** - Generated builders and serializers

### How It Works

By default, generated files are **excluded** (recommended). Use `--include-generated` to analyze them:

```bash
# Include generated code in analysis
dart run flutter_prunekit --include-generated
```

⚠️ **Note:** Generated classes may appear unused if only referenced in other generated code. This is usually safe to ignore.

**Best Practice:** Run analysis both with and without `--include-generated` to understand your codebase.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/furkanvatandas/flutter_prunekit.git
cd flutter_prunekit

# Install dependencies
dart pub get

# Run the tool locally
dart run bin/flutter_prunekit.dart --path lib
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 💬 Support & Community

- 🐛 **Issues:** [GitHub Issues](https://github.com/furkanvatandas/flutter_prunekit/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/furkanvatandas/flutter_prunekit/discussions)

## ⭐ Show Your Support

If `flutter_prunekit` helped clean up your codebase, consider:

- ⭐ Starring the repo
- 🐦 Sharing on social media
- 📝 Writing a blog post about it
