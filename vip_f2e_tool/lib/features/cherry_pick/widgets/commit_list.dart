import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/commit.dart';
import '../providers/app_state.dart';

/// Widget to display the list of commits with their status
class CommitListWidget extends ConsumerWidget {
  const CommitListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commits = ref.watch(appStateProvider.select((s) => s.commits));

    if (commits.isEmpty) {
      return const Center(
        child: Text(
          '尚未搜尋 commits\n請輸入 Ticket 號碼或 Commit Hash 後點擊搜尋',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: commits.length,
      itemBuilder: (context, index) {
        final commit = commits[index];
        return _CommitTile(commit: commit, index: index);
      },
    );
  }
}

class _CommitTile extends StatelessWidget {
  final Commit commit;
  final int index;

  const _CommitTile({required this.commit, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          commit.message,
          style: const TextStyle(fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          commit.shortHash,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        trailing: _buildStatusChip(),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: _getStatusColor(),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 14, color: _getStatusColor()),
          const SizedBox(width: 4),
          Text(
            commit.status.displayName,
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (commit.status) {
      case CherryPickStatus.pending:
        return Colors.grey;
      case CherryPickStatus.applying:
        return Colors.blue;
      case CherryPickStatus.applied:
        return Colors.green;
      case CherryPickStatus.skipped:
        return Colors.orange;
      case CherryPickStatus.conflict:
        return Colors.red;
      case CherryPickStatus.error:
        return Colors.red;
    }
  }

  Color _getBackgroundColor() {
    switch (commit.status) {
      case CherryPickStatus.applied:
        return Colors.green.withValues(alpha: 0.05);
      case CherryPickStatus.skipped:
        return Colors.orange.withValues(alpha: 0.05);
      case CherryPickStatus.conflict:
      case CherryPickStatus.error:
        return Colors.red.withValues(alpha: 0.05);
      default:
        return Colors.transparent;
    }
  }

  Color _getBorderColor() {
    switch (commit.status) {
      case CherryPickStatus.applying:
        return Colors.blue.withValues(alpha: 0.5);
      case CherryPickStatus.conflict:
        return Colors.red.withValues(alpha: 0.5);
      default:
        return Colors.grey.withValues(alpha: 0.2);
    }
  }

  IconData _getStatusIcon() {
    switch (commit.status) {
      case CherryPickStatus.pending:
        return Icons.schedule;
      case CherryPickStatus.applying:
        return Icons.sync;
      case CherryPickStatus.applied:
        return Icons.check_circle;
      case CherryPickStatus.skipped:
        return Icons.skip_next;
      case CherryPickStatus.conflict:
        return Icons.warning;
      case CherryPickStatus.error:
        return Icons.error;
    }
  }
}
