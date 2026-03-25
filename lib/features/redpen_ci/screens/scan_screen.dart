import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/repo_config.dart';
import '../models/commit_info.dart';
import '../models/execution_record.dart';
import '../services/storage_service.dart';
import '../services/history_service.dart';
import '../services/git_service.dart';
import '../services/command_service.dart';

class ScanScreen extends StatefulWidget {
  final StorageService storageService;
  final HistoryService historyService;

  const ScanScreen({
    super.key,
    required this.storageService,
    required this.historyService,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _gitService = GitService();
  final _commandService = CommandService();
  
  int _currentStep = 0;
  
  // Step 1: Selected repos
  Set<RepoConfig> _selectedRepos = {};
  
  // Step 2: Commits per repo
  Map<RepoConfig, List<CommitInfo>> _commitsMap = {};
  Map<RepoConfig, CommitInfo?> _selectedCommits = {};
  Map<RepoConfig, String?> _fetchErrors = {};
  bool _isLoadingCommits = false;
  
  // Step 3: Scan results
  Map<RepoConfig, ScanResult> _scanResults = {};
  bool _isScanning = false;

  List<RepoConfig> get _repos => widget.storageService.repos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: _buildStepContent(),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return '選擇 Repos';
      case 1:
        return '選擇 Commits';
      case 2:
        return '掃描進度';
      default:
        return 'RedPen CI';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildRepoSelection();
      case 1:
        return _buildCommitSelection();
      case 2:
        return _buildScanProgress();
      default:
        return const SizedBox();
    }
  }

