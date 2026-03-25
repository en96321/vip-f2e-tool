import 'package:flutter/material.dart';
import '../models/team_member.dart';

/// 新增/編輯成員的對話框
class MemberEditDialog extends StatefulWidget {
  final TeamMember? member;

  const MemberEditDialog({super.key, this.member});

  @override
  State<MemberEditDialog> createState() => _MemberEditDialogState();
}

class _MemberEditDialogState extends State<MemberEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _tokenController;
  bool _obscureToken = true;

  bool get isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _emailController = TextEditingController(text: widget.member?.email ?? '');
    _tokenController = TextEditingController(text: widget.member?.token ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();

    if (name.isEmpty || email.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫所有欄位')),
      );
      return;
    }

    final member = TeamMember(
      id: widget.member?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      token: token,
      isEnabled: widget.member?.isEnabled ?? true,
    );

    Navigator.of(context).pop(member);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? '編輯成員' : '新增成員'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                hintText: '例如：王小明',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Jira Email',
                hintText: '例如：user@104.com.tw',
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Jira API Token',
                hintText: '從 Atlassian 取得的 API Token',
                suffixIcon: IconButton(
                  icon: Icon(_obscureToken ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureToken = !_obscureToken),
                ),
              ),
              obscureText: _obscureToken,
            ),
          ],
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
