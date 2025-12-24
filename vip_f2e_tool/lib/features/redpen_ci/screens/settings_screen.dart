import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/repo_config.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;

  const SettingsScreen({super.key, required this.storageService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _mailController = TextEditingController();
  final _filterController = TextEditingController();
  final _repoInputController = TextEditingController();
  int _commitCount = 5;
  List<RepoConfig> _repos = [];
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.storageService.targetUrl;
    _tokenController.text = widget.storageService.token;
    _mailController.text = widget.storageService.mail;
    _filterController.text = widget.storageService.sastFilter;
    _commitCount = widget.storageService.commitCount;
    _repos = List.from(widget.storageService.repos);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    _mailController.dispose();
    _filterController.dispose();
    _repoInputController.dispose();
    super.dispose();
  }

  void _addRepo() {
    final input = _repoInputController.text.trim();
    if (input.isEmpty) return;

    try {
      final repo = RepoConfig.fromString(input);
      if (!_repos.contains(repo)) {
        setState(() {
          _repos.add(repo);
        });
        _repoInputController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('此 Repo 已存在')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('格式錯誤，請使用 owner/repo/branch 格式')),
      );
    }
  }

  void _removeRepo(RepoConfig repo) {
    setState(() {
      _repos.remove(repo);
    });
  }

  void _save() {
    widget.storageService.targetUrl = _urlController.text.trim();
    widget.storageService.token = _tokenController.text.trim();
    widget.storageService.mail = _mailController.text.trim();
    widget.storageService.sastFilter = _filterController.text.trim();
    widget.storageService.commitCount = _commitCount;
    widget.storageService.repos = _repos;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('設定已儲存')),
    );
    Navigator.pop(context);
  }

  void _resetDefaults() {
    setState(() {
      _urlController.text = StorageService.defaultTargetUrl;
      _filterController.text = StorageService.defaultSastFilter;
      _commitCount = StorageService.defaultCommitCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        actions: [
          TextButton(
            onPressed: _resetDefaults,
            child: const Text('重設預設值'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // === Repos Section ===
                _buildSectionHeader('Repositories', Icons.folder_copy),
                const SizedBox(height: 8),
                
                // Add repo input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _repoInputController,
                        decoration: InputDecoration(
                          hintText: 'owner/repo/branch (例: myorg/my-repo/main)',
                          prefixIcon: const Icon(Icons.add),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (_) => _addRepo(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addRepo,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Repo list
                if (_repos.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '尚未新增任何 Repo\n請使用上方輸入框新增',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _repos.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                      itemBuilder: (context, index) {
                        final repo = _repos[index];
                        return ListTile(
                          leading: const Icon(Icons.folder, color: Colors.blueAccent),
                          title: Text(repo.displayName),
                          subtitle: Text(
                            repo.branch,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeRepo(repo),
                          ),
                        );
                      },
                    ),
                  ),
                
                const SizedBox(height: 24),

                // === Scan Settings ===
                _buildSectionHeader('掃描設定', Icons.settings),
                const SizedBox(height: 12),

                // Commit count
                Row(
                  children: [
                    const Text('顯示 Commit 數量：'),
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: _commitCount,
                      items: [3, 5, 10, 15, 20]
                          .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _commitCount = value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Target URL
                _buildLabel('目標網址'),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: StorageService.defaultTargetUrl,
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Token
                _buildLabel('API Token'),
                TextField(
                  controller: _tokenController,
                  obscureText: _obscureToken,
                  decoration: InputDecoration(
                    hintText: '輸入您的 API Token',
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureToken ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureToken = !_obscureToken;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Mail
                _buildLabel('Email'),
                TextField(
                  controller: _mailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // SAST Filter
                _buildLabel('SAST Filter'),
                TextField(
                  controller: _filterController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: StorageService.defaultSastFilter,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Icon(Icons.filter_list),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('儲存設定'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}
