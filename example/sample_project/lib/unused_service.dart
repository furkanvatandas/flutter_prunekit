class LegacyService {
  void runLegacyProcess() {
    // Pretend to do legacy work.
  }
}

mixin UnusedMixin {
  void apply() {}
}

enum DeprecatedVariant {
  first,
  second,
}

extension DebugHelper on String {
  String withDebugPrefix() => '[DEBUG] $this';
}
