import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/dependency_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../cherry_pick/screens/cherry_pick_screen.dart';
import '../../pr_compare/screens/pr_compare_screen.dart';
import '../../redpen_ci/screens/redpen_home_screen.dart';
import '../../redpen_report/screens/redpen_report_screen.dart';
import '../../startup/screens/dependency_check_screen.dart';
import '../../worklog/screens/worklog_home_screen.dart';

class ToolItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final WidgetBuilder screenBuilder;

  ToolItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screenBuilder,
  });
}

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

  bool _isGridMode = false;
  List<ToolItem> _tools = [];

  final List<ToolItem> _defaultTools = [
    ToolItem(
      id: 'pr_compare',
      title: 'PR Commit 比對',
      description: '比對 Staging 和 Production PR 的 commit，確認 cherry-pick 是否完整',
      icon: Icons.compare_arrows,
      color: AppTheme.accentPurple,
      screenBuilder: (_) => const PrCompareScreen(),
    ),
    ToolItem(
      id: 'redpen_ci',
      title: 'RedPen CI',
      description: '靜態程式碼分析工具，掃描多個 Repository 的程式碼品質',
      icon: Icons.security,
      color: AppTheme.accentBlue,
      screenBuilder: (_) => const RedpenHomeScreen(),
    ),
    ToolItem(
      id: 'cherry_pick',
      title: '發車工具',
      description: 'Cherry-pick 發車工具，批次處理多個 commit 到目標分支',
      icon: Icons.directions_bus,
      color: AppTheme.accentOrange,
      screenBuilder: (_) => const CherryPickScreen(),
    ),
    ToolItem(
      id: 'worklog',
      title: '統一會議工時',
      description: '批次記錄團隊成員的 Jira 工時，支援樣板快速填入',
      icon: Icons.timer,
      color: AppTheme.accentGreen,
      screenBuilder: (_) => const WorklogHomeScreen(),
    ),
    ToolItem(
      id: 'redpen_report',
      title: 'RedPen 報告合併',
      description: '合併新舊 RedPen 掃描報告，自動複製歷史 Comment 並標記新問題',
      icon: Icons.merge,
      color: AppTheme.accentRed,
      screenBuilder: (_) => const RedpenReportScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridMode = prefs.getBool('is_grid_mode') ?? false;
      final savedOrder = prefs.getStringList('tool_order');
      if (savedOrder != null && savedOrder.isNotEmpty) {
        _tools = [];
        for (var id in savedOrder) {
          try {
            final tool = _defaultTools.firstWhere((t) => t.id == id);
            _tools.add(tool);
          } catch (_) {}
        }
        for (var tool in _defaultTools) {
          if (!_tools.any((t) => t.id == tool.id)) {
            _tools.add(tool);
          }
        }
      } else {
        _tools = List.from(_defaultTools);
      }
    });
  }

  Future<void> _toggleViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridMode = !_isGridMode;
    });
    await prefs.setBool('is_grid_mode', _isGridMode);
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tool_order', _tools.map((t) => t.id).toList());
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _tools.removeAt(oldIndex);
      _tools.insert(newIndex, item);
    });
    _saveOrder();
  }

  void _onReorderGrid(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    setState(() {
      final item = _tools.removeAt(oldIndex);
      _tools.insert(newIndex, item);
    });
    _saveOrder();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = 'v${info.version}';
      setState(() {
        _version = currentVersion;
      });
      _checkAndShowChangelog(currentVersion);
    } catch (_) {
      setState(() {
        _version = 'v1.0.0';
      });
    }
  }

  Future<void> _checkAndShowChangelog(String currentVersion) async {
    final prefs = await SharedPreferences.getInstance();
    final lastVersion = prefs.getString('last_changelog_version');
    
    if (lastVersion != currentVersion) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showChangelogDialog();
        });
      }
      await prefs.setString('last_changelog_version', currentVersion);
    }
  }

  void _showChangelogDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更新日誌'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('v1.0.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 8),
              Text('• 新增：首頁新增切換版型、並可以調整排序'),
              Text('• 新增：首頁加入版本更新日誌與 GitHub 連結')
              // 在發布新版本時，直接修改或新增此處的文字內容
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
        ],
      ),
    );
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

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法開啟連結: $urlString')),
        );
      }
    }
  }

  Widget _buildListView() {
    return ReorderableListView(
      buildDefaultDragHandles: false,
      onReorder: _onReorder,
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        return Material(
          elevation: 8,
          color: Colors.transparent,
          child: child,
        );
      },
      children: _tools.asMap().entries.map((entry) {
        final index = entry.key;
        final tool = entry.value;
        return Padding(
          key: ValueKey(tool.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: ReorderableDelayedDragStartListener(
            index: index,
            child: _ToolCard(
              title: tool.title,
              description: tool.description,
              icon: tool.icon,
              color: tool.color,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: tool.screenBuilder),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridView() {
    return SingleChildScrollView(
      child: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _tools.asMap().entries.map((entry) {
            final index = entry.key;
            final tool = entry.value;
            return DragTarget<int>(
              key: ValueKey(tool.id),
              onAcceptWithDetails: (details) {
                _onReorderGrid(details.data, index);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovered = candidateData.isNotEmpty;
                return LongPressDraggable<int>(
                  data: index,
                  feedback: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.transparent,
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: _ToolGridCard(
                        title: tool.title,
                        icon: tool.icon,
                        color: tool.color,
                        onTap: null,
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: _ToolGridCard(
                        title: tool.title,
                        icon: tool.icon,
                        color: tool.color,
                        onTap: null,
                      ),
                    ),
                  ),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: isHovered
                        ? BoxDecoration(
                            border: Border.all(
                                color: AppTheme.accentPurple, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          )
                        : null,
                    child: _ToolGridCard(
                      title: tool.title,
                      icon: tool.icon,
                      color: tool.color,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: tool.screenBuilder),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tools.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('VIP F2E Tool'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridMode ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridMode ? '切換列表顯示' : '切換方格顯示',
            onPressed: _toggleViewMode,
          ),
          IconButton(
            icon: const Icon(Icons.build_circle_outlined),
            tooltip: '依賴檢查',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const DependencyCheckScreen(isStartupCheck: false)),
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
                child: _isGridMode ? _buildGridView() : _buildListView(),
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
                    onPressed: _showChangelogDialog,
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('更新日誌'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _launchURL('https://github.com/en96321/vip-f2e-tool'),
                    icon: const Icon(Icons.code, size: 16),
                    label: const Text('GitHub'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 4),
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
                    color: _updateMessage!.contains('有新版本') ||
                            _updateMessage!.contains('正在')
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
            ? Matrix4.diagonal3Values(1.01, 1.01, 1.01)
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
                      color: widget.color.withValues(alpha: 0.1),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolGridCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ToolGridCard({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_ToolGridCard> createState() => _ToolGridCardState();
}

class _ToolGridCardState extends State<_ToolGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: _isHovered && widget.onTap != null
            ? Matrix4.diagonal3Values(1.02, 1.02, 1.02)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: _isHovered && widget.onTap != null ? 4 : 0,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 32,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
