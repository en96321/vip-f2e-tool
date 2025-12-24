import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../services/cherry_pick_manager.dart';

/// Widget to display the log output
class LogPanel extends ConsumerWidget {
  const LogPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(appStateProvider.select((s) => s.logs));

    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '執行日誌將會顯示在這裡',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              log.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: _getLogColor(log.level),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.white70;
      case LogLevel.success:
        return Colors.greenAccent;
      case LogLevel.warning:
        return Colors.orangeAccent;
      case LogLevel.error:
        return Colors.redAccent;
    }
  }
}
