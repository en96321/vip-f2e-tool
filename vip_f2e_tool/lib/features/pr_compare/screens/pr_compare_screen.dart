import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../models/pr_info.dart';
import '../models/comparison_result.dart';
import '../services/comparison_service.dart';
import '../services/github_service.dart';

class PrCompareScreen extends StatefulWidget {
  const PrCompareScreen({super.key});

  @override
  State<PrCompareScreen> createState() => _PrCompareScreenState();
}

class _PrCompareScreenState extends State<PrCompareScreen> {
  final _stagingController = TextEditingController();
  final _prodController = TextEditingController();
  final _comparisonService = ComparisonService();
  final _githubService = GithubService();

  bool _isLoading = false;
  String _status = '';
  ComparisonResult? _result;
  bool _ghInstalled = true;

  @override
  void initState() {
    super.initState();
    _checkGh();
  }

  Future<void> _checkGh() async {
    final installed = await _githubService.isGhInstalled();
    setState(() {
      _ghInstalled = installed;
    });
  }

  @override
  void dispose() {
    _stagingController.dispose();
    _prodController.dispose();
    super.dispose();
  }

  Future<void> _compare() async {
    // Parse staging PRs
    final stagingUrls = _stagingController.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final stagingPrs = <PrInfo>[];
    for (final url in stagingUrls) {
      final pr = PrInfo.fromUrl(url);
      if (pr == null) {
        setState(() {
          _status = '無法解析 URL: $url';
        });
        return;
      }
      stagingPrs.add(pr);
    }

    // Parse prod PR
    final prodPr = PrInfo.fromUrl(_prodController.text.trim());
    if (prodPr == null) {
      setState(() {
        _status = '無法解析 Prod PR URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '開始比對...';
      _result = null;
    });

    try {
      final result = await _comparisonService.compare(
        stagingPrs: stagingPrs,
        prodPr: prodPr,
        onProgress: (msg) {
          setState(() {
            _status = msg;
          });
        },
      );

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '錯誤: $e';
        _isLoading = false;
      });
    }
  }

  void _copyMarkdown() {
    if (_result != null) {
      Clipboard.setData(ClipboardData(text: _result!.toMarkdown()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Markdown 已複製到剪貼簿'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PR Commit 比對工具'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Input
            Expanded(
              flex: 1,
              child: _buildInputPanel(),
            ),
            const SizedBox(width: 16),
            // Right side - Result
            Expanded(
              flex: 1,
              child: _buildResultPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_ghInstalled)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '未偵測到 gh CLI。請先安裝: brew install gh',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            const Text(
              'Staging PRs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '每行一個 PR URL',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _stagingController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'https://github.com/owner/repo/pull/123',
                ),
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Prod PR',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _prodController,
              decoration: const InputDecoration(
                hintText: 'https://github.com/owner/repo/pull/456',
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading || !_ghInstalled ? null : _compare,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.compare_arrows),
                label: Text(_isLoading ? '比對中...' : '開始比對'),
              ),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                _status,
                style: TextStyle(
                  color: _status.startsWith('錯誤') ? Colors.red : AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '比對結果 (Markdown)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_result != null)
                  ElevatedButton.icon(
                    onPressed: _copyMarkdown,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('複製'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_result != null) ...[
              // Summary badges
              Row(
                children: [
                  _buildBadge(
                    _result!.isMatch ? '✅ 一致' : '❌ 不一致',
                    _result!.isMatch ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    'Staging: ${_result!.stagingCommits.length}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    'Prod: ${_result!.prodCherryPickSources.length}',
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100]!,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _result != null
                    ? SingleChildScrollView(
                        child: SelectableText(
                          _result!.toMarkdown(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          '尚無比對結果\n請輸入 PR URLs 後點擊「開始比對」',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
