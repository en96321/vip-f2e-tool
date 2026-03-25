import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../services/report_merge_service.dart';

class RedpenReportScreen extends StatefulWidget {
  const RedpenReportScreen({super.key});

  @override
  State<RedpenReportScreen> createState() => _RedpenReportScreenState();
}

class _RedpenReportScreenState extends State<RedpenReportScreen> {
  final _mergeService = ReportMergeService();

  String? _oldReportPath;
  String? _newCsvPath;
  bool _isProcessing = false;
  MergeResult? _mergeResult;
  String? _exportedPath;
  String? _errorMessage;

  Future<void> _pickOldReport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: '選擇舊的報告 Excel 檔案',
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        if (!path.endsWith('.xlsx') && !path.endsWith('.xls')) {
          setState(() {
            _errorMessage = '請選擇 .xlsx 或 .xls 檔案';
          });
          return;
        }
        setState(() {
          _oldReportPath = path;
          _mergeResult = null;
          _exportedPath = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '選擇檔案失敗: $e';
      });
    }
  }

  Future<void> _pickNewCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: '選擇新的掃描 CSV 檔案',
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        if (!path.endsWith('.csv')) {
          setState(() {
            _errorMessage = '請選擇 .csv 檔案';
          });
          return;
        }
        setState(() {
          _newCsvPath = path;
          _mergeResult = null;
          _exportedPath = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '選擇檔案失敗: $e';
      });
    }
  }

  Future<void> _processAndMerge() async {
    if (_oldReportPath == null || _newCsvPath == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _mergeResult = null;
      _exportedPath = null;
    });

    try {
      // Parse old report
      final oldFindings = _mergeService.parseExcel(_oldReportPath!);

      // Parse new CSV
      final newFindings = _mergeService.parseCsv(_newCsvPath!);

      // Merge
      final result = _mergeService.merge(
        oldFindings: oldFindings,
        newFindings: newFindings,
      );

      setState(() {
        _mergeResult = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '處理失敗: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _exportReport() async {
    if (_mergeResult == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Let user pick save location
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '儲存合併報告',
        fileName: 'redpen_merged_report.xlsx',
      );

      if (outputPath == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Ensure .xlsx extension
      final finalPath =
          outputPath.endsWith('.xlsx') ? outputPath : '$outputPath.xlsx';

      final path = await _mergeService.exportExcel(
        findings: _mergeResult!.findings,
        outputPath: finalPath,
      );

      setState(() {
        _exportedPath = path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('報告已匯出至: $path')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '匯出失敗: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RedPen 報告合併'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              // Step 1: Select old report
              _buildStepCard(
                step: 1,
                title: '選擇舊的報告',
                subtitle: '含有人工 Comment 的歷史掃描報告 (.xlsx)',
                filePath: _oldReportPath,
                onPick: _pickOldReport,
                icon: Icons.history,
              ),
              const SizedBox(height: 16),

              // Step 2: Select new CSV
              _buildStepCard(
                step: 2,
                title: '選擇新的掃描結果',
                subtitle: 'RedPen/Checkmarx 匯出的 CSV 檔案 (.csv)',
                filePath: _newCsvPath,
                onPick: _pickNewCsv,
                icon: Icons.file_present,
              ),
              const SizedBox(height: 24),

              // Merge button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_oldReportPath != null &&
                          _newCsvPath != null &&
                          !_isProcessing)
                      ? _processAndMerge
                      : null,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.merge_type),
                  label: Text(_isProcessing ? '處理中...' : '開始合併'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: AppTheme.accentRed.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.accentRed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.accentRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Merge result
              if (_mergeResult != null) ...[
                const SizedBox(height: 24),
                _buildResultCard(),
                const SizedBox(height: 16),

                // Preview table
                _buildPreviewTable(),
                const SizedBox(height: 24),

                // Export button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: !_isProcessing ? _exportReport : null,
                    icon: const Icon(Icons.download),
                    label: const Text('匯出 Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              // Export path
              if (_exportedPath != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: AppTheme.accentGreen.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppTheme.accentGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '匯出成功！',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _exportedPath!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.folder_open),
                          tooltip: '在 Finder 中顯示',
                          onPressed: () {
                            Process.run('open', [
                              '-R',
                              _exportedPath!,
                            ]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String subtitle,
    required String? filePath,
    required VoidCallback onPick,
    required IconData icon,
  }) {
    final hasFile = filePath != null;
    final fileName = hasFile ? filePath.split('/').last : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Step number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasFile
                    ? AppTheme.accentGreen.withOpacity(0.1)
                    : AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: hasFile
                    ? const Icon(Icons.check,
                        color: AppTheme.accentGreen, size: 20)
                    : Text(
                        '$step',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentBlue,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName ?? subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasFile
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Pick button
            OutlinedButton.icon(
              onPressed: onPick,
              icon: Icon(icon, size: 18),
              label: Text(hasFile ? '重選' : '選擇檔案'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _mergeResult!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '合併結果',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(
                  label: '總筆數',
                  value: '${result.totalCount}',
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  label: '已複製 Comment',
                  value: '${result.copiedCommentCount}',
                  color: AppTheme.accentGreen,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  label: '需人工查看',
                  value: '${result.newIssueCount}',
                  color: AppTheme.accentOrange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTable() {
    final findings = _mergeResult!.findings;
    final previewCount = findings.length > 50 ? 50 : findings.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '預覽',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(顯示前 $previewCount 筆，共 ${findings.length} 筆)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowColor: WidgetStateProperty.all(
                  AppTheme.accentBlue.withOpacity(0.05),
                ),
                columns: const [
                  DataColumn(label: Text('Query')),
                  DataColumn(label: Text('SrcFileName')),
                  DataColumn(label: Text('Line')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Severity')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Comment')),
                ],
                rows: findings.take(previewCount).map((f) {
                  final isNew = f.comment == '(需人工查看)';
                  return DataRow(
                    color: isNew
                        ? WidgetStateProperty.all(
                            AppTheme.accentOrange.withOpacity(0.05))
                        : null,
                    cells: [
                      DataCell(SizedBox(
                        width: 180,
                        child: Text(f.query,
                            overflow: TextOverflow.ellipsis),
                      )),
                      DataCell(SizedBox(
                        width: 250,
                        child: Text(f.srcFileName,
                            overflow: TextOverflow.ellipsis),
                      )),
                      DataCell(Text(f.line)),
                      DataCell(SizedBox(
                        width: 150,
                        child:
                            Text(f.name, overflow: TextOverflow.ellipsis),
                      )),
                      DataCell(_buildSeverityBadge(f.resultSeverity)),
                      DataCell(_buildStatusBadge(f.resultStatus)),
                      DataCell(SizedBox(
                        width: 200,
                        child: Text(
                          f.comment,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isNew
                                ? AppTheme.accentRed
                                : AppTheme.textPrimary,
                            fontWeight:
                                isNew ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    switch (severity.toUpperCase()) {
      case 'HIGH':
        color = AppTheme.accentRed;
        break;
      case 'MEDIUM':
        color = AppTheme.accentOrange;
        break;
      case 'LOW':
        color = AppTheme.accentGreen;
        break;
      default:
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        severity,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isNew = status.toUpperCase() == 'NEW';
    final color = isNew ? AppTheme.accentOrange : AppTheme.accentBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
