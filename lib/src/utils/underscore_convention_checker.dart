/// Utility for handling Dart's single-underscore "intentionally unused" convention.
class UnderscoreConventionChecker {
  const UnderscoreConventionChecker();

  /// Returns true when a variable name is intentionally unused.
  bool isIntentionallyUnused(String name) => name == '_';
}
