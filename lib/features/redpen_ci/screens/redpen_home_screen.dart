import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/history_service.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'scan_screen.dart';

/// RedPen CI Home Screen - initializes its own services
class RedpenHomeScreen extends StatefulWidget {
  const RedpenHomeScreen({super.key});

  @override
  State<RedpenHomeScreen> createState() => _RedpenHomeScreenState();
}

class _RedpenHomeScreenState extends State<RedpenHomeScreen> {
  late StorageService _storageService;
  late HistoryService _historyService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    _storageService = StorageService();
    _historyService = HistoryService();
    await _storageService.init();
    await _historyService.init();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('RedPen CI')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final repoCount = _storageService.repos.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RedPen CI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '執行紀錄',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(
                    historyService: _historyService,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    storageService: _storageService,
                  ),
                ),
              );
              setState(() {}); // Refresh after settings change
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo / Title
              const Icon(
                Icons.security,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'RedPen CI Scanner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '靜態程式碼分析工具',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Stats Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStat(
                            icon: Icons.folder,
                            value: '$repoCount',
                            label: 'Repositories',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Main Action Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: repoCount > 0
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScanScreen(
                                storageService: _storageService,
                                historyService: _historyService,
                              ),
                            ),
                          )
                      : null,
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text(
                    '開始掃描',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (repoCount == 0) ...[
                const SizedBox(height: 16),
                Text(
                  '請先在設定中新增 Repository',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          storageService: _storageService,
                        ),
                      ),
                    );
                    setState(() {});
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('前往設定'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blueAccent),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
