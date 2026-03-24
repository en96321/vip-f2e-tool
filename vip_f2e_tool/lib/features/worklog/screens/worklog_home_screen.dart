import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/team_member.dart';
import '../models/worklog_entry.dart';
import '../models/worklog_result.dart';
import '../models/worklog_template.dart';
import '../services/jira_service.dart';
import '../services/worklog_storage_service.dart';
import 'worklog_settings_screen.dart';

/// 統一會議工時記錄主畫面
class WorklogHomeScreen extends StatefulWidget {
  const WorklogHomeScreen({super.key});

  @override
  State<WorklogHomeScreen> createState() => _WorklogHomeScreenState();
}

class _WorklogHomeScreenState extends State<WorklogHomeScreen> {
  final _storageService = WorklogStorageService();
  final _jiraService = JiraService();
  
  bool _isLoading = true;
  bool _isExecuting = false;
  
  // 資料
  List<TeamMember> _members = [];
  List<WorklogTemplate> _templates = [];
  
  // 表單欄位
  WorklogTemplate? _selectedTemplate;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final _issueKeyController = TextEditingController();
  final _minutesController = TextEditingController(text: '60');
  final _commentController = TextEditingController();
  Set<String> _selectedMemberIds = {};
  
  // 執行結果
  List<WorklogResult>? _results;
  int _progress = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _issueKeyController.dispose();
    _minutesController.dispose();
    _commentController.dispose();
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

  void _applyTemplate(WorklogTemplate? template) {
    if (template == null) {
      setState(() => _selectedTemplate = null);
      return;
    }
    
    setState(() {
      _selectedTemplate = template;
      _issueKeyController.text = template.issueKey;
      _minutesController.text = template.minutes.toString();
      _commentController.text = template.comment;
      _selectedTime = template.defaultTime;
      _selectedMemberIds = Set.from(template.selectedMemberIds);
    });
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
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

  void _toggleSelectAll() {
    setState(() {
      if (_selectedMemberIds.length == _members.length) {
        _selectedMemberIds.clear();
      } else {
        _selectedMemberIds = Set.from(_members.map((m) => m.id));
      }
    });
  }

  Future<void> _execute() async {
    // 驗證輸入
    final issueKey = _issueKeyController.text.trim();
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final jiraDomain = _storageService.jiraDomain;

    if (jiraDomain.isEmpty) {
      _showError('請先至設定頁面設定 Jira Domain');
      return;
    }
    
    if (issueKey.isEmpty) {
      _showError('請輸入 Jira 單號');
      return;
    }
    
    if (minutes <= 0) {
      _showError('時數必須大於 0');
      return;
    }
    
    if (_selectedMemberIds.isEmpty) {
      _showError('請至少選擇一位成員');
      return;
    }

    // 取得選中的成員
    final selectedMembers = _members
        .where((m) => _selectedMemberIds.contains(m.id))
        .toList();

    // 組合日期和時間
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final entry = WorklogEntry(
      date: dateTime,
      issueKey: issueKey,
      minutes: minutes,
      comment: _commentController.text.trim(),
    );

    setState(() {
      _isExecuting = true;
      _results = null;
      _progress = 0;
      _total = selectedMembers.length;
    });

    final results = await _jiraService.addWorklogBatch(
      jiraDomain,
      selectedMembers,
      entry,
      onProgress: (current, total) {
        setState(() {
          _progress = current;
          _total = total;
        });
      },
    );

    setState(() {
      _isExecuting = false;
      _results = results;
    });

    _showResultDialog(results);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showResultDialog(List<WorklogResult> results) {
    final successCount = results.where((r) => r.success).length;
    final failCount = results.length - successCount;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              failCount == 0 ? Icons.check_circle : Icons.warning,
              color: failCount == 0 ? AppTheme.accentGreen : AppTheme.accentOrange,
            ),
            const SizedBox(width: 8),
            const Text('執行結果'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('成功：$successCount 人 / 失敗：$failCount 人'),
              const Divider(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        result.success ? Icons.check : Icons.close,
                        color: result.success
                            ? AppTheme.accentGreen
                            : AppTheme.accentRed,
                        size: 20,
                      ),
                      title: Text(result.member.name),
                      subtitle: result.success
                          ? null
                          : Text(
                              result.message,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorklogSettingsScreen()),
    );
    // 重新載入資料
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('統一會議工時'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? _buildEmptyState()
              : _buildForm(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '尚未新增任何成員',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '請先到設定頁面新增團隊成員',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
            label: const Text('前往設定'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 樣板選擇
            if (_templates.isNotEmpty) ...[
              _buildSectionTitle('樣板'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<WorklogTemplate?>(
                          value: _selectedTemplate,
                          decoration: const InputDecoration(
                            labelText: '選擇樣板',
                            border: InputBorder.none,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('（不使用樣板）'),
                            ),
                            ..._templates.map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.name),
                                )),
                          ],
                          onChanged: _applyTemplate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 基本資訊
            _buildSectionTitle('工時資訊'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 日期和時間
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: '日期',
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                                  ),
                                  const Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: '時間',
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
                    // Jira 單號
                    TextField(
                      controller: _issueKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Jira 單號',
                        hintText: '例如：CPM-27966',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 時數和備註
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _minutesController,
                            decoration: const InputDecoration(
                              labelText: '時數（分）',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              labelText: '備註',
                              hintText: '例如：統一會議',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 成員選擇
            _buildSectionTitle(
              '成員清單 (${_selectedMemberIds.length}/${_members.length})',
              trailing: TextButton(
                onPressed: _toggleSelectAll,
                child: Text(
                  _selectedMemberIds.length == _members.length ? '取消全選' : '全選',
                ),
              ),
            ),
            Card(
              child: Column(
                children: _members.map((member) {
                  final isSelected = _selectedMemberIds.contains(member.id);
                  return CheckboxListTile(
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
                    title: Text(member.name),
                    subtitle: Text(member.email, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // 執行按鈕
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isExecuting ? null : _execute,
                icon: _isExecuting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isExecuting ? '執行中 ($_progress/$_total)...' : '執行工時記錄',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
