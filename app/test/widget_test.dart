import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clockin/core/database/app_database.dart';
import 'package:clockin/core/providers/app_providers.dart';
import 'package:clockin/main.dart';

void main() {
  testWidgets('ClockInApp initializes and renders shell smoke test', (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await testDb.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const ClockInApp(),
      ),
    );

    // Verify brand title and navigation destinations
    expect(find.text('ClockIn'), findsWidgets);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Look Up'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Cleanly unmount and drain Drift StreamQueryStore cancellation timer
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('App opens on disconnected state directly to the Connect tab (index 3)',
      (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await testDb.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const ClockInApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the NavigationBar has selectedIndex == 3 (Connect tab)
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 3);

    // Verify ConnectWalletScreen content is displayed
    expect(find.text('Zero key custody'), findsOneWidget);
    expect(find.text('Connect via Mobile Wallet'), findsOneWidget);

    // Cleanly unmount
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
