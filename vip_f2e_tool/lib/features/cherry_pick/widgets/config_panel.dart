import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../models/environment.dart';
import '../providers/app_state.dart';

/// Configuration panel for environment and branch settings
class ConfigPanel extends ConsumerStatefulWidget {
  const ConfigPanel({super.key});

  @override
  ConsumerState<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends ConsumerState<ConfigPanel> {
  late TextEditingController _inputController;
  late TextEditingController _baseBranchController;
  late TextEditingController _sourceBranchController;
  late TextEditingController _targetBranchController;
  late TextEditingController _ticketPrefixController;

  @override
  void initState() {
    super.initState();
    final appState = ref.read(appStateProvider);
    _inputController = TextEditingController(text: appState.inputText);
    _baseBranchController = TextEditingController(text: appState.baseBranch);
    _sourceBranchController = TextEditingController(text: appState.sourceBranch);
    _targetBranchController = TextEditingController(text: appState.targetBranch);
    _ticketPrefixController = TextEditingController(text: appState.ticketPrefix);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _baseBranchController.dispose();
    _sourceBranchController.dispose();
    _targetBranchController.dispose();
    _ticketPrefixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    // Update controllers if state changes from outside (e.g., environment change or repo change)
    if (_baseBranchController.text != appState.baseBranch) {
      _baseBranchController.text = appState.baseBranch;
    }
    if (_sourceBranchController.text != appState.sourceBranch) {
      _sourceBranchController.text = appState.sourceBranch;
    }
    if (_targetBranchController.text != appState.targetBranch) {
      _targetBranchController.text = appState.targetBranch;
    }
    if (_ticketPrefixController.text != appState.ticketPrefix) {
      _ticketPrefixController.text = appState.ticketPrefix;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Working Directory Section
            _buildSectionHeader('工作目錄', Icons.folder),
            const SizedBox(height: 8),
            _buildDirectorySelector(context, appState, notifier),

            const SizedBox(height: 20),

            // Environment Section
            _buildSectionHeader('環境配置', Icons.settings),
            const SizedBox(height: 8),
            _buildEnvironmentSelector(appState, notifier),

            const SizedBox(height: 16),

            // Ticket Prefix Configuration
            TextField(
              decoration: const InputDecoration(
                labelText: 'Ticket Prefix (例如: VIPOP)',
                helperText: '搜尋時會自動處理此外綴',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              controller: _ticketPrefixController,
              onChanged: notifier.setTicketPrefix,
            ),

            const SizedBox(height: 16),

            // Base Branch Configuration
            TextField(
              decoration: const InputDecoration(
                labelText: '基礎分支 (目標分支會從此分支拉出)',
                helperText: '例如: staging 或 production',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              controller: _baseBranchController,
              onChanged: notifier.setBaseBranch,
            ),

            const SizedBox(height: 16),

            // Branch Configuration
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '來源分支',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    controller: _sourceBranchController,
                    onChanged: notifier.setSourceBranch,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '目標分支',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    controller: _targetBranchController,
                    onChanged: notifier.setTargetBranch,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Input Section
            _buildSectionHeader('Tickets / Commits', Icons.label),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: '輸入 ticket 號碼或 commit hash (例如: 41209 或 ${appState.ticketPrefix}-41209)',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              controller: _inputController,
              onChanged: notifier.setInputText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDirectorySelector(
    BuildContext context,
    AppState appState,
    AppStateNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  appState.workingDirectory ?? '尚未選擇目錄',
                  style: TextStyle(
                    color: appState.workingDirectory != null
                        ? Colors.black87
                        : Colors.grey,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('選擇'),
              onPressed: () => _selectDirectory(context, notifier),
            ),
          ],
        ),

        // Recent directories
        if (appState.recentDirectories.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: appState.recentDirectories.map((dir) {
              final isSelected = dir == appState.workingDirectory;
              return ActionChip(
                avatar: Icon(
                  isSelected ? Icons.check_circle : Icons.history,
                  size: 16,
                  color: isSelected ? Colors.green : Colors.grey,
                ),
                label: Text(
                  dir.split('/').last,
                  style: const TextStyle(fontSize: 11),
                ),
                onPressed: () => notifier.setWorkingDirectory(dir),
                backgroundColor: isSelected ? Colors.green[50] : null,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDirectory(
    BuildContext context,
    AppStateNotifier notifier,
  ) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final success = await notifier.setWorkingDirectory(result);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('選擇的目錄不是有效的 Git Repository'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEnvironmentSelector(AppState appState, AppStateNotifier notifier) {
    return SegmentedButton<Environment>(
      segments: Environments.all.map((env) {
        return ButtonSegment<Environment>(
          value: env,
          label: Text(env.name),
          tooltip: env.description,
        );
      }).toList(),
      selected: {appState.selectedEnvironment},
      onSelectionChanged: (selected) {
        notifier.setEnvironment(selected.first);
      },
    );
  }
}
