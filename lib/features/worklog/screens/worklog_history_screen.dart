import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/worklog_history.dart';
import '../services/jira_service.dart';
import '../services/worklog_storage_service.dart';

class WorklogHistoryScreen extends StatefulWidget {
  const WorklogHistoryScreen({super.key});

  @override
  State<WorklogHistoryScreen> createState() => _WorklogHistoryScreenState();
}

class _WorklogHistoryScreenState extends State<WorklogHistoryScreen> {
  final _storageService = WorklogStorageService();
  final _jiraService = JiraService();

  List<WorklogHistory> _histories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _storageService.init();
    setState(() {
      _histories = _storageService.histories;
      _isLoading = false;
    });
  }

  Future<void> _undoItem(WorklogHistory history, WorklogHistoryItem item) async {
    final member = _storageService.getMemberById(item.memberId);
    if (member == null) {
      _showError('找不到該成員設定，可能已被刪除，撤銷失敗');
      return;
    }

    final confirm = await _showConfirmDialog('確定要撤銷 ${item.memberName} 的單筆工時紀錄嗎？');
    if (!confirm) return;

    _showLoadingDialog();

    final result = await _jiraService.deleteWorklog(
      _storageService.jiraDomain,
      member,
      history.issueKey,
      item.worklogId,
    );

    _hideLoadingDialog();

    if (result.success) {
      setState(() {
        item.isUndone = true;
        _storageService.updateHistory(history);
      });
      _showSuccess('已成功撤銷單筆工時');
    } else {
      _showError('撤銷失敗：${result.message}');
    }
  }

  Future<void> _undoBatch(WorklogHistory history) async {
    final itemsToUndo = history.items.where((i) => !i.isUndone).toList();
    if (itemsToUndo.isEmpty) return;

    final confirm = await _showConfirmDialog('確定要撤銷這批剩餘成員（共 ${itemsToUndo.length} 人）的工時紀錄嗎？');
    if (!confirm) return;

    _showLoadingDialog();

    int successCount = 0;
    int failCount = 0;

    for (var item in itemsToUndo) {
      final member = _storageService.getMemberById(item.memberId);
      if (member == null) {
        failCount++;
        continue;
      }
      final result = await _jiraService.deleteWorklog(
        _storageService.jiraDomain,
        member,
        history.issueKey,
        item.worklogId,
      );
      
      if (result.success) {
        successCount++;
        setState(() {
          item.isUndone = true;
        });
      } else {
        failCount++;
      }
      
      // 加入延遲避免觸發 Jira API 限流
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    _storageService.updateHistory(history);
    _hideLoadingDialog();

    if (failCount > 0) {
      _showError('撤銷完畢：成功 $successCount 筆，失敗 $failCount 筆');
    } else {
      _showSuccess('已成功撤銷整批工時');
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認撤銷'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed, foregroundColor: Colors.white),
            child: const Text('確認撤銷'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16)
          ),
          child: const CircularProgressIndicator(),
        )
      ),
    );
  }

  void _hideLoadingDialog() {
    Navigator.pop(context);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accentGreen),
    );
  }

  Widget _buildHistoryCard(WorklogHistory history) {
    final formattedDate = '${history.createdAt.year}/${history.createdAt.month.toString().padLeft(2, '0')}/${history.createdAt.day.toString().padLeft(2, '0')} ${history.createdAt.hour.toString().padLeft(2, '0')}:${history.createdAt.minute.toString().padLeft(2, '0')}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        history.issueKey,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: history.isAllUndone ? Colors.grey.shade300 : AppTheme.accentGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          history.isAllUndone ? '已全數撤銷' : '紀錄有效',
                          style: TextStyle(
                            fontSize: 12,
                            color: history.isAllUndone ? Colors.grey.shade700 : AppTheme.accentGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    history.comment.isEmpty ? '（無備註）' : history.comment,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (!history.isAllUndone)
              TextButton.icon(
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('全批撤銷'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
                onPressed: () => _undoBatch(history),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '時間: $formattedDate  |  總計: ${history.minutes} 分鐘  |  成功寄送: ${history.items.length} 人',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        children: [
          const Divider(height: 1),
          ...history.items.map((item) => ListTile(
            dense: true,
            leading: Icon(
              item.isUndone ? Icons.cancel : Icons.check_circle,
              color: item.isUndone ? Colors.grey : AppTheme.accentGreen,
              size: 20,
            ),
            title: Text(
              item.memberName,
              style: TextStyle(
                decoration: item.isUndone ? TextDecoration.lineThrough : null,
                color: item.isUndone ? Colors.grey : null,
              ),
            ),
            trailing: item.isUndone
                ? const Text('已撤銷', style: TextStyle(color: Colors.grey, fontSize: 12))
                : IconButton(
                    icon: const Icon(Icons.undo, size: 20),
                    tooltip: '撤銷單筆',
                    color: AppTheme.accentRed,
                    onPressed: () => _undoItem(history, item),
                  ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('操作紀錄管理'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _histories.isEmpty
              ? const Center(
                  child: Text(
                    '尚無任何歷程紀錄',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _histories.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(_histories[index]);
                      },
                    ),
                  ),
                ),
    );
  }
}
