import 'class_declaration.dart';
import 'class_reference.dart';
import 'method_declaration.dart';
import 'method_invocation.dart';
import 'variable_declaration.dart';
import 'variable_reference.dart';
import 'variable_types.dart';

/// Represents the complete reference graph of the codebase.
///
/// This graph maps all class declarations to their references, enabling
/// efficient unused class detection.
///
/// **Phase 2 Enhancement (T007)**: Extended to support method-level tracking
/// for detecting unused methods/functions alongside unused classes.
///
/// **Performance Optimization (T071)**: String interning is used for file paths
/// to reduce memory usage. File paths are repeated many times in references,
/// so interning them saves significant memory on large codebases.
class ReferenceGraph {
  /// All class declarations found in the codebase.
  ///
  /// Key: uniqueId (packageRelativePath#ClassName)
  /// Value: ClassDeclaration
  final Map<String, ClassDeclaration> declarations;

  /// All references found in the codebase.
  ///
  /// Key: className
  /// Value: List of all references to that class
  final Map<String, List<ClassReference>> references;

  /// All method/function declarations found in the codebase (T007).
  ///
  /// Key: uniqueId (filePath#[ClassName.]methodName)
  /// Value: MethodDeclaration
  final Map<String, MethodDeclaration> methodDeclarations;

  /// All method/function invocations found in the codebase (T007).
  ///
  /// Key: method name
  /// Value: List of all invocations to that method
  final Map<String, List<MethodInvocation>> methodInvocations;

  /// All variable declarations tracked for unused-variable analysis.
  ///
  /// Key: declaration id (filePath#scopeId#name)
  /// Value: VariableDeclaration
  final Map<String, VariableDeclaration> variableDeclarations;

  /// All variable references encountered during analysis.
  ///
  /// Key: variableId
  /// Value: List of references to that variable
  final Map<String, List<VariableReference>> variableReferences;

  /// String interning pool for file paths (T071).
  ///
  /// File paths are repeated many times (once per reference), so we intern
  /// them to reduce memory usage. On a project with 10k references and 100
  /// unique files, this saves ~500KB of string data.
  final Map<String, String> _pathInternPool = {};

  /// Creates a new reference graph.
  ReferenceGraph({
    required this.declarations,
    required this.references,
    Map<String, MethodDeclaration>? methodDeclarations,
    Map<String, List<MethodInvocation>>? methodInvocations,
    Map<String, VariableDeclaration>? variableDeclarations,
    Map<String, List<VariableReference>>? variableReferences,
  })  : methodDeclarations = methodDeclarations ?? {},
        methodInvocations = methodInvocations ?? {},
        variableDeclarations = variableDeclarations ?? {},
        variableReferences = variableReferences ?? {};

  /// Creates an empty reference graph.
  ReferenceGraph.empty()
      : declarations = {},
        references = {},
        methodDeclarations = {},
        methodInvocations = {},
        variableDeclarations = {},
        variableReferences = {};

  /// Interns a file path to reduce memory usage (T071).
  ///
  /// Returns the interned string if it already exists in the pool,
  /// otherwise adds it to the pool and returns it.
  String _internPath(String path) {
    return _pathInternPool.putIfAbsent(path, () => path);
  }

  /// Adds a class declaration to the graph.
  void addDeclaration(ClassDeclaration declaration) {
    declarations[declaration.uniqueId] = declaration;
  }

  /// Adds a class reference to the graph.
  ///
  /// Automatically interns the file path to reduce memory usage (T071).
  void addReference(ClassReference reference) {
    // Intern the file path to save memory
    final internedPath = _internPath(reference.sourceFile);

    // Create a new reference with the interned path if different
    final internedReference =
        internedPath == reference.sourceFile ? reference : reference.copyWith(sourceFile: internedPath);

    references.putIfAbsent(reference.className, () => []).add(internedReference);
  }

  /// Adds a method declaration to the graph (T007).
  void addMethodDeclaration(MethodDeclaration declaration) {
    methodDeclarations[declaration.uniqueId] = declaration;
  }

