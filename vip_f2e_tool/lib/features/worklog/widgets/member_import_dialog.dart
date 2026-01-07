import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/team_member.dart';

/// 批次匯入成員對話框
/// 支援從 Excel 複製貼上，格式：姓名\tToken\tEmail
class MemberImportDialog extends StatefulWidget {
  const MemberImportDialog({super.key});

  @override
  State<MemberImportDialog> createState() => _MemberImportDialogState();
}

class _MemberImportDialogState extends State<MemberImportDialog> {
  final _controller = TextEditingController();
  List<TeamMember> _parsed = [];
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _parsed = [];
        _error = null;
      });
      return;
    }

    final lines = text.split('\n');
    final members = <TeamMember>[];
    final errors = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // 嘗試用 Tab 分割
      final parts = line.split('\t');
      
      if (parts.length >= 3) {
        // 格式: 姓名\tToken\tEmail
        final name = parts[0].trim();
        final token = parts[1].trim();
        final email = parts[2].trim();

        if (name.isNotEmpty && token.isNotEmpty && email.isNotEmpty) {
          members.add(TeamMember(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            name: name,
            email: email,
            token: token,
          ));
        } else {
          errors.add('第 ${i + 1} 行：資料不完整');
        }
      } else {
        errors.add('第 ${i + 1} 行：格式錯誤（需要姓名、Token、Email）');
      }
    }

    setState(() {
      _parsed = members;
      _error = errors.isNotEmpty ? errors.join('\n') : null;
    });
  }

  void _import() {
    if (_parsed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有可匯入的成員')),
      );
      return;
    }
    Navigator.of(context).pop(_parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('批次匯入成員'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '從 Excel 複製資料貼上，格式：\n姓名 [Tab] Token [Tab] Email',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '貼上資料...\n\n範例：\nAgnes Kao 高慈謙\tATATT3xF...\tagnes.kao@104.com.tw\nBrian Chao 趙軒弘\tATATT3xF...\tbrian.chao@104.com.tw',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => _parse(),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ),
            if (_parsed.isNotEmpty) ...[
              const Divider(),
              Text(
                '預覽：${_parsed.length} 位成員',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 100),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _parsed.length,
                  itemBuilder: (context, index) {
                    final member = _parsed[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${member.name} (${member.email})',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _parsed.isEmpty ? null : _import,
          child: Text('匯入 ${_parsed.isEmpty ? "" : "(${_parsed.length})"}'),
        ),
      ],
    );
  }
}
