import 'dart:io';
import 'dart:convert';
import '../models/repo_config.dart';
import '../models/commit_info.dart';

class GitService {
  String? _ghPath;

  /// Get platform-specific gh paths
  List<String> get _ghPaths {
    if (Platform.isWindows) {
      return [
        'C:\\Program Files\\GitHub CLI\\gh.exe',
        'C:\\Program Files (x86)\\GitHub CLI\\gh.exe',
        '${Platform.environment['LOCALAPPDATA']}\\GitHub CLI\\gh.exe',
        'gh.exe',
        'gh',
      ];
    } else {
      // macOS / Linux
      return [
        '/opt/homebrew/bin/gh',     // ARM Mac Homebrew
        '/usr/local/bin/gh',        // Intel Mac Homebrew
        '/usr/bin/gh',              // System install
        'gh',                       // In PATH
      ];
    }
  }

  /// Find the gh executable path - with full error handling
  Future<String?> _findGhPath() async {
    if (_ghPath != null) return _ghPath;

    for (final path in _ghPaths) {
      try {
        // For Windows, check if file exists (for absolute paths)
        if (path.contains(Platform.pathSeparator) || path.contains('/') || path.contains('\\')) {
          final file = File(path);
          if (!await file.exists()) {
            continue;
          }
        }

        // Try to run it
        final result = await Process.run(
          path, 
          ['--version'],
          runInShell: Platform.isWindows,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => ProcessResult(0, 1, '', 'timeout'),
        );
        
        if (result.exitCode == 0) {
          _ghPath = path;
          return path;
        }
      } catch (e) {
        // Try next path - don't crash
        continue;
      }
    }
    return null;
  }

