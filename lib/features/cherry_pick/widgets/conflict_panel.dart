import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';

/// Widget for conflict resolution actions
class ConflictPanel extends ConsumerWidget {
  const ConflictPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appStateProvider.select((s) => s.status));

    if (status != AppStatus.conflict) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(appStateProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 24),
              const SizedBox(width: 8),
              Text(
                '發生衝突！',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '請依照以下步驟解決衝突:',
            style: TextStyle(color: Colors.red[900], fontSize: 13),
          ),
          const SizedBox(height: 8),
          _buildStep('1', '手動解決衝突檔案'),
          _buildStep('2', '執行: git add .'),
          _buildStep('3', '執行: git cherry-pick --continue'),
          _buildStep('4', '點擊下方「繼續」按鈕'),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.terminal),
                label: const Text('開啟 Terminal'),
                onPressed: notifier.openTerminal,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.code),
                label: const Text('開啟 VS Code'),
                onPressed: notifier.openVSCode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('中止'),
                onPressed: notifier.abortCherryPick,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('繼續'),
                onPressed: notifier.continueFromProgress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: Colors.red[900], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