  /// Adds a method invocation to the graph (T007).
  ///
  /// Automatically interns the file path to reduce memory usage.
  void addMethodInvocation(MethodInvocation invocation) {
    // Intern the file path to save memory
    final internedPath = _internPath(invocation.filePath);
    final declarationPath = invocation.declarationFilePath;
    final internedDeclarationPath = declarationPath != null ? _internPath(declarationPath) : null;

    // Create a new invocation with the interned path if different
    final needsCopy = internedPath != invocation.filePath || internedDeclarationPath != invocation.declarationFilePath;
    final internedInvocation = needsCopy
        ? MethodInvocation(
            methodName: invocation.methodName,
            targetClass: invocation.targetClass,
            declarationFilePath: internedDeclarationPath,
            filePath: internedPath,
            lineNumber: invocation.lineNumber,
            invocationType: invocation.invocationType,
            isDynamic: invocation.isDynamic,
            isCommentReference: invocation.isCommentReference,
            isTearOff: invocation.isTearOff,
          )
        : invocation;

    methodInvocations.putIfAbsent(invocation.methodName, () => []).add(internedInvocation);
  }

  /// Adds a variable declaration to the graph.
  void addVariableDeclaration(VariableDeclaration declaration) {
    variableDeclarations[declaration.id] = declaration;
  }

  /// Adds a variable reference to the graph, interning file paths for memory efficiency.
  void addVariableReference(VariableReference reference) {
    final internedPath = _internPath(reference.filePath);
    final needsCopy = internedPath != reference.filePath;
    final internedReference = needsCopy
        ? VariableReference(
            id: reference.id,
            variableId: reference.variableId,
            filePath: internedPath,
            lineNumber: reference.lineNumber,
            columnNumber: reference.columnNumber,
            referenceType: reference.referenceType,
            context: reference.context,
            enclosingScope: reference.enclosingScope,
            isCapturedByClosure: reference.isCapturedByClosure,
          )
        : reference;

    variableReferences.putIfAbsent(reference.variableId, () => []).add(internedReference);
  }

  /// Returns all declarations that have no references.
  ///
  /// This is the core unused detection logic.
  List<ClassDeclaration> getUnusedDeclarations() {
    return declarations.values.where((declaration) {
      // Check if there are any references to this class
      final refs = references[declaration.name] ?? [];
      return refs.isEmpty;
    }).toList()
      ..sort((a, b) => a.uniqueId.compareTo(b.uniqueId)); // Deterministic order
  }

  /// Returns all variable declarations with zero read references (unused variables).
  List<VariableDeclaration> getUnusedVariableDeclarations() {
    return variableDeclarations.values.where((declaration) {
      final refs = variableReferences[declaration.id] ?? const [];
      final hasReadReference =
          refs.any((ref) => ref.referenceType == ReferenceType.read || ref.referenceType == ReferenceType.readWrite);
      return !hasReadReference;
    }).toList()
      ..sort((a, b) {
        final pathCompare = a.filePath.compareTo(b.filePath);
        if (pathCompare != 0) return pathCompare;
        return a.lineNumber.compareTo(b.lineNumber);
      });
  }

  /// Returns all method declarations that have no invocations (T007).
  ///
  /// Excludes:
  /// - Methods marked with @keepUnused annotation
  /// - Override methods (would break inheritance contract)
  /// - Lifecycle methods (called by framework)
  List<MethodDeclaration> getUnusedMethodDeclarations() {
    return methodDeclarations.values.where((declaration) {
      // Skip if marked with @keepUnused
      if (declaration.annotations.contains('keepUnused')) {
        return false;
      }

      // Skip if it's an override (would break inheritance)
      if (declaration.isOverride) {
        return false;
      }

      // T101: Skip abstract methods that have concrete overrides
      // Abstract methods are implemented by subclasses, so if there's any override
      // of this method name in the same class hierarchy, don't flag the abstract method
      if (declaration.isAbstract && declaration.containingClass != null) {
        // Check if any method with the same name has @override annotation
        // This indicates that the abstract method has been implemented
        final hasOverride = methodDeclarations.values
            .any((otherDecl) => otherDecl.name == declaration.name && otherDecl.isOverride && !otherDecl.isAbstract);
        if (hasOverride) {
          return false; // Abstract method has an implementation, don't flag it
        }
      }

      // Skip if it's a lifecycle method (called by framework)
      if (declaration.isLifecycleMethod) {
        return false;
      }

      // Check if there are any invocations to this method
      final invocations = methodInvocations[declaration.name] ?? [];

      if (invocations.isEmpty) {
        return true;
      }

      final hasMatchingInvocation = invocations.any((invocation) {
        // Require matching declaration file when available to avoid cross-file collisions
        if (invocation.declarationFilePath != null && invocation.declarationFilePath != declaration.filePath) {
          return false;
        }

        if (declaration.containingClass == null) {
          // Top-level function: declaration file already checked above
          return true;
        }

        final matchesContainingClass = invocation.targetClass == declaration.containingClass;
        final matchesExtensionTarget =
            declaration.extensionTargetType != null && invocation.targetClass == declaration.extensionTargetType;

        return matchesContainingClass || matchesExtensionTarget;
      });

      return !hasMatchingInvocation;
    }).toList()
      ..sort((a, b) => a.uniqueId.compareTo(b.uniqueId)); // Deterministic order
  }

