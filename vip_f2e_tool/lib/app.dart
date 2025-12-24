import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/startup/screens/dependency_check_screen.dart';

/// Main application widget
class VipF2eToolApp extends StatelessWidget {
  const VipF2eToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIP F2E Tool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const DependencyCheckScreen(),
    );
  }
}
