import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import '../models/commit.dart';
import '../models/environment.dart';
import '../models/progress.dart';
import 'git_service.dart';

/// Callback for logging messages during cherry-pick operations
typedef LogCallback = void Function(String message, LogLevel level);

enum LogLevel { info, success, warning, error }

/// Result of commit search
class CommitSearchResult {
  final String input;
  final String type; // 'ticket' or 'hash'
  final List<Commit> commits;

  CommitSearchResult({
    required this.input,
    required this.type,
    required this.commits,
  });
}

/// Manager for cherry-pick operations
class CherryPickManager {
  final GitService gitService;
  final List<String> tickets;
  final Environment environment;
  final String baseBranch;
  final String sourceBranch;
  final String targetBranch;
  final String ticketPrefix;
  final LogCallback? onLog;
  final VoidCallback? onStateChange;

  List<Commit> _allCommits = [];
  int _currentIndex = 0;

  CherryPickManager({
    required this.gitService,
    required this.tickets,
    required this.environment,
    String? baseBranch,
    String? sourceBranch,
    String? targetBranch,
    String? ticketPrefix,
    this.onLog,
    this.onStateChange,
  })  : baseBranch = baseBranch ?? environment.baseBranch,
        sourceBranch = sourceBranch ?? environment.defaultSource,
        targetBranch = targetBranch ?? environment.defaultTarget,
        ticketPrefix = ticketPrefix ?? 'VIPOP';

  List<Commit> get allCommits => _allCommits;
  int get currentIndex => _currentIndex;

  void _log(String message, [LogLevel level = LogLevel.info]) {
    onLog?.call(message, level);
  }

  void _notifyStateChange() {
    onStateChange?.call();
  }

  /// Check if an input is a commit hash (7-40 hex characters)
  bool _isCommitHash(String input) {
    return RegExp(r'^[a-f0-9]{7,40}$', caseSensitive: false)
        .hasMatch(input.trim());
  }

  /// Search for commits by ticket or hash
  Future<CommitSearchResult> _searchCommit(String input) async {
    final trimmedInput = input.trim();

    if (_isCommitHash(trimmedInput)) {
      // Commit hash search
      final result = await gitService.getCommit(trimmedInput);
      if (result != null && result.isNotEmpty) {
        try {
          final commit = Commit.fromGitLog(result);
          return CommitSearchResult(
            input: trimmedInput,
            type: 'hash',
            commits: [commit],
          );
        } catch (_) {}
      }
      return CommitSearchResult(input: trimmedInput, type: 'hash', commits: []);
    } else {
      // Ticket search - strip prefix if already present to avoid double prefix
      String ticketNumber = trimmedInput;
      final prefix = ticketPrefix.toUpperCase();
      final upperInput = ticketNumber.toUpperCase();
      
      if (upperInput.startsWith('$prefix-')) {
        ticketNumber = ticketNumber.substring(prefix.length + 1); // Remove 'PREFIX-'
      }
      
      final searchPattern = '$prefix-$ticketNumber';
      
      // Log the git command being executed
      final gitCommand = gitService.getSearchCommand(searchPattern, sourceBranch);
      _log('  📋 執行: $gitCommand', LogLevel.info);
      
      final lines =
          await gitService.searchCommits(searchPattern, sourceBranch);
      final commits = <Commit>[];
      for (final line in lines) {
        try {
          commits.add(Commit.fromGitLog(line));
        } catch (_) {}
      }
      return CommitSearchResult(
        input: trimmedInput,
        type: 'ticket',
        commits: commits,
      );
    }
  }

  /// Pull latest changes from source branch
  Future<void> pullLatest() async {
    _log('📥 更新來源分支以取得最新 commits...', LogLevel.info);
    
    // Checkout source branch
    _log('  📋 執行: git checkout $sourceBranch', LogLevel.info);
    var result = await gitService.checkout(sourceBranch);
    if (!result.success) {
      _log('  ⚠️ 無法切換到 $sourceBranch: ${result.error}', LogLevel.warning);
      return;
    }
    
    // Pull latest
    _log('  📋 執行: git pull origin $sourceBranch', LogLevel.info);
    result = await gitService.pull(sourceBranch);
    if (!result.success) {
      _log('  ⚠️ 無法拉取最新: ${result.error}', LogLevel.warning);
    } else {
      _log('  ✅ 已更新到最新版本', LogLevel.success);
    }
  }

