import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../widgets/config_panel.dart';
import '../widgets/commit_list.dart';
import '../widgets/log_panel.dart';
import '../widgets/conflict_panel.dart';

/// Cherry Pick Screen - Release Tool
class CherryPickScreen extends ConsumerWidget {
  const CherryPickScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.directions_bus, size: 28, color: Colors.orange[400]),
            const SizedBox(width: 8),
            const Text('發車工具'),
          ],
        ),
        actions: [
          if (appState.savedProgress != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.save, size: 16, color: Colors.orange),
                label: const Text('有未完成的進度'),
                backgroundColor: Colors.orange.withOpacity(0.2),
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Configuration
          SizedBox(
            width: 400,
            child: Column(
              children: [
                const Expanded(child: SingleChildScrollView(child: ConfigPanel())),
                _buildActionButtons(appState, notifier),
              ],
            ),
          ),

          // Divider
          const VerticalDivider(width: 1),

          // Right Panel - Commits and Logs
          Expanded(
            child: Column(
              children: [
                // Saved progress banner
                if (appState.savedProgress != null)
                  _buildSavedProgressBanner(appState, notifier),

                // Conflict panel
                const ConflictPanel(),

                // Commits list
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.commit, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Commits (${appState.commits.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            _buildStatusIndicator(appState),
                          ],
                        ),
                      ),
                      const Expanded(child: CommitListWidget()),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Logs panel
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.terminal, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              '執行日誌',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            if (appState.logs.isNotEmpty)
                              TextButton.icon(
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('清除'),
                                onPressed: notifier.clearLogs,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Expanded(child: Padding(
                        padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: LogPanel(),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppState appState, AppStateNotifier notifier) {
    final isWorking = appState.status == AppStatus.searching ||
        appState.status == AppStatus.preparing ||
        appState.status == AppStatus.cherryPicking;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                icon: isWorking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 18),
                label: const Text('搜尋', overflow: TextOverflow.ellipsis),
                onPressed: isWorking ? null : notifier.searchCommits,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                icon: isWorking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow, size: 18),
                label: const Text('Cherry-pick', overflow: TextOverflow.ellipsis),
                onPressed: isWorking || appState.commits.isEmpty
                    ? null
                    : notifier.executeCherryPick,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedProgressBanner(AppState appState, AppStateNotifier notifier) {
    final progress = appState.savedProgress!;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '發現未完成的 cherry-pick 任務',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tickets: ${progress.tickets.join(", ")} | '
                  '進度: ${progress.currentIndex}/${progress.totalCommits}',
                  style: TextStyle(fontSize: 12, color: Colors.blue[200]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: notifier.abortCherryPick,
            child: const Text('放棄'),
          ),
          ElevatedButton(
            onPressed: notifier.continueFromProgress,
            child: const Text('繼續'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(AppState appState) {
    Color color;
    String text;
    IconData icon;

    switch (appState.status) {
      case AppStatus.idle:
        return const SizedBox.shrink();
      case AppStatus.searching:
        color = Colors.blue;
        text = '搜尋中...';
        icon = Icons.search;
        break;
      case AppStatus.preparing:
        color = Colors.orange;
        text = '準備中...';
        icon = Icons.sync;
        break;
      case AppStatus.cherryPicking:
        color = Colors.blue;
        text = '執行中...';
        icon = Icons.play_circle;
        break;
      case AppStatus.conflict:
        color = Colors.red;
        text = '發生衝突';
        icon = Icons.warning;
        break;
      case AppStatus.completed:
        color = Colors.green;
        text = '已完成';
        icon = Icons.check_circle;
        break;
      case AppStatus.error:
        color = Colors.red;
        text = '錯誤';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
