import 'package:flutter/material.dart';
import '../models/team_member.dart';
import '../models/worklog_template.dart';

/// 新增/編輯樣板的對話框
class TemplateEditDialog extends StatefulWidget {
  final WorklogTemplate? template;
  final List<TeamMember> allMembers;

  const TemplateEditDialog({
    super.key,
    this.template,
    required this.allMembers,
  });

  @override
  State<TemplateEditDialog> createState() => _TemplateEditDialogState();
}

class _TemplateEditDialogState extends State<TemplateEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _issueKeyController;
  late final TextEditingController _minutesController;
  late final TextEditingController _commentController;
  late TimeOfDay _selectedTime;
  late Set<String> _selectedMemberIds;

  bool get isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _issueKeyController = TextEditingController(text: widget.template?.issueKey ?? '');
    _minutesController = TextEditingController(
      text: widget.template?.minutes.toString() ?? '60',
    );
    _commentController = TextEditingController(text: widget.template?.comment ?? '');
    _selectedTime = widget.template?.defaultTime ?? const TimeOfDay(hour: 9, minute: 0);
    _selectedMemberIds = Set.from(widget.template?.selectedMemberIds ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issueKeyController.dispose();
    _minutesController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫樣板名稱')),
      );
      return;
    }

    final template = WorklogTemplate(
      id: widget.template?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      issueKey: _issueKeyController.text.trim(),
      minutes: int.tryParse(_minutesController.text.trim()) ?? 60,
      comment: _commentController.text.trim(),
      defaultTime: _selectedTime,
      selectedMemberIds: _selectedMemberIds.toList(),
    );

    Navigator.of(context).pop(template);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? '編輯樣板' : '新增樣板'),
      content: SizedBox(
        width: 450,
        height: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '樣板名稱 *',
                  hintText: '例如：Daily',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _issueKeyController,
                decoration: const InputDecoration(
                  labelText: '預設 Jira 單號',
                  hintText: '例如：CPM-27966',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minutesController,
                      decoration: const InputDecoration(
                        labelText: '預設時數（分鐘）',
                        hintText: '60',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '預設時間',
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedTime.format(context)),
                            const Icon(Icons.access_time, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: '預設備註',
                  hintText: '例如：統一會議',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              const Text(
                '預設勾選成員',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.allMembers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '尚未新增任何成員',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.allMembers.length,
                      itemBuilder: (context, index) {
                        final member = widget.allMembers[index];
                        final isSelected = _selectedMemberIds.contains(member.id);
                        return CheckboxListTile(
                          title: Text(member.name),
                          subtitle: Text(member.email, style: const TextStyle(fontSize: 12)),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedMemberIds.add(member.id);
                              } else {
                                _selectedMemberIds.remove(member.id);
                              }
                            });
                          },
                          dense: true,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? '儲存' : '新增'),
        ),
      ],
    );
  }
}