  /// Step 1: Find all commits for the given tickets/hashes
  Future<void> findCommits() async {
    // First, pull latest changes from source branch
    await pullLatest();
    
    _log('🔍 搜尋相關 commits...', LogLevel.info);

    final allCommitsData = <Commit>[];

    for (final input in tickets) {
      final search = await _searchCommit(input);

      if (search.commits.isNotEmpty) {
        _log(
          '  ✅ ${input.trim()} (${search.type}): 找到 ${search.commits.length} 個 commits',
          LogLevel.success,
        );
        allCommitsData.addAll(search.commits);
      } else {
        _log(
          '  ⚠️  ${input.trim()} (${search.type}): 未找到相關 commits',
          LogLevel.warning,
        );
      }
    }

    _allCommits = allCommitsData;
  }

  /// Step 2: Process and sort commits by timestamp
  void processAndSortCommits() {
    if (_allCommits.isEmpty) {
      throw Exception('沒有找到任何相關 commits');
    }

    // Sort by timestamp
    _allCommits.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Remove duplicates
    final uniqueCommits = <Commit>[];
    final seenHashes = <String>{};

    for (final commit in _allCommits) {
      if (!seenHashes.contains(commit.hash)) {
        seenHashes.add(commit.hash);
        uniqueCommits.add(commit);
      }
    }

    _allCommits = uniqueCommits;
    _log('📋 找到 ${_allCommits.length} 個唯一 commits', LogLevel.info);
  }

  /// Step 3: Update base branch and setup target branch
  Future<void> updateBaseAndSetupTarget() async {
    _log('📥 更新來源分支、基礎分支並設定目標分支...', LogLevel.info);

    // Update source branch
    _log('  更新來源分支 $sourceBranch...', LogLevel.info);
    var result = await gitService.checkout(sourceBranch);
    if (!result.success) {
      throw Exception('無法切換到來源分支 $sourceBranch: ${result.error}');
    }

    result = await gitService.pull(sourceBranch);
    if (!result.success) {
      throw Exception('無法拉取 $sourceBranch 最新內容: ${result.error}');
    }

    // Update base branch if different
    if (baseBranch != sourceBranch) {
      _log('  更新基礎分支 $baseBranch...', LogLevel.info);
      result = await gitService.checkout(baseBranch);
      if (!result.success) {
        throw Exception('無法切換到分支 $baseBranch: ${result.error}');
      }

      result = await gitService.pull(baseBranch);
      if (!result.success) {
        throw Exception('無法拉取 $baseBranch 最新內容: ${result.error}');
      }
    }

    // Setup target branch
    final targetExists = await gitService.branchExists(targetBranch);
    if (targetExists) {
      _log(
        '  分支 $targetBranch 已存在，重置為 $baseBranch 最新狀態',
        LogLevel.warning,
      );
      await gitService.checkout(targetBranch);
      await gitService.resetHard(baseBranch);
    } else {
      _log(
        '  創建新分支 $targetBranch 基於 $baseBranch',
        LogLevel.warning,
      );
      await gitService.createBranch(targetBranch, baseBranch: baseBranch);
    }
  }

  /// Check if a commit already exists in target branch
  Future<({bool exists, String? reason})> _isCommitExistsInTarget(
      Commit commit) async {
    // Check ticket number (#xxxx)
    final ticketMatch = RegExp(r'\(#(\d+)\)$').firstMatch(commit.message);
    if (ticketMatch != null) {
      final ticketNumber = ticketMatch.group(1)!;
      final exists =
          await gitService.ticketExistsInBranch(ticketNumber, targetBranch);
      if (exists) {
        return (exists: true, reason: '已存在 #$ticketNumber');
      }
    }

    // Check complete message
    final messageExists =
        await gitService.commitMessageExistsInBranch(commit.message, targetBranch);
    if (messageExists) {
      return (exists: true, reason: '已存在相同訊息');
    }

    return (exists: false, reason: null);
  }