  /// Returns the number of references for a given class name.
  int getReferenceCount(String className) {
    return references[className]?.length ?? 0;
  }

  /// Returns all references for a given class name.
  List<ClassReference> getReferences(String className) {
    return references[className] ?? [];
  }

  /// Returns the number of invocations for a given method name (T007).
  int getMethodInvocationCount(String methodName) {
    return methodInvocations[methodName]?.length ?? 0;
  }

  /// Returns all invocations for a given method name (T007).
  List<MethodInvocation> getMethodInvocations(String methodName) {
    return methodInvocations[methodName] ?? [];
  }

  /// Returns statistics about the reference graph.
  GraphStatistics getStatistics() {
    // T092: Count dynamic invocations
    final dynamicCount = methodInvocations.values.expand((invs) => invs).where((inv) => inv.isDynamic).length;

    final totalVariableRefs = variableReferences.values.fold<int>(0, (sum, refs) => sum + refs.length);

    return GraphStatistics(
      totalDeclarations: declarations.length,
      totalReferences: references.values.fold(0, (sum, refs) => sum + refs.length),
      unusedCount: getUnusedDeclarations().length,
      filesAnalyzed: _countUniqueFiles(),
      totalMethodDeclarations: methodDeclarations.length,
      totalMethodInvocations: methodInvocations.values.fold(0, (sum, invs) => sum + invs.length),
      unusedMethodCount: getUnusedMethodDeclarations().length,
      dynamicInvocationCount: dynamicCount, // T092
      totalVariableDeclarations: variableDeclarations.length,
      totalVariableReferences: totalVariableRefs,
      unusedVariableCount: getUnusedVariableDeclarations().length,
    );
  }

  int _countUniqueFiles() {
    final files = <String>{};
    for (final decl in declarations.values) {
      files.add(decl.filePath);
    }
    for (final refs in references.values) {
      for (final ref in refs) {
        files.add(ref.sourceFile);
      }
    }
    for (final variable in variableDeclarations.values) {
      files.add(variable.filePath);
    }
    for (final refs in variableReferences.values) {
      for (final ref in refs) {
        files.add(ref.filePath);
      }
    }
    return files.length;
  }
}

/// Statistics about a reference graph.
class GraphStatistics {
  /// Total number of class declarations found.
  final int totalDeclarations;

  /// Total number of references found.
  final int totalReferences;

  /// Number of unused classes detected.
  final int unusedCount;

  /// Number of unique files analyzed.
  final int filesAnalyzed;

  /// Total number of method/function declarations found (T007).
  final int totalMethodDeclarations;

  /// Total number of method invocations found (T007).
  final int totalMethodInvocations;

  /// Number of unused methods detected (T007).
  final int unusedMethodCount;

  /// Number of dynamic invocations detected (T092).
  final int dynamicInvocationCount;

  /// Total variable declarations tracked.
  final int totalVariableDeclarations;

  /// Total variable references encountered.
  final int totalVariableReferences;

  /// Number of variable declarations without read references.
  final int unusedVariableCount;

  /// Percentage of dynamic invocations (T092).
  double get dynamicInvocationPercentage {
    if (totalMethodInvocations == 0) return 0.0;
    return (dynamicInvocationCount / totalMethodInvocations) * 100;
  }

  /// Whether dynamic invocations exceed warning threshold (≥5%) (T092).
  bool get hasDynamicWarning => dynamicInvocationPercentage >= 5.0;

  GraphStatistics({
    required this.totalDeclarations,
    required this.totalReferences,
    required this.unusedCount,
    required this.filesAnalyzed,
    this.totalMethodDeclarations = 0,
    this.totalMethodInvocations = 0,
    this.unusedMethodCount = 0,
    this.dynamicInvocationCount = 0, // T092
    this.totalVariableDeclarations = 0,
    this.totalVariableReferences = 0,
    this.unusedVariableCount = 0,
  });
}
