/// Environment configuration for cherry-pick operations
class Environment {
  final String name;
  final String baseBranch;
  final String defaultSource;
  final String defaultTarget;
  final String description;

  const Environment({
    required this.name,
    required this.baseBranch,
    required this.defaultSource,
    required this.defaultTarget,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'baseBranch': baseBranch,
        'defaultSource': defaultSource,
        'defaultTarget': defaultTarget,
        'description': description,
      };

  factory Environment.fromJson(Map<String, dynamic> json) => Environment(
        name: json['name'] as String,
        baseBranch: json['baseBranch'] as String,
        defaultSource: json['defaultSource'] as String,
        defaultTarget: json['defaultTarget'] as String,
        description: json['description'] as String,
      );
}

/// Predefined environments
class Environments {
  static const staging = Environment(
    name: 'staging',
    baseBranch: 'staging',
    defaultSource: 'lab',
    defaultTarget: 'to-staging',
    description: '一般開發環境',
  );

  static const production = Environment(
    name: 'production',
    baseBranch: 'production',
    defaultSource: 'staging',
    defaultTarget: 'to-production',
    description: 'Production 環境',
  );

  static const List<Environment> all = [staging, production];

  static Environment? byName(String name) {
    try {
      return all.firstWhere((e) => e.name == name);
    } catch (_) {
      return null;
    }
  }
}
