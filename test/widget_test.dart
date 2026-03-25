// Basic widget test for VIP F2E Tool

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vip_f2e_tool/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build app and trigger a frame
    await tester.pumpWidget(const ProviderScope(child: VipF2eToolApp()));

    // Wait for dependency check screen
    await tester.pump();

    // Verify app title is shown
    expect(find.text('VIP F2E Tool'), findsOneWidget);
  });
}
