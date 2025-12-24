import 'dart:convert';

class RepoConfig {
  final String owner;
  final String repo;
  final String branch;

  RepoConfig({
    required this.owner,
    required this.repo,
    required this.branch,
  });

  /// Parse from string format
  /// Supports: "owner/repo/branch" or "owner/repo/tree/branch" (from GitHub URL)
  factory RepoConfig.fromString(String input) {
    // Clean up input - remove GitHub URL prefix if present
    var cleaned = input.trim();
    cleaned = cleaned.replaceAll('https://github.com/', '');
    cleaned = cleaned.replaceAll('http://github.com/', '');
    cleaned = cleaned.replaceAll(RegExp(r'^github\.com/'), '');
    
    final parts = cleaned.split('/');
    if (parts.length < 3) {
      throw FormatException('Invalid repo format. Expected: owner/repo/branch');
    }
    
    final owner = parts[0];
    final repo = parts[1];
    
    // Handle "tree/branch" or just "branch"
    String branch;
    if (parts.length >= 4 && parts[2] == 'tree') {
      // Format: owner/repo/tree/branch-name
      branch = parts.sublist(3).join('/');
    } else {
      // Format: owner/repo/branch-name
      branch = parts.sublist(2).join('/');
    }
    
    return RepoConfig(
      owner: owner,
      repo: repo,
      branch: branch,
    );
  }

  /// Convert to string format: "owner/repo/branch"
  @override
  String toString() => '$owner/$repo/$branch';

  /// Display name for UI
  String get displayName => '$owner/$repo';

  /// Full GitHub URL
  String get githubUrl => 'https://github.com/$owner/$repo/tree/$branch';

  /// GitHub slug for RedPen CI
  String get slug => '$owner/$repo';

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'repo': repo,
        'branch': branch,
      };

  factory RepoConfig.fromJson(Map<String, dynamic> json) => RepoConfig(
        owner: json['owner'] as String,
        repo: json['repo'] as String,
        branch: json['branch'] as String,
      );

  static String encodeList(List<RepoConfig> repos) =>
      jsonEncode(repos.map((r) => r.toJson()).toList());

  static List<RepoConfig> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => RepoConfig.fromJson(e)).toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepoConfig &&
          owner == other.owner &&
          repo == other.repo &&
          branch == other.branch;

  @override
  int get hashCode => Object.hash(owner, repo, branch);
}