  // === Step 1: Repo Selection ===
  Widget _buildRepoSelection() {
    if (_repos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('尚未設定任何 Repo', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.settings),
              label: const Text('前往設定'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _repos.length,
            itemBuilder: (context, index) {
              final repo = _repos[index];
              final isSelected = _selectedRepos.contains(repo);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedRepos.add(repo);
                      } else {
                        _selectedRepos.remove(repo);
                      }
                    });
                  },
                  title: Text(repo.displayName),
                  subtitle: Text(repo.branch, style: TextStyle(color: Colors.grey[400])),
                  secondary: const Icon(Icons.folder, color: Colors.blueAccent),
                ),
              );
            },
          ),
        ),
        _buildBottomBar(
          enabled: _selectedRepos.isNotEmpty,
          label: '下一步：選擇 Commits (${_selectedRepos.length})',
          onPressed: _fetchCommits,
        ),
      ],
    );
  }

  Future<void> _fetchCommits() async {
    // First check if gh CLI is available
    final isInstalled = await _gitService.isGhInstalled();
    if (!isInstalled) {
      if (mounted) {
        _showGhInstallDialog();
      }
      return;  // Don't proceed - stay on step 0
    }

    final isAuth = await _gitService.isGhAuthenticated();
    if (!isAuth) {
      if (mounted) {
        _showGhAuthDialog();
      }
      return;  // Don't proceed - stay on step 0
    }

    // Now safe to proceed to step 1
    setState(() {
      _isLoadingCommits = true;
      _currentStep = 1;
      _commitsMap.clear();
      _selectedCommits.clear();
      _fetchErrors.clear();
    });

    final count = widget.storageService.commitCount;
    
    // Fetch commits for all selected repos concurrently
    await Future.wait(_selectedRepos.map((repo) async {
      final result = await _gitService.fetchCommits(repo, count: count);
      if (mounted) {
        setState(() {
          if (result.success && result.data != null) {
            _commitsMap[repo] = result.data!;
            if (result.data!.isNotEmpty) {
              _selectedCommits[repo] = result.data!.first;
            }
          } else {
            _fetchErrors[repo] = result.error ?? 'Unknown error';
          }
        });
      }
    }));

    if (mounted) {
      setState(() => _isLoadingCommits = false);
    }
  }

  void _showGhInstallDialog() {
    final installCmd = _gitService.getInstallCommand();
    final isWindows = Platform.isWindows;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.orange),
            SizedBox(width: 8),
            Text('需要安裝 GitHub CLI'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GitHub CLI (gh) 未安裝。'),
            const SizedBox(height: 12),
            Text(isWindows ? '請在 PowerShell 或 cmd 執行以下命令：' : '請在 Terminal 執行以下命令：'),
            const SizedBox(height: 8),
            SelectableText(
              installCmd,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _gitService.openTerminalWithInstall();
            },
            icon: const Icon(Icons.terminal),
            label: Text(isWindows ? '開啟 PowerShell' : '開啟 Terminal'),
          ),
        ],
      ),
    );
  }

  void _showGhAuthDialog() {
    final isWindows = Platform.isWindows;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.login, color: Colors.orange),
            SizedBox(width: 8),
            Text('需要登入 GitHub'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GitHub CLI 尚未登入。'),
            const SizedBox(height: 12),
            Text(isWindows ? '請在 PowerShell 執行以下命令：' : '請在 Terminal 執行以下命令：'),
            const SizedBox(height: 8),
            const SelectableText(
              'gh auth login',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _gitService.openTerminalWithAuth();
            },
            icon: const Icon(Icons.terminal),
            label: Text(isWindows ? '開啟 PowerShell' : '開啟 Terminal'),
          ),
        ],
      ),
    );
  }

  // === Step 2: Commit Selection ===
  Widget _buildCommitSelection() {
    if (_isLoadingCommits) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在載入 Commits...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _selectedRepos.length,
            itemBuilder: (context, index) {
              final repo = _selectedRepos.elementAt(index);
              final commits = _commitsMap[repo] ?? [];
              final error = _fetchErrors[repo];
              final selectedCommit = _selectedCommits[repo];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  repo.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  repo.branch,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(error, style: const TextStyle(color: Colors.red))),
                            ],
                          ),
                        )
                      else if (commits.isEmpty)
                        const Text('沒有找到 Commits', style: TextStyle(color: Colors.grey))
                      else
                        ...commits.map((commit) => RadioListTile<CommitInfo>(
                          value: commit,
                          groupValue: selectedCommit,
                          onChanged: (value) {
                            setState(() => _selectedCommits[repo] = value);
                          },
                          title: Text(
                            commit.shortMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${commit.shortSha} • ${commit.author}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                          dense: true,
                        )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildBottomBar(
          enabled: _selectedCommits.values.where((c) => c != null).isNotEmpty,
          label: '執行掃描 (${_selectedCommits.values.where((c) => c != null).length})',
          onPressed: _startScanning,
        ),
      ],
    );
  }

  Future<void> _startScanning() async {
    setState(() {
      _currentStep = 2;
      _isScanning = true;
      _scanResults.clear();
    });

    // Initialize all as pending
    for (final repo in _selectedRepos) {
      if (_selectedCommits[repo] != null) {
        _scanResults[repo] = ScanResult.pending();
      }
    }
    setState(() {});

    // Execute scans concurrently
    await Future.wait(_selectedRepos.map((repo) async {
      final commit = _selectedCommits[repo];
      if (commit == null) return;

      setState(() => _scanResults[repo] = ScanResult.running());

      final result = await _commandService.execute(
        targetUrl: widget.storageService.targetUrl,
        token: widget.storageService.token,
        mail: widget.storageService.mail,
        repo: repo.slug,
        commitHash: commit.sha,
        sastFilter: widget.storageService.sastFilter,
      );

      // Save to history
      await widget.historyService.addRecord(ExecutionRecord(
        repo: repo.toString(),
        commitHash: commit.sha,
        timestamp: DateTime.now(),
        response: result.output,
        success: result.success,
      ));

      setState(() {
        _scanResults[repo] = ScanResult(
          success: result.success,
          output: result.output,
          isComplete: true,
        );
      });
    }));

    setState(() => _isScanning = false);
  }

  // === Step 3: Scan Progress ===
  Widget _buildScanProgress() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _selectedRepos.length,
            itemBuilder: (context, index) {
              final repo = _selectedRepos.elementAt(index);
              final commit = _selectedCommits[repo];
              final result = _scanResults[repo];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _buildStatusIcon(result),
                  title: Text(repo.displayName),
                  subtitle: Text(
                    commit?.shortSha ?? 'N/A',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: result?.isComplete == true
                      ? IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () => _showResult(repo, result!),
                        )
                      : null,
                  onTap: result?.isComplete == true
                      ? () => _showResult(repo, result!)
                      : null,
                ),
              );
            },
          ),
        ),
        if (!_isScanning)
          _buildBottomBar(
            enabled: true,
            label: '完成',
            onPressed: () => Navigator.pop(context),
          ),
      ],
    );
  }

  Widget _buildStatusIcon(ScanResult? result) {
    if (result == null || result.isPending) {
      return const Icon(Icons.pending, color: Colors.grey);
    }
    if (result.isRunning) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (result.success) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    return const Icon(Icons.error, color: Colors.red);
  }

  void _showResult(RepoConfig repo, ScanResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(repo.displayName)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      result.output ?? '(無輸出)',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result.output ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已複製到剪貼簿')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('複製'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({
    required bool enabled,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class ScanResult {
  final bool success;
  final String? output;
  final bool isComplete;
  final bool isPending;
  final bool isRunning;

  ScanResult({
    this.success = false,
    this.output,
    this.isComplete = false,
    this.isPending = false,
    this.isRunning = false,
  });

  factory ScanResult.pending() => ScanResult(isPending: true);
  factory ScanResult.running() => ScanResult(isRunning: true);
}
