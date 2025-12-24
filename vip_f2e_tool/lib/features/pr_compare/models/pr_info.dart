class PrInfo {
  final String owner;
  final String repo;
  final int prNumber;
  final String url;
  List<CommitInfo> commits;

  PrInfo({
    required this.owner,
    required this.repo,
    required this.prNumber,
    required this.url,
    this.commits = const [],
  });

  String get fullRepo => '$owner/$repo';

  static PrInfo? fromUrl(String url) {
    // Parse: https://github.com/owner/repo/pull/123
    final regex = RegExp(r'github\.com/([^/]+)/([^/]+)/pull/(\d+)');
    final match = regex.firstMatch(url);
    if (match == null) return null;

    return PrInfo(
      owner: match.group(1)!,
      repo: match.group(2)!,
      prNumber: int.parse(match.group(3)!),
      url: url,
    );
  }
}

class CommitInfo {
  final String oid;
  final String messageHeadline;
  final String messageBody;
  final List<String> cherryPickSources;

  CommitInfo({
    required this.oid,
    required this.messageHeadline,
    required this.messageBody,
    required this.cherryPickSources,
  });

  /// Get the last cherry-pick source (from staging to prod)
  String? get lastCherryPickSource =>
      cherryPickSources.isNotEmpty ? cherryPickSources.last : null;

  factory CommitInfo.fromJson(Map<String, dynamic> json) {
    final body = json['messageBody'] as String? ?? '';
    final regex = RegExp(r'\(cherry picked from commit ([a-f0-9]+)\)');
    final matches = regex.allMatches(body);
    final sources = matches.map((m) => m.group(1)!).toList();

    return CommitInfo(
      oid: json['oid'] as String,
      messageHeadline: json['messageHeadline'] as String? ?? '',
      messageBody: body,
      cherryPickSources: sources,
    );
  }
}
