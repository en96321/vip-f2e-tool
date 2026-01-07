import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/team_member.dart';
import '../models/worklog_template.dart';
import '../services/worklog_storage_service.dart';
import '../widgets/member_edit_dialog.dart';
import '../widgets/member_import_dialog.dart';
import '../widgets/template_edit_dialog.dart';

/// 工時記錄設定畫面
/// 管理成員清單和樣板設定
class WorklogSettingsScreen extends StatefulWidget {
  const WorklogSettingsScreen({super.key});

  @override
  State<WorklogSettingsScreen> createState() => _WorklogSettingsScreenState();
}

class _WorklogSettingsScreenState extends State<WorklogSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storageService = WorklogStorageService();
  bool _isLoading = true;

  List<TeamMember> _members = [];
  List<WorklogTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _storageService.init();
    setState(() {
      _members = _storageService.members;
      _templates = _storageService.templates;
      _isLoading = false;
    });
  }

  // ==================== 成員管理 ====================

  Future<void> _addMember() async {
    final result = await showDialog<TeamMember>(
      context: context,
      builder: (_) => const MemberEditDialog(),
    );
    if (result != null) {
      _storageService.addMember(result);
      setState(() => _members = _storageService.members);
    }
  }

  Future<void> _importMembers() async {
    final result = await showDialog<List<TeamMember>>(
      context: context,
      builder: (_) => const MemberImportDialog(),
    );
    if (result != null && result.isNotEmpty) {
      for (final member in result) {
        _storageService.addMember(member);
      }
      setState(() => _members = _storageService.members);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已匯入 ${result.length} 位成員')),
        );
      }
    }
  }

  Future<void> _editMember(TeamMember member) async {
    final result = await showDialog<TeamMember>(
      context: context,
      builder: (_) => MemberEditDialog(member: member),
    );
    if (result != null) {
      _storageService.updateMember(result);
      setState(() => _members = _storageService.members);
    }
  }

  Future<void> _deleteMember(TeamMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除「${member.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _storageService.removeMember(member.id);
      setState(() => _members = _storageService.members);
    }
  }

  // ==================== 樣板管理 ====================

  Future<void> _addTemplate() async {
    final result = await showDialog<WorklogTemplate>(
      context: context,
      builder: (_) => TemplateEditDialog(allMembers: _members),
    );
    if (result != null) {
      _storageService.addTemplate(result);
      setState(() => _templates = _storageService.templates);
    }
  }

  Future<void> _editTemplate(WorklogTemplate template) async {
    final result = await showDialog<WorklogTemplate>(
      context: context,
      builder: (_) => TemplateEditDialog(
        template: template,
        allMembers: _members,
      ),
    );
    if (result != null) {
      _storageService.updateTemplate(result);
      setState(() => _templates = _storageService.templates);
    }
  }

  Future<void> _deleteTemplate(WorklogTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除樣板「${template.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _storageService.removeTemplate(template.id);
      setState(() => _templates = _storageService.templates);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工時設定'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '成員管理'),
            Tab(text: '樣板管理'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(),
                _buildTemplatesTab(),
              ],
            ),
    );
  }

  Widget _buildMembersTab() {
    return Column(
      children: [
        Expanded(
          child: _members.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('尚未新增任何成員', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
                          child: Text(
                            member.name.isNotEmpty ? member.name[0] : '?',
                            style: const TextStyle(
                              color: AppTheme.accentBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(member.name),
                        subtitle: Text(member.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editMember(member),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Colors.red.shade400),
                              onPressed: () => _deleteMember(member),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importMembers,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('匯入'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _addMember,
                  icon: const Icon(Icons.add),
                  label: const Text('新增成員'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesTab() {
    return Column(
      children: [
        Expanded(
          child: _templates.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('尚未新增任何樣板', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.accentGreen.withOpacity(0.1),
                          child: const Icon(
                            Icons.bookmark,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                        title: Text(template.name),
                        subtitle: Text(
                          '${template.issueKey.isNotEmpty ? template.issueKey : "無預設單號"} · ${template.minutes} 分鐘',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editTemplate(template),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Colors.red.shade400),
                              onPressed: () => _deleteTemplate(template),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addTemplate,
              icon: const Icon(Icons.add),
              label: const Text('新增樣板'),
            ),
          ),
        ),
      ],
    );
  }
}
