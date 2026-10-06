import 'package:clockin/core/database/app_database.dart'
    hide WorkerProfile, Review, EscrowContract, SeekerAttestation;
import 'package:clockin/core/providers/app_providers.dart';
import 'package:clockin/core/solana/wallet_adapter.dart';
import 'package:clockin/features/contracts/create_contract_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TestWalletNotifier extends WalletNotifier {
  TestWalletNotifier(String address) : super(WalletAdapter()) {
    state = WalletState(
      status: WalletStatus.connected,
      address: address,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testAddress = 'EmployerTest11111111111111111111111111111111';

  group('CreateContractScreen Multi-Currency Widget Tests', () {
    testWidgets(
        'Renders 3-way currency selector [SOL | USDC | \$SKR] without overflow on 360dp screen',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletStateProvider.overrideWith((ref) => TestWalletNotifier(testAddress)),
            draftContractsProvider.overrideWith((ref) => Stream.value(<DraftContract>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CreateContractScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Zero exceptions / RenderFlex overflow
      expect(tester.takeException(), isNull);

      // Verify all 3 currencies are visible
      expect(find.text('SOL'), findsWidgets);
      expect(find.text('USDC'), findsWidgets);
      expect(find.text(r'$SKR'), findsWidgets);

      // Subtitles
      expect(find.text('Native'), findsOneWidget);
      expect(find.text('USD Coin'), findsOneWidget);
      expect(find.text('Seeker'), findsOneWidget);

      // Initial state is SOL
      expect(find.text('Escrow Amount (SOL)'), findsOneWidget);
    });

    testWidgets('Tapping USDC and \$SKR tabs updates currency state and amount presets',
        (tester) async {
      tester.view.physicalSize = const Size(412 * 2, 892 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletStateProvider.overrideWith((ref) => TestWalletNotifier(testAddress)),
            draftContractsProvider.overrideWith((ref) => Stream.value(<DraftContract>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CreateContractScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Find currency tab for USDC and tap it
      final usdcTab = find.text('USDC');
      expect(usdcTab, findsWidgets);
      await tester.tap(usdcTab.first);
      await tester.pumpAndSettle();

      final afterTapError = tester.takeException();
      if (afterTapError != null) {
        print('AFTER TAP ERROR: $afterTapError');
      }
      expect(afterTapError, isNull);
      expect(find.text('Escrow Amount (USDC)'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money_rounded), findsWidgets);

      // Find currency tab for $SKR and tap it
      final skrTab = find.text(r'$SKR');
      expect(skrTab, findsWidgets);
      await tester.tap(skrTab.first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(r'Escrow Amount ($SKR)'), findsOneWidget);
      expect(find.byIcon(Icons.shield_rounded), findsWidgets);

      // Switch back to SOL
      final solTab = find.text('SOL');
      expect(solTab, findsWidgets);
      await tester.tap(solTab.first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Escrow Amount (SOL)'), findsOneWidget);
    });
  });
}
