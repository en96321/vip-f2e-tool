/// Represents a system dependency required by the app
class Dependency {
  final String name;
  final String displayName;
  final String checkCommand;
  final String installInstructions;
  final String? postInstallInstructions;
  final bool isRequired;

  const Dependency({
    required this.name,
    required this.displayName,
    required this.checkCommand,
    required this.installInstructions,
    this.postInstallInstructions,
    this.isRequired = true,
  });

  @override
  String toString() => 'Dependency($name)';
}

/// Result of checking a dependency
class DependencyCheckResult {
  final Dependency dependency;
  final bool isInstalled;
  final String? version;
  final String? errorMessage;

  const DependencyCheckResult({
    required this.dependency,
    required this.isInstalled,
    this.version,
    this.errorMessage,
  });
}
