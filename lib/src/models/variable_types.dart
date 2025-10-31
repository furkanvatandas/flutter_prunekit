/// Enumerations used for variable tracking models.
///
/// These enums live in a dedicated file to avoid cyclical imports between
/// declarations, references, and scope context models.
library;

/// The kind of variable being analyzed.
enum VariableType {
  /// Variable declared inside a function or method body.
  local,

  /// Parameter declared on a function or method.
  parameter,

  /// Variable declared at the top level of a file.
  topLevel,

  /// Variable declared inside a catch clause.
  catchClause,
}

/// Mutability of a variable declaration.
enum Mutability {
  /// Compile-time constant (`const`).
  const_,

  /// Runtime constant (`final`).
  final_,

  /// Mutable variable (`var` or explicit type without const/final).
  mutable,
}

/// How a variable is referenced at a given location.
enum ReferenceType {
  /// Variable value is read.
  read,

  /// Variable value is written/assigned.
  write,

  /// Variable is both read and written (e.g., `x += 1`).
  readWrite,
}

/// Context in which a variable reference occurs.
enum ReferenceContext {
  /// General expression usage.
  expression,

  /// Assignment or mutation target.
  assignment,

  /// String interpolation (e.g., `'Hello $name'`).
  stringInterpolation,

  /// Captured inside a closure.
  closure,

  /// Await expression or async callback.
  asyncContext,

  /// Pattern matching construct.
  patternMatch,

  /// Usage inside an assert statement.
  assertStatement,

  /// Usage inside a return statement.
  returnStatement,
}

/// Kind of lexical scope currently being traversed.
enum ScopeType {
  /// Top-level function scope.
  function,

  /// Class or extension method scope.
  method,

  /// General block scope (if/for/while/etc.).
  block,

  /// Closure or anonymous function scope.
  closure,

  /// Catch block scope.
  catchBlock,
}

/// Kind of parameter encountered in a callable declaration.
enum ParameterKind {
  /// Required positional parameter.
  required,

  /// Optional positional parameter.
  optionalPositional,

  /// Named parameter.
  named,
}

/// Which variable slot inside a catch clause is being represented.
enum CatchVariableType {
  /// Exception variable (first argument in `catch`).
  exception,

  /// Stack trace variable (second argument in `catch`).
  stackTrace,
}

/// Pattern construct that produced a variable binding.
enum PatternType {
  /// List pattern (`var [a, b] = list`).
  list,

  /// Record pattern (`var (x, y) = record`).
  record,

  /// Object pattern (`var Foo(:bar) = obj`).
  object,

  /// Switch case pattern (`case (x, y):`).
  switchCase,

  /// Destructuring pattern (`var [first, ...rest] = items`).
  destructuring,

  /// Map pattern (`var {'key': value} = map`).
  map,
}
