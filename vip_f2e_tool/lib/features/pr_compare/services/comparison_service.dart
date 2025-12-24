import '../models/pr_info.dart';
import '../models/comparison_result.dart';
import 'github_service.dart';

class ComparisonService {
  final GithubService _githubService = GithubService();

  Future<ComparisonResult> compare({
    required List<PrInfo> stagingPrs,
    required PrInfo prodPr,
    Function(String)? onProgress,
  }) async {
    // Fetch staging commits
    final stagingCommits = <String>{};
    for (var i = 0; i < stagingPrs.length; i++) {
      final pr = stagingPrs[i];
      onProgress?.call('Fetching Staging PR #${pr.prNumber} (${i + 1}/${stagingPrs.length})...');
      pr.commits = await _githubService.fetchPrCommits(pr);
      for (final commit in pr.commits) {
        stagingCommits.add(commit.oid);
      }
    }

    // Fetch prod commits
    onProgress?.call('Fetching Prod PR #${prodPr.prNumber}...');
    prodPr.commits = await _githubService.fetchPrCommits(prodPr);

    // Extract cherry-pick sources from prod (last one for each commit)
    final prodCherryPickSources = <String>{};
    for (final commit in prodPr.commits) {
      if (commit.lastCherryPickSource != null) {
        prodCherryPickSources.add(commit.lastCherryPickSource!);
      }
    }

    // Compare
    final inStagingNotInProd = stagingCommits.difference(prodCherryPickSources);
    final inProdNotInStaging = prodCherryPickSources.difference(stagingCommits);

    onProgress?.call('比對完成！');

    return ComparisonResult(
      stagingPrs: stagingPrs,
      prodPr: prodPr,
      stagingCommits: stagingCommits,
      prodCherryPickSources: prodCherryPickSources,
      inStagingNotInProd: inStagingNotInProd,
      inProdNotInStaging: inProdNotInStaging,
    );
  }
}
