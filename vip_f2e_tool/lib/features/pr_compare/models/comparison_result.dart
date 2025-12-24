import 'pr_info.dart';

class ComparisonResult {
  final List<PrInfo> stagingPrs;
  final PrInfo prodPr;
  final Set<String> stagingCommits;
  final Set<String> prodCherryPickSources;
  final Set<String> inStagingNotInProd;
  final Set<String> inProdNotInStaging;

  ComparisonResult({
    required this.stagingPrs,
    required this.prodPr,
    required this.stagingCommits,
    required this.prodCherryPickSources,
    required this.inStagingNotInProd,
    required this.inProdNotInStaging,
  });

  bool get isMatch =>
      inStagingNotInProd.isEmpty && inProdNotInStaging.isEmpty;

  String toMarkdown() {
    final buffer = StringBuffer();

    buffer.writeln('## 🔍 PR Commit 比對結果');
    buffer.writeln();

    // Summary table
    buffer.writeln('| 項目 | 數量 |');
    buffer.writeln('|------|------|');
    buffer.writeln('| Staging PRs | ${stagingPrs.length} 個 |');
    buffer.writeln('| Staging Commits | ${stagingCommits.length} 個 |');
    buffer.writeln('| Prod Commits | ${prodPr.commits.length} 個 |');
    buffer.writeln('| Prod Cherry-pick 來源 | ${prodCherryPickSources.length} 個 |');
    buffer.writeln();

    // Result
    if (isMatch) {
      buffer.writeln('### ✅ 比對結果：完全相同');
      buffer.writeln();
      buffer.writeln('所有 Staging commits 都已正確 cherry-pick 到 Prod。');
    } else {
      buffer.writeln('### ❌ 比對結果：不一致');
      buffer.writeln();

      if (inStagingNotInProd.isNotEmpty) {
        buffer.writeln('#### ⚠️ 在 Staging 但不在 Prod 的 commits (缺少):');
        buffer.writeln();
        buffer.writeln('```');
        for (final hash in inStagingNotInProd.toList()..sort()) {
          buffer.writeln(hash);
        }
        buffer.writeln('```');
        buffer.writeln();
      }

      if (inProdNotInStaging.isNotEmpty) {
        buffer.writeln('#### ⚠️ 在 Prod 但不在 Staging 的 commits (額外):');
        buffer.writeln();
        buffer.writeln('```');
        for (final hash in inProdNotInStaging.toList()..sort()) {
          buffer.writeln(hash);
        }
        buffer.writeln('```');
        buffer.writeln();
      }
    }

    // Details
    buffer.writeln('<details>');
    buffer.writeln('<summary>📋 詳細 Commit 列表</summary>');
    buffer.writeln();
    buffer.writeln('**Staging PRs Commits (供 cherry-pick 複製用):**');
    buffer.writeln();
    buffer.writeln('```');
    for (final pr in stagingPrs) {
      buffer.writeln('# PR #${pr.prNumber}');
      for (final commit in pr.commits) {
        buffer.writeln('(cherry picked from commit ${commit.oid.substring(0, 7)})');
      }
    }
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('**PR 統計:**');
    for (final pr in stagingPrs) {
      buffer.writeln('- #${pr.prNumber} (${pr.commits.length} commits)');
    }
    buffer.writeln('- Prod: #${prodPr.prNumber} (${prodPr.commits.length} commits)');
    buffer.writeln();
    buffer.writeln('</details>');

    return buffer.toString();
  }
}
