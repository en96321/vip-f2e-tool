import 'dart:io';

class CommandService {
  /// Get platform-specific temp directory
  String get _tempDir {
    if (Platform.isWindows) {
      return Platform.environment['TEMP'] ?? 'C:\\Windows\\Temp';
    }
    return '/tmp';
  }

  /// Get platform-specific script path
  String get _scriptPath {
    if (Platform.isWindows) {
      return '$_tempDir\\redpen-ci.sh';
    }
    return '/tmp/redpen-ci.sh';
  }

  Future<CommandResult> execute({
    required String targetUrl,
    required String token,
    required String mail,
    required String repo,
    required String commitHash,
    required String sastFilter,
  }) async {
    final StringBuffer log = StringBuffer();
    
    try {
      log.writeln('=== 下載腳本 ===');
      log.writeln('Platform: ${Platform.operatingSystem}');
      log.writeln('URL: $targetUrl');
      log.writeln('Script path: $_scriptPath');
      log.writeln('');
      
      // Download the script using curl
      ProcessResult downloadResult;
      
      if (Platform.isWindows) {
        // Windows: use curl.exe or PowerShell
        try {
          downloadResult = await Process.run(
            'curl.exe',
            ['--tlsv1.2', '-sSf', targetUrl, '-o', _scriptPath],
            runInShell: true,
          ).timeout(const Duration(seconds: 30));
        } catch (e) {
          // Fallback to PowerShell Invoke-WebRequest
          downloadResult = await Process.run(
            'powershell',
            ['-Command', 'Invoke-WebRequest', '-Uri', targetUrl, '-OutFile', _scriptPath],
            runInShell: true,
          ).timeout(const Duration(seconds: 30));
        }
      } else {
        // macOS/Linux: use curl
        downloadResult = await Process.run(
          'curl',
          ['--tlsv1.2', '-sSf', targetUrl, '-o', _scriptPath],
        ).timeout(const Duration(seconds: 30));
      }

      log.writeln('Download Exit Code: ${downloadResult.exitCode}');
      if (downloadResult.stdout.toString().isNotEmpty) {
        log.writeln('Stdout: ${downloadResult.stdout}');
      }
      if (downloadResult.stderr.toString().isNotEmpty) {
        log.writeln('Stderr: ${downloadResult.stderr}');
      }

      if (downloadResult.exitCode != 0) {
        return CommandResult(
          success: false,
          output: '下載腳本失敗\n\n${log.toString()}',
        );
      }

      // Make it executable (not needed on Windows)
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', _scriptPath]);
      }

      log.writeln('');
      log.writeln('=== 執行掃描 ===');
      log.writeln('Repository: $repo');
      log.writeln('Commit: $commitHash');
      log.writeln('SAST Filter: $sastFilter');
      log.writeln('Mail: $mail');
      log.writeln('Token: ${token.isNotEmpty ? "${token.substring(0, 4)}..." : "(empty)"}');
      log.writeln('');

      // Execute the script
      ProcessResult result;
      final environment = {
        'REDPEN_CI_API_TOKEN': token,
        'REDPEN_CI_MAIL_TO': mail,
      };

      if (Platform.isWindows) {
        // Windows: use Git Bash or WSL sh, or PowerShell to run bash
        try {
          // Try Git Bash first
          result = await Process.run(
            'C:\\Program Files\\Git\\bin\\bash.exe',
            [_scriptPath,
              '--github-slug', repo,
              '--commit', commitHash,
              '--sast-filter', sastFilter,
            ],
            environment: environment,
            runInShell: false,
          ).timeout(const Duration(minutes: 5));
        } catch (e) {
          // Fallback: Try wsl
          try {
            result = await Process.run(
              'wsl',
              ['sh', _scriptPath,
                '--github-slug', repo,
                '--commit', commitHash,
                '--sast-filter', sastFilter,
              ],
              environment: environment,
              runInShell: true,
            ).timeout(const Duration(minutes: 5));
          } catch (e2) {
            log.writeln('Error: 無法執行 shell script。請安裝 Git for Windows 或 WSL。');
            log.writeln('Git Bash error: $e');
            log.writeln('WSL error: $e2');
            return CommandResult(success: false, output: log.toString());
          }
        }
      } else {
        result = await Process.run(
          'sh',
          [_scriptPath,
            '--github-slug', repo,
            '--commit', commitHash,
            '--sast-filter', sastFilter,
          ],
          environment: environment,
        ).timeout(const Duration(minutes: 5));
      }

      log.writeln('Exit Code: ${result.exitCode}');
      log.writeln('');
      
      if (result.stdout.toString().isNotEmpty) {
        log.writeln('=== Output ===');
        log.writeln(result.stdout.toString());
      }
      
      if (result.stderr.toString().isNotEmpty) {
        log.writeln('=== Stderr ===');
        log.writeln(result.stderr.toString());
      }

      return CommandResult(
        success: result.exitCode == 0,
        output: log.toString(),
      );
    } catch (e, stackTrace) {
      log.writeln('');
      log.writeln('=== Exception ===');
      log.writeln('Error: $e');
      log.writeln('');
      log.writeln('Stack Trace:');
      log.writeln(stackTrace.toString());
      
      return CommandResult(
        success: false,
        output: log.toString(),
      );
    }
  }
}

class CommandResult {
  final bool success;
  final String output;

  CommandResult({required this.success, required this.output});
}