  /// Step 4: Execute cherry-pick for all commits
  /// Returns the index of the conflicting commit, or -1 if all succeeded
  Future<int> cherryPickCommits() async {
    final commitCount = _allCommits.length;
    _log(
      '\n📋 開始 cherry-pick $commitCount 個 commits (從第 ${_currentIndex + 1} 個開始)...',
      LogLevel.info,
    );

    for (int i = _currentIndex; i < _allCommits.length; i++) {
      _currentIndex = i;
      final commit = _allCommits[i];
      final progress = '(${i + 1}/$commitCount)';

      commit.status = CherryPickStatus.applying;
      _notifyStateChange(); // Notify state change when status changes to applying

      // Check if already exists
      final existsCheck = await _isCommitExistsInTarget(commit);
      if (existsCheck.exists) {
        commit.status = CherryPickStatus.skipped;
        _notifyStateChange(); // Notify state change when status changes to skipped
        _log(
          '  ⏭️  $progress 跳過 (${existsCheck.reason}): ${commit.message}',
          LogLevel.warning,
        );
        continue;
      }

      // Execute cherry-pick
      final result = await gitService.cherryPick(commit.hash);

      if (result.success) {
        commit.status = CherryPickStatus.applied;
        _notifyStateChange(); // Notify state change when status changes to applied
        final lastCommit = await gitService.getLastCommit();
        _log(
          '  ✅ $progress ${lastCommit ?? commit.hash}',
          LogLevel.success,
        );
      } else {
        commit.status = CherryPickStatus.conflict;
        _notifyStateChange(); // Notify state change when status changes to conflict
        _log(
          '  ❌ $progress Cherry-pick 失敗，發生衝突: ${commit.hash}',
          LogLevel.error,
        );
        _log('  📝 Commit message: ${commit.message}', LogLevel.error);
        _currentIndex = i + 1; // Next time start from the next commit
        return i; // Return the conflicting index
      }
    }

    _currentIndex = _allCommits.length;
    return -1; // All succeeded
  }

  /// Get statistics
  ({int applied, int skipped}) getStatistics() {
    return (
      applied: _allCommits.where((c) => c.status == CherryPickStatus.applied).length,
      skipped: _allCommits.where((c) => c.status == CherryPickStatus.skipped).length,
    );
  }

  /// Create progress object for saving
  CherryPickProgress createProgress() {
    return CherryPickProgress(
      tickets: tickets,
      environment: environment.name,
      baseBranch: baseBranch,
      sourceBranch: sourceBranch,
      targetBranch: targetBranch,
      allCommits: _allCommits,
      currentIndex: _currentIndex,
      workingDirectory: gitService.workingDirectory,
    );
  }

  /// Restore from progress
  void restoreFromProgress(CherryPickProgress progress) {
    _allCommits = progress.allCommits;
    _currentIndex = progress.currentIndex;
  }

  /// Save progress to file
  Future<void> saveProgress() async {
    final progress = createProgress();
    final file = File('${gitService.workingDirectory}/.cherry-pick-progress.json');
    await file.writeAsString(jsonEncode(progress.toJson()));
    _log('  💾 進度已儲存', LogLevel.info);
  }

  /// Load progress from file
  static Future<CherryPickProgress?> loadProgress(String workingDirectory) async {
    final file = File('$workingDirectory/.cherry-pick-progress.json');
    if (!await file.exists()) {
      return null;
    }
    try {
      final content = await file.readAsString();
      return CherryPickProgress.fromJson(jsonDecode(content));
    } catch (e) {
      return null;
    }
  }

  /// Clear progress file
  static Future<void> clearProgress(String workingDirectory) async {
    final file = File('$workingDirectory/.cherry-pick-progress.json');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
