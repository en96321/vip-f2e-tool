import 'dart:io';
import 'dart:convert';

/// Result of a Git command execution
class GitResult {
  final bool success;
  final String output;
  final String? error;
  final int exitCode;

  GitResult({
    required this.success,
    required this.output,
    this.error,
    this.exitCode = 0,
  });
}

/// Service for executing Git commands
class GitService {
  final String workingDirectory;

  GitService(this.workingDirectory);

  /// Execute a git command with a list of arguments
  Future<GitResult> execArgs(List<String> args, {bool silent = false}) async {
    try {
      final result = await Process.run(
        'git',
        args,
        workingDirectory: workingDirectory,
        stderrEncoding: utf8,
        stdoutEncoding: utf8,
      );

      final success = result.exitCode == 0;
      return GitResult(
        success: success,
        output: result.stdout.toString().trim(),
        error: result.stderr.toString().trim(),
        exitCode: result.exitCode,
      );
    } catch (e) {
      return GitResult(
        success: false,
        output: '',
        error: e.toString(),
        exitCode: 1,
      );
    }
  }

  /// Execute a git command and return the result (for simple commands without spaces in args)
  Future<GitResult> exec(String command, {bool silent = false}) async {
    return execArgs(command.split(' '), silent: silent);
  }

  /// Check if the working directory is a git repository
  Future<bool> isGitRepository() async {
    final result = await exec('rev-parse --is-inside-work-tree');
    return result.success && result.output == 'true';
  }

  /// Check if a branch exists
  Future<bool> branchExists(String branchName) async {
    final result =
        await exec('show-ref --verify --quiet refs/heads/$branchName');
    return result.success;
  }

  /// Get the current branch name
  Future<String?> getCurrentBranch() async {
    final result = await exec('branch --show-current');
    return result.success ? result.output : null;
  }

  /// Checkout a branch
  Future<GitResult> checkout(String branchName) async {
    return await exec('checkout $branchName');
  }

  /// Create a new branch based on another branch
  Future<GitResult> createBranch(String branchName,
      {String? baseBranch}) async {
    if (baseBranch != null) {
      return await exec('checkout -b $branchName $baseBranch');
    }
    return await exec('checkout -b $branchName');
  }

  /// Pull from origin
  Future<GitResult> pull(String branchName) async {
    return await exec('pull origin $branchName');
  }

  /// Reset hard to a branch
  Future<GitResult> resetHard(String target) async {
    return await exec('reset --hard $target');
  }

  /// Search commits by ticket number or pattern (case-insensitive)
  Future<List<String>> searchCommits(String pattern, String branch) async {
    // Use execArgs to properly handle --format with spaces
    // Use --regexp-ignore-case for case-insensitive search
    final result = await execArgs([
      'log',
      branch,
      '--grep=$pattern',
      '--regexp-ignore-case',
      '--format=%H %ct %s',
      '--reverse',
    ]);
    if (!result.success || result.output.isEmpty) {
      return [];
    }
    return result.output.split('\n').where((line) => line.isNotEmpty).toList();
  }

  /// Get the git command string for logging purposes
  String getSearchCommand(String pattern, String branch) {
    return 'git log $branch --grep="$pattern" --regexp-ignore-case --format="%H %ct %s" --reverse';
  }

  /// Get a specific commit by hash
  Future<String?> getCommit(String hash) async {
    // Use execArgs to properly handle --format with spaces
    final result = await execArgs([
      'show',
      '--format=%H %ct %s',
      '--no-patch',
      hash,
    ]);
    return result.success ? result.output : null;
  }

  /// Execute cherry-pick
  Future<GitResult> cherryPick(String hash) async {
    return await exec('cherry-pick -x --no-edit $hash');
  }

  /// Abort cherry-pick
  Future<GitResult> cherryPickAbort() async {
    return await exec('cherry-pick --abort');
  }

  /// Continue cherry-pick after conflict resolution
  Future<GitResult> cherryPickContinue() async {
    return await exec('cherry-pick --continue');
  }

  /// Check if there's an ongoing cherry-pick
  Future<bool> isCherryPickInProgress() async {
    final gitDirResult = await exec('rev-parse --git-dir');
    if (!gitDirResult.success) return false;

    final cherryPickHeadPath =
        '$workingDirectory/${gitDirResult.output}/CHERRY_PICK_HEAD';
    return await File(cherryPickHeadPath).exists();
  }

  /// Get the last commit on current branch
  Future<String?> getLastCommit() async {
    final result = await exec('log --oneline -1 HEAD');
    return result.success ? result.output : null;
  }

  /// Check if a commit message exists in target branch
  Future<bool> commitMessageExistsInBranch(
      String message, String branch) async {
    final result = await execArgs([
      'log',
      branch,
      '--oneline',
      '--format=%s',
    ]);
    if (!result.success) return false;

    final existingMessages =
        result.output.split('\n').map((line) => line.trim()).toList();
    return existingMessages.contains(message.trim());
  }

  /// Check if a ticket number (#xxxx) exists in target branch
  Future<bool> ticketExistsInBranch(String ticketNumber, String branch) async {
    final result = await execArgs([
      'log',
      branch,
      '--grep=(#$ticketNumber)\$',
      '--format=%H',
      '-1',
    ]);
    return result.success && result.output.isNotEmpty;
  }
}
