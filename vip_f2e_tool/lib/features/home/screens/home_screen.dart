import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/services/dependency_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../pr_compare/screens/pr_compare_screen.dart';
import '../../redpen_ci/screens/redpen_home_screen.dart';
import '../../cherry_pick/screens/cherry_pick_screen.dart';
import '../../worklog/screens/worklog_home_screen.dart';
import '../../startup/screens/dependency_check_screen.dart';

/// Main home screen with tool selection
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _version = '';
  bool _isCheckingUpdate = false;
  bool _isUpdating = false;
  bool _hasUpdate = false;
  String? _updateMessage;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = 'v${info.version}';
      });
    } catch (_) {
      setState(() {
        _version = 'v1.0.0';
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateMessage = null;
      _hasUpdate = false;
    });

    try {
      final dependencyService = DependencyService();
      final brewPath = await dependencyService.findCommandPath('brew') ?? 'brew';
      
      // Run brew update first
      await Process.run(brewPath, ['update'], runInShell: true);
      
      // Then check if vip-f2e-tool is outdated
      final result = await Process.run(
        brewPath,
        ['outdated', '--cask', 'vip-f2e-tool'],
        runInShell: true,
      );

      if (result.stdout.toString().contains('vip-f2e-tool')) {
        setState(() {
          _updateMessage = '有新版本可用！';
          _hasUpdate = true;
        });
      } else {
        setState(() {
          _updateMessage = '已是最新版本 ✓';
          _hasUpdate = false;
        });
      }
    } catch (e) {
      setState(() {
        _updateMessage = '檢查更新失敗';
        _hasUpdate = false;
      });
    } finally {
      setState(() {
        _isCheckingUpdate = false;
      });
    }
  }

  Future<void> _performUpdate() async {
    setState(() {
      _isUpdating = true;
      _updateMessage = '正在更新...';
    });

    try {
      final dependencyService = DependencyService();
      final brewPath = await dependencyService.findCommandPath('brew') ?? 'brew';

      // Run the upgrade command
      final result = await Process.run(
        brewPath,
        ['upgrade', '--cask', 'vip-f2e-tool'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        setState(() {
          _updateMessage = '更新完成！請重新啟動應用程式。';
          _hasUpdate = false;
        });
        
        // Show dialog to restart
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('更新完成'),
              content: const Text('應用程式已更新，請重新啟動以使用新版本。'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    // Exit the app
                    exit(0);
                  },
                  child: const Text('關閉應用程式'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          _updateMessage = '更新失敗: ${result.stderr}';
        });
      }
    } catch (e) {
      setState(() {
        _updateMessage = '更新失敗: $e';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VIP F2E Tool'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.build_circle_outlined),
            tooltip: '依賴檢查',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DependencyCheckScreen(isStartupCheck: false)),
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _ToolCard(
                      title: 'PR Commit 比對',
                      description: '比對 Staging 和 Production PR 的 commit，確認 cherry-pick 是否完整',
                      icon: Icons.compare_arrows,
                      color: AppTheme.accentPurple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrCompareScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ToolCard(
                      title: 'RedPen CI',
                      description: '靜態程式碼分析工具，掃描多個 Repository 的程式碼品質',
                      icon: Icons.security,
                      color: AppTheme.accentBlue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RedpenHomeScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ToolCard(
                      title: '發車工具',
                      description: 'Cherry-pick 發車工具，批次處理多個 commit 到目標分支',
                      icon: Icons.directions_bus,
                      color: AppTheme.accentOrange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CherryPickScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ToolCard(
                      title: '統一會議工時',
                      description: '批次記錄團隊成員的 Jira 工時，支援樣板快速填入',
                      icon: Icons.timer,
                      color: AppTheme.accentGreen,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WorklogHomeScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              // Version and update section
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _version,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                    icon: _isCheckingUpdate
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 16),
                    label: Text(_isCheckingUpdate ? '檢查中...' : '檢查更新'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (_updateMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _updateMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _updateMessage!.contains('有新版本') || _updateMessage!.contains('正在')
                        ? AppTheme.accentOrange
                        : _updateMessage!.contains('失敗')
                            ? AppTheme.accentRed
                            : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (_hasUpdate && !_isUpdating) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _performUpdate,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('立即更新'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: _isHovered
            ? (Matrix4.identity()..scale(1.01))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: _isHovered ? 4 : 0,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Left: Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 32,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Center: Title and Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right: Arrow
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
