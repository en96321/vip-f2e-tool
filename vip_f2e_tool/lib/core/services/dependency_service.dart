import 'dart:io';
import '../models/dependency.dart';

/// Service for checking system dependencies
class DependencyService {
  /// List of all dependencies required by the app
  static const List<Dependency> requiredDependencies = [
    Dependency(
      name: 'git',
      displayName: 'Git',
      checkCommand: 'git',
      installInstructions: 'xcode-select --install',
      isRequired: true,
    ),
    Dependency(
      name: 'gh',
      displayName: 'GitHub CLI',
      checkCommand: 'gh',
      installInstructions: 'brew install gh',
      postInstallInstructions: 'gh auth login',
      isRequired: true,
    ),
  ];

  /// Common paths for CLI tools
  static const List<String> _searchPaths = [
    '/opt/homebrew/bin',
    '/usr/local/bin',
    '/usr/bin',
    '/bin',
  ];

  /// Find the full path to a command
  Future<String?> findCommandPath(String command) async {
    // First check common paths directly
    for (final dir in _searchPaths) {
      final path = '$dir/$command';
      if (await File(path).exists()) {
        return path;
      }
    }
    
    // Fallback: try running 'which' with system PATH
    try {
      final result = await Process.run(
        '/usr/bin/which',
        [command],
        environment: {
          'PATH': '${_searchPaths.join(':')}:${Platform.environment['PATH'] ?? ''}',
        },
      );
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (_) {}
    
    return null;
  }

  /// Check if a command exists in the system
  Future<bool> _commandExists(String command) async {
    return await findCommandPath(command) != null;
  }

  /// Get version of a command
  Future<String?> _getVersion(String command) async {
    try {
      final cmdPath = await findCommandPath(command);
      if (cmdPath == null) return null;
      
      final result = await Process.run(
        cmdPath,
        ['--version'],
      );
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        // Get first line only
        return output.split('\n').first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check a single dependency
  Future<DependencyCheckResult> checkDependency(Dependency dependency) async {
    final isInstalled = await _commandExists(dependency.checkCommand);
    String? version;
    
    if (isInstalled) {
      version = await _getVersion(dependency.checkCommand);
    }
    
    return DependencyCheckResult(
      dependency: dependency,
      isInstalled: isInstalled,
      version: version,
    );
  }

  /// Check all required dependencies
  Future<List<DependencyCheckResult>> checkAllDependencies() async {
    final results = <DependencyCheckResult>[];
    
    for (final dep in requiredDependencies) {
      final result = await checkDependency(dep);
      results.add(result);
    }
    
    return results;
  }

  /// Check if all required dependencies are installed
  Future<bool> areAllDependenciesInstalled() async {
    final results = await checkAllDependencies();
    return results.every((r) => r.isInstalled || !r.dependency.isRequired);
  }

  /// Get list of missing dependencies
  Future<List<DependencyCheckResult>> getMissingDependencies() async {
    final results = await checkAllDependencies();
    return results.where((r) => !r.isInstalled && r.dependency.isRequired).toList();
  }
}
