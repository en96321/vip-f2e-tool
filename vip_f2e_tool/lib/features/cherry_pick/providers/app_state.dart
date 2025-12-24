import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/commit.dart';
import '../models/environment.dart';
import '../models/progress.dart';
import '../services/git_service.dart';
import '../services/cherry_pick_manager.dart';

// ===========================================================================
// Log Entry
// ===========================================================================

class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;

  LogEntry({
    required this.message,
    required this.level,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ===========================================================================
// App State
// ===========================================================================

enum AppStatus {
  idle,
  searching,
  preparing,
  cherryPicking,
  conflict,
  completed,
  error,
}

class AppState {
  final String? workingDirectory;
  final List<String> recentDirectories;
  final Environment selectedEnvironment;
  final String baseBranch;  // The branch to base the target branch on
  final String sourceBranch;
  final String targetBranch;
  final String ticketPrefix; // Custom ticket prefix (e.g. VIPOP)
  final String inputText;
  final List<Commit> commits;
  final int currentCommitIndex;
  final AppStatus status;
  final List<LogEntry> logs;
  final String? errorMessage;
  final CherryPickProgress? savedProgress;

  const AppState({
    this.workingDirectory,
    this.recentDirectories = const [],
    this.selectedEnvironment = Environments.staging,
    this.baseBranch = 'staging',
    this.sourceBranch = 'lab',
    this.targetBranch = 'to-staging',
    this.ticketPrefix = 'VIPOP',
    this.inputText = '',
    this.commits = const [],
    this.currentCommitIndex = 0,
    this.status = AppStatus.idle,
    this.logs = const [],
    this.errorMessage,
    this.savedProgress,
  });

  AppState copyWith({
    String? workingDirectory,
    List<String>? recentDirectories,
    Environment? selectedEnvironment,
    String? baseBranch,
    String? sourceBranch,
    String? targetBranch,
    String? ticketPrefix,
    String? inputText,
    List<Commit>? commits,
    int? currentCommitIndex,
    AppStatus? status,
    List<LogEntry>? logs,
    String? errorMessage,
    CherryPickProgress? savedProgress,
    bool clearError = false,
    bool clearProgress = false,
  }) {
    return AppState(
      workingDirectory: workingDirectory ?? this.workingDirectory,
      recentDirectories: recentDirectories ?? this.recentDirectories,
      selectedEnvironment: selectedEnvironment ?? this.selectedEnvironment,
      baseBranch: baseBranch ?? this.baseBranch,
      sourceBranch: sourceBranch ?? this.sourceBranch,
      targetBranch: targetBranch ?? this.targetBranch,
      ticketPrefix: ticketPrefix ?? this.ticketPrefix,
      inputText: inputText ?? this.inputText,
      commits: commits ?? this.commits,
      currentCommitIndex: currentCommitIndex ?? this.currentCommitIndex,
      status: status ?? this.status,
      logs: logs ?? this.logs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedProgress: clearProgress ? null : (savedProgress ?? this.savedProgress),
    );
  }
}

// ===========================================================================
// App State Notifier
// ===========================================================================

class AppStateNotifier extends StateNotifier<AppState> {
  static const _recentDirsKey = 'recent_directories';
  static const _lastDirKey = 'last_directory';
  static const _maxRecentDirs = 5;

  AppStateNotifier() : super(const AppState()) {
    _loadSettings();
  }

  /// Get a unique key for repo-specific settings
  String _getRepoSettingsKey(String path) {
    // Use base64 encoded path to create a safe key
    final repoName = path.split('/').last;
    return 'repo_settings_$repoName';
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final recentDirs = prefs.getStringList(_recentDirsKey) ?? [];
    final lastDir = prefs.getString(_lastDirKey);

    state = state.copyWith(
      recentDirectories: recentDirs,
      workingDirectory: lastDir,
    );

    if (lastDir != null) {
      await _loadRepoSettings(lastDir);
      await _checkSavedProgress();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentDirsKey, state.recentDirectories);
    if (state.workingDirectory != null) {
      await prefs.setString(_lastDirKey, state.workingDirectory!);
    }
  }

  /// Load repo-specific settings (baseBranch, sourceBranch, targetBranch, ticketPrefix)
  Future<void> _loadRepoSettings(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getRepoSettingsKey(path);
    
    final baseBranch = prefs.getString('${key}_baseBranch');
    final sourceBranch = prefs.getString('${key}_sourceBranch');
    final targetBranch = prefs.getString('${key}_targetBranch');
    final ticketPrefix = prefs.getString('${key}_ticketPrefix');
    final envName = prefs.getString('${key}_environment');
    
    final env = envName != null 
        ? (Environments.byName(envName) ?? Environments.staging)
        : Environments.staging;
    
    state = state.copyWith(
      baseBranch: baseBranch ?? env.baseBranch,
      sourceBranch: sourceBranch ?? env.defaultSource,
      targetBranch: targetBranch ?? env.defaultTarget,
      ticketPrefix: ticketPrefix ?? 'VIPOP',
      selectedEnvironment: env,
    );
  }

  /// Save repo-specific settings
  Future<void> _saveRepoSettings() async {
    if (state.workingDirectory == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final key = _getRepoSettingsKey(state.workingDirectory!);
    
    await prefs.setString('${key}_baseBranch', state.baseBranch);
    await prefs.setString('${key}_sourceBranch', state.sourceBranch);
    await prefs.setString('${key}_targetBranch', state.targetBranch);
    await prefs.setString('${key}_ticketPrefix', state.ticketPrefix);
    await prefs.setString('${key}_environment', state.selectedEnvironment.name);
  }

  Future<void> _checkSavedProgress() async {
    if (state.workingDirectory == null) return;

    final progress = await CherryPickManager.loadProgress(state.workingDirectory!);
    if (progress != null) {
      state = state.copyWith(savedProgress: progress);
    }
  }

  void _addLog(String message, LogLevel level) {
    final logs = [...state.logs, LogEntry(message: message, level: level)];
    state = state.copyWith(logs: logs);
  }

  // ===========================================================================
  // Public Methods
  // ===========================================================================

  Future<bool> setWorkingDirectory(String path) async {
    final gitService = GitService(path);
    final isGitRepo = await gitService.isGitRepository();

    if (!isGitRepo) {
      state = state.copyWith(
        errorMessage: '選擇的目錄不是有效的 Git Repository',
      );
      return false;
    }

    // Update recent directories
    final recentDirs = <String>{path, ...state.recentDirectories}
        .take(_maxRecentDirs)
        .toList();

    state = state.copyWith(
      workingDirectory: path,
      recentDirectories: recentDirs,
      logs: [],
      clearError: true,
    );

    await _saveSettings();
    await _loadRepoSettings(path);
    await _checkSavedProgress();

    _addLog('📁 工作目錄: $path', LogLevel.info);
    _addLog('  📋 基礎分支: ${state.baseBranch}', LogLevel.info);
    return true;
  }

  void setEnvironment(Environment env) {
    state = state.copyWith(
      selectedEnvironment: env,
      baseBranch: env.baseBranch,
      sourceBranch: env.defaultSource,
      targetBranch: env.defaultTarget,
    );
    _saveRepoSettings();
  }

  void setBaseBranch(String branch) {
    state = state.copyWith(baseBranch: branch);
    _saveRepoSettings();
  }

  void setSourceBranch(String branch) {
    state = state.copyWith(sourceBranch: branch);
    _saveRepoSettings();
  }

  void setTargetBranch(String branch) {
    state = state.copyWith(targetBranch: branch);
    _saveRepoSettings();
  }

  void setTicketPrefix(String prefix) {
    state = state.copyWith(ticketPrefix: prefix);
    _saveRepoSettings();
  }

  void setInputText(String text) {
    state = state.copyWith(inputText: text);
  }

  void clearLogs() {
    state = state.copyWith(logs: []);}

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> searchCommits() async {
    if (state.workingDirectory == null) {
      state = state.copyWith(errorMessage: '請先選擇工作目錄');
      return;
    }

    if (state.inputText.trim().isEmpty) {
      state = state.copyWith(errorMessage: '請輸入 Ticket 號碼或 Commit Hash');
      return;
    }

    state = state.copyWith(
      status: AppStatus.searching,
      commits: [],
      clearError: true,
    );

    try {
      final gitService = GitService(state.workingDirectory!);
      final tickets = state.inputText.split(',').map((t) => t.trim()).toList();

      final manager = CherryPickManager(
        gitService: gitService,
        tickets: tickets,
        environment: state.selectedEnvironment,
        baseBranch: state.baseBranch,
        sourceBranch: state.sourceBranch,
        targetBranch: state.targetBranch,
        ticketPrefix: state.ticketPrefix,
        onLog: _addLog,
      );

      await manager.findCommits();
      manager.processAndSortCommits();

      state = state.copyWith(
        commits: manager.allCommits,
        status: AppStatus.idle,
      );

      _addLog('🔍 搜尋完成，找到 ${manager.allCommits.length} 個 commits', LogLevel.success);
    } catch (e) {
      state = state.copyWith(
        status: AppStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> executeCherryPick() async {
    if (state.workingDirectory == null) return;
    if (state.commits.isEmpty) {
      state = state.copyWith(errorMessage: '請先搜尋 commits');
      return;
    }

    state = state.copyWith(
      status: AppStatus.preparing,
      clearError: true,
    );

    try {
      final gitService = GitService(state.workingDirectory!);
      final tickets = state.inputText.split(',').map((t) => t.trim()).toList();

      final manager = CherryPickManager(
        gitService: gitService,
        tickets: tickets,
        environment: state.selectedEnvironment,
        baseBranch: state.baseBranch,
        sourceBranch: state.sourceBranch,
        targetBranch: state.targetBranch,
        ticketPrefix: state.ticketPrefix,
        onLog: _addLog,
        onStateChange: () {
          // Force update state to refresh UI
          state = state.copyWith(commits: [...state.commits]);
        },
      );

      // Use existing commits
      manager.restoreFromProgress(CherryPickProgress(
        tickets: tickets,
        environment: state.selectedEnvironment.name,
        baseBranch: state.baseBranch,
        sourceBranch: state.sourceBranch,
        targetBranch: state.targetBranch,
        allCommits: state.commits,
        currentIndex: 0,
      ));

      _addLog('📥 準備分支...', LogLevel.info);
      await manager.updateBaseAndSetupTarget();

      state = state.copyWith(status: AppStatus.cherryPicking);

      final conflictIndex = await manager.cherryPickCommits();

      if (conflictIndex >= 0) {
        await manager.saveProgress();
        state = state.copyWith(
          status: AppStatus.conflict,
          commits: manager.allCommits,
          currentCommitIndex: conflictIndex,
        );
      } else {
        await CherryPickManager.clearProgress(state.workingDirectory!);
        final stats = manager.getStatistics();
        _addLog(
          '\n🎉 Cherry-pick 完成！已套用 ${stats.applied} 個，已跳過 ${stats.skipped} 個',
          LogLevel.success,
        );
        state = state.copyWith(
          status: AppStatus.completed,
          commits: manager.allCommits,
          clearProgress: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AppStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> continueFromProgress() async {
    if (state.workingDirectory == null) return;

    // Use saved progress if available, otherwise try to load from file
    var progress = state.savedProgress;
    progress ??= await CherryPickManager.loadProgress(state.workingDirectory!);
    
    state = state.copyWith(
      status: AppStatus.cherryPicking,
      clearError: true,
    );

    try {
      final gitService = GitService(state.workingDirectory!);

      // If there's an ongoing git cherry-pick, complete it first
      if (await gitService.isCherryPickInProgress()) {
        _addLog('🔄 執行 git cherry-pick --continue...', LogLevel.info);
        final continueResult = await gitService.cherryPickContinue();
        
        if (continueResult.success) {
          _addLog('✅ Cherry-pick 衝突已解決', LogLevel.success);
          
          // Update the commit status in progress
          if (progress != null && progress.currentIndex > 0) {
            final prevIndex = progress.currentIndex - 1;
            if (prevIndex < progress.allCommits.length) {
              progress.allCommits[prevIndex].status = CherryPickStatus.applied;
            }
          }
        } else {
          _addLog('❌ git cherry-pick --continue 失敗: ${continueResult.error}', LogLevel.error);
          _addLog('請確認已解決所有衝突並執行 git add .', LogLevel.warning);
          state = state.copyWith(
            status: AppStatus.conflict,
            errorMessage: 'cherry-pick --continue 失敗，請確認已解決所有衝突',
          );
          return;
        }
      }

      // If no saved progress, nothing to continue
      if (progress == null) {
        _addLog('⚠️ 沒有儲存的進度可以繼續', LogLevel.warning);
        state = state.copyWith(status: AppStatus.idle);
        return;
      }

      state = state.copyWith(
        commits: progress.allCommits,
        clearProgress: true,
      );

      final manager = CherryPickManager(
        gitService: gitService,
        tickets: progress.tickets,
        environment: Environments.byName(progress.environment) ?? Environments.staging,
        baseBranch: progress.baseBranch,
        sourceBranch: progress.sourceBranch,
        targetBranch: progress.targetBranch,
        ticketPrefix: state.ticketPrefix,
        onLog: _addLog,
        onStateChange: () {
          // Force update state to refresh UI
          state = state.copyWith(commits: [...state.commits]);
        },
      );

      manager.restoreFromProgress(progress);

      _addLog('📂 從第 ${progress.currentIndex + 1} 個 commit 繼續執行...', LogLevel.info);

      final conflictIndex = await manager.cherryPickCommits();

      if (conflictIndex >= 0) {
        await manager.saveProgress();
        state = state.copyWith(
          status: AppStatus.conflict,
          commits: manager.allCommits,
          currentCommitIndex: conflictIndex,
        );
      } else {
        await CherryPickManager.clearProgress(state.workingDirectory!);
        final stats = manager.getStatistics();
        _addLog(
          '\n🎉 Cherry-pick 完成！已套用 ${stats.applied} 個，已跳過 ${stats.skipped} 個',
          LogLevel.success,
        );
        state = state.copyWith(
          status: AppStatus.completed,
          commits: manager.allCommits,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AppStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> abortCherryPick() async {
    if (state.workingDirectory == null) return;

    final gitService = GitService(state.workingDirectory!);

    // Abort git cherry-pick if in progress
    if (await gitService.isCherryPickInProgress()) {
      await gitService.cherryPickAbort();
      _addLog('✅ Git cherry-pick 已中止', LogLevel.success);
    }

    // Clear progress file
    await CherryPickManager.clearProgress(state.workingDirectory!);

    state = state.copyWith(
      status: AppStatus.idle,
      commits: [],
      clearProgress: true,
    );

    _addLog('🗑️ 已中止並清除所有進度', LogLevel.info);
  }

  Future<void> openTerminal() async {
    if (state.workingDirectory == null) return;

    await Process.run('open', ['-a', 'Terminal', state.workingDirectory!]);
  }

  Future<void> openVSCode() async {
    if (state.workingDirectory == null) return;

    await Process.run('code', [state.workingDirectory!]);
  }
}

// ===========================================================================
// Providers
// ===========================================================================

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});