  /// Check if GitHub CLI (gh) is installed
  Future<bool> isGhInstalled() async {
    try {
      return await _findGhPath() != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if GitHub CLI is authenticated
  Future<bool> isGhAuthenticated() async {
    try {
      final ghPath = await _findGhPath();
      if (ghPath == null) return false;

      final result = await Process.run(
        ghPath, 
        ['auth', 'status'],
        runInShell: Platform.isWindows,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => ProcessResult(0, 1, '', 'timeout'),
      );
      
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get installation command for GitHub CLI
  String getInstallCommand() {
    if (Platform.isWindows) {
      return 'winget install GitHub.cli';
    } else {
      return 'brew install gh && gh auth login';
    }
  }

  /// Open Terminal with install command
  Future<void> openTerminalWithInstall() async {
    try {
      if (Platform.isWindows) {
        // Open PowerShell with install command
        await Process.run(
          'powershell',
          ['-Command', 'Start-Process', 'powershell', '-ArgumentList', 
           '"-NoExit -Command winget install GitHub.cli; gh auth login"'],
          runInShell: true,
        );
      } else {
        // macOS - use AppleScript
        final script = '''
          tell application "Terminal"
            activate
            do script "brew install gh && gh auth login"
          end tell
        ''';
        await Process.run('osascript', ['-e', script]);
      }
    } catch (e) {
      // Ignore errors - just best effort
    }
  }

  /// Open Terminal for auth
  Future<void> openTerminalWithAuth() async {
    try {
      if (Platform.isWindows) {
        await Process.run(
          'powershell',
          ['-Command', 'Start-Process', 'powershell', '-ArgumentList', 
           '"-NoExit -Command gh auth login"'],
          runInShell: true,
        );
      } else {
        final script = '''
          tell application "Terminal"
            activate
            do script "gh auth login"
          end tell
        ''';
        await Process.run('osascript', ['-e', script]);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Fetch recent commits for a repo/branch using GitHub CLI
  Future<GitResult<List<CommitInfo>>> fetchCommits(
    RepoConfig repo, {
    int count = 5,
  }) async {
    final log = StringBuffer();
    
    try {
      // Find gh path
      final ghPath = await _findGhPath();
      if (ghPath == null) {
        final installCmd = getInstallCommand();
        return GitResult.error(
          'GitHub CLI (gh) 未安裝。\n\n'
          '請在終端機執行以下命令安裝：\n'
          '$installCmd',
          needsInstall: true,
        );
      }

      // Check if gh is authenticated
      try {
        final authResult = await Process.run(
          ghPath, 
          ['auth', 'status'],
          runInShell: Platform.isWindows,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => ProcessResult(0, 1, '', 'timeout'),
        );
        
        if (authResult.exitCode != 0) {
          return GitResult.error(
            'GitHub CLI 尚未登入。\n\n'
            '請在終端機執行以下命令登入：\n'
            'gh auth login',
            needsAuth: true,
          );
        }
      } catch (e) {
        return GitResult.error(
          'GitHub CLI 認證檢查失敗：$e',
          needsAuth: true,
        );
      }

      log.writeln('=== Fetching Commits ===');
      log.writeln('Platform: ${Platform.operatingSystem}');
      log.writeln('gh path: $ghPath');
      log.writeln('Repository: ${repo.owner}/${repo.repo}');
      log.writeln('Branch: ${repo.branch}');
      log.writeln('');

      // Use gh api to get commits
      final apiPath = 'repos/${repo.owner}/${repo.repo}/commits?sha=${repo.branch}&per_page=$count';
      final args = ['api', apiPath];
      
      log.writeln('Command: $ghPath ${args.join(" ")}');
      log.writeln('');

      ProcessResult result;
      try {
        result = await Process.run(
          ghPath, 
          args,
          runInShell: Platform.isWindows,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => ProcessResult(0, 1, '', 'Request timeout'),
        );
      } catch (e) {
        log.writeln('Process.run exception: $e');
        return GitResult.error('執行 gh 命令時發生錯誤：$e\n\n$log');
      }

      log.writeln('Exit Code: ${result.exitCode}');

      if (result.exitCode != 0) {
        final stderr = result.stderr.toString();
        log.writeln('Stderr: $stderr');
        
        if (stderr.contains('Could not resolve') || stderr.contains('Not Found') || stderr.contains('404')) {
          return GitResult.error('Repository 或 branch 找不到: ${repo.owner}/${repo.repo} (${repo.branch})\n\n$log');
        }
        if (stderr.contains('auth') || stderr.contains('401')) {
          return GitResult.error('認證失敗，請執行 gh auth login\n\n$log', needsAuth: true);
        }
        return GitResult.error('Failed to fetch commits.\n\n$log\nError: $stderr');
      }

      final output = result.stdout.toString().trim();
      log.writeln('Output length: ${output.length} bytes');

      if (output.isEmpty) {
        return GitResult.error('No commits found for branch "${repo.branch}".\n\n$log');
      }

      // Parse JSON response
      try {
        final dynamic decoded = jsonDecode(output);
        if (decoded is! List) {
          return GitResult.error('Unexpected response format.\n\n$log');
        }
        
        final List<dynamic> jsonList = decoded;
        final commits = <CommitInfo>[];
        
        for (final item in jsonList) {
          if (commits.length >= count) break;
          if (item is Map<String, dynamic>) {
            final sha = item['sha'] as String? ?? '';
            final commitData = item['commit'] as Map<String, dynamic>?;
            final message = commitData?['message'] as String? ?? 'No message';
            final authorData = commitData?['author'] as Map<String, dynamic>?;
            final author = authorData?['name'] as String? ?? 'Unknown';
            final dateStr = authorData?['date'] as String? ?? '';
            
            if (sha.isNotEmpty) {
              commits.add(CommitInfo(
                sha: sha,
                message: message,
                author: author,
                date: DateTime.tryParse(dateStr) ?? DateTime.now(),
              ));
            }
          }
        }

        if (commits.isEmpty) {
          return GitResult.error('Failed to parse commits.\n\n$log');
        }

        return GitResult.success(commits);
      } catch (e) {
        return GitResult.error('Failed to parse commits: $e\n\n$log');
      }
    } catch (e) {
      return GitResult.error('Error fetching commits: $e');
    }
  }
}

class GitResult<T> {
  final T? data;
  final String? error;
  final bool success;
  final bool needsInstall;
  final bool needsAuth;

  GitResult._({
    this.data,
    this.error,
    required this.success,
    this.needsInstall = false,
    this.needsAuth = false,
  });

  factory GitResult.success(T data) => GitResult._(data: data, success: true);
  factory GitResult.error(String error, {bool needsInstall = false, bool needsAuth = false}) => 
      GitResult._(error: error, success: false, needsInstall: needsInstall, needsAuth: needsAuth);
}
