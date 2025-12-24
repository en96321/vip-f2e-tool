import 'dart:convert';
import 'dart:io';
import '../models/pr_info.dart';

class GithubService {
  Future<String?> findGhPath() async {
    final paths = [
      '/opt/homebrew/bin/gh',
      '/usr/local/bin/gh',
      '/usr/bin/gh',
    ];

    for (final path in paths) {
      if (await File(path).exists()) {
        return path;
      }
    }

    // Try which
    try {
      final result = await Process.run('which', ['gh']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (_) {}

    return null;
  }

  Future<bool> isGhInstalled() async {
    return await findGhPath() != null;
  }

  Future<List<CommitInfo>> fetchPrCommits(PrInfo pr) async {
    final ghPath = await findGhPath();
    if (ghPath == null) {
      throw Exception('gh CLI not found');
    }

    final result = await Process.run(
      ghPath,
      [
        'pr', 'view', pr.prNumber.toString(),
        '--repo', pr.fullRepo,
        '--json', 'commits',
      ],
      environment: {
        'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin',
      },
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to fetch PR #${pr.prNumber}: ${result.stderr}');
    }

    final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final commits = (json['commits'] as List<dynamic>)
        .map((c) => CommitInfo.fromJson(c as Map<String, dynamic>))
        .toList();

    return commits;
  }
}
