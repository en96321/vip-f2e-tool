import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/dependency.dart';
import '../../../core/services/dependency_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/home_screen.dart';

/// Screen shown at startup to check required dependencies
class DependencyCheckScreen extends StatefulWidget {
  /// If true, this is the initial startup check and will auto-navigate to home
  final bool isStartupCheck;
  
  const DependencyCheckScreen({super.key, this.isStartupCheck = true});

  @override
  State<DependencyCheckScreen> createState() => _DependencyCheckScreenState();
}

class _DependencyCheckScreenState extends State<DependencyCheckScreen> {
  final _dependencyService = DependencyService();
  List<DependencyCheckResult>? _results;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkDependencies();
  }

  Future<void> _checkDependencies() async {
    setState(() {
      _isChecking = true;
    });

    final results = await _dependencyService.checkAllDependencies();

    setState(() {
      _results = results;
      _isChecking = false;
    });

    // If all dependencies are installed and this is startup, navigate to home
    final allInstalled = results.every((r) => r.isInstalled || !r.dependency.isRequired);
    if (allInstalled && mounted && widget.isStartupCheck) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (widget.isStartupCheck) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isStartupCheck ? null : AppBar(
        title: const Text('依賴檢查'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                const Icon(
                  Icons.build_circle_outlined,
                  size: 80,
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(height: 24),
                const Text(
                  'VIP F2E Tool',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '系統依賴檢查',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                if (_isChecking)
                  const _LoadingIndicator()
                else if (_results != null)
                  _DependencyList(
                    results: _results!,
                    onRetry: _checkDependencies,
                    onSkip: _navigateToHome,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          '正在檢查系統依賴...',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _DependencyList extends StatelessWidget {
  final List<DependencyCheckResult> results;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  const _DependencyList({
    required this.results,
    required this.onRetry,
    required this.onSkip,
  });

  bool get allInstalled => results.every((r) => r.isInstalled || !r.dependency.isRequired);
  List<DependencyCheckResult> get missingRequired =>
      results.where((r) => !r.isInstalled && r.dependency.isRequired).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status message
        if (allInstalled)
          _StatusBanner(
            icon: Icons.check_circle,
            color: AppTheme.accentGreen,
            message: '所有依賴已安裝！',
          )
        else
          _StatusBanner(
            icon: Icons.warning_amber_rounded,
            color: AppTheme.accentOrange,
            message: '缺少 ${missingRequired.length} 個必要依賴',
          ),
        const SizedBox(height: 24),

        // Dependency cards
        ...results.map((result) => _DependencyCard(result: result)),
        const SizedBox(height: 32),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重新檢查'),
            ),
            if (allInstalled) ...[
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: onSkip,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('繼續'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _DependencyCard extends StatelessWidget {
  final DependencyCheckResult result;

  const _DependencyCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isInstalled = result.isInstalled;
    final dep = result.dependency;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isInstalled ? Icons.check_circle : Icons.cancel,
                  color: isInstalled ? AppTheme.accentGreen : AppTheme.accentRed,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dep.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (result.version != null)
                        Text(
                          result.version!,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (dep.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '必要',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            if (!isInstalled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                '安裝指令：',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              _CommandBox(command: dep.installInstructions),
              if (dep.postInstallInstructions != null) ...[
                const SizedBox(height: 12),
                Text(
                  '安裝後執行：',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                _CommandBox(command: dep.postInstallInstructions!),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CommandBox extends StatelessWidget {
  final String command;

  const _CommandBox({required this.command});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100]!,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              command,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: command));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已複製到剪貼簿'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: '複製',
          ),
        ],
      ),
    );
  }
}
