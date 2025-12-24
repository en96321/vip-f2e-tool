import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/history_service.dart';
import '../models/execution_record.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  final HistoryService historyService;

  const HistoryScreen({super.key, required this.historyService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ExecutionRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _records = widget.historyService.getHistory();
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除紀錄'),
        content: const Text('確定要清除所有執行紀錄嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.historyService.clearHistory();
      _loadHistory();
    }
  }

  void _showDetail(ExecutionRecord record) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              record.success ? Icons.check_circle : Icons.error,
              color: record.success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                record.repo,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Repo', record.repo),
                _buildInfoRow('Commit', record.commitHash),
                _buildInfoRow('時間', dateFormat.format(record.timestamp)),
                const SizedBox(height: 12),
                const Text('回應內容：', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      record.response.isEmpty ? '(無輸出)' : record.response,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: record.response));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已複製到剪貼簿')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('複製回應'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('執行紀錄'),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '清除紀錄',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _records.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('尚無執行紀錄', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      record.success ? Icons.check_circle : Icons.error,
                      color: record.success ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      record.repo,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${record.commitHash.substring(0, record.commitHash.length > 8 ? 8 : record.commitHash.length)}... • ${dateFormat.format(record.timestamp)}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: '複製回應',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: record.response));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已複製到剪貼簿')),
                        );
                      },
                    ),
                    onTap: () => _showDetail(record),
                  ),
                );
              },
            ),
    );
  }
}
