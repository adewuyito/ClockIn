import 'package:clockin/core/providers/app_providers.dart';
import 'package:clockin/core/solana/wallet_adapter.dart';
import 'package:clockin/core/theme/app_colors.dart';
import 'package:clockin/core/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TestWalletNotifier extends WalletNotifier {
  bool disconnectCalled = false;

  TestWalletNotifier({
    String initialAddress = '8xrt2BeSqZfW7GqFv3qNf4K8jY1u9m6oP4s7T2wX1abc',
  }) : super(WalletAdapter()) {
    state = WalletState(
      status: WalletStatus.connected,
      address: initialAddress,
    );
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
    state = const WalletState(status: WalletStatus.disconnected);
  }
}

void main() {
  testWidgets(
      'Tapping profile avatar in AppHeader opens WalletAccountSheet without disconnecting',
      (WidgetTester tester) async {
    final notifier = TestWalletNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletStateProvider.overrideWith((ref) => notifier),
          walletBalanceProvider.overrideWith((ref) => Future.value(1500000000)), // 1.5 SOL
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Consumer(
                builder: (context, ref, child) {
                  final wallet = ref.watch(walletStateProvider);
                  return AppHeader(
                    address: wallet.isConnected ? wallet.address : null,
                  );
                },
              ),
            ),
            body: const Center(child: Text('Screen Body')),
          ),
        ),
      ),
    );

    // Initial state: connected, shows avatar button
    expect(notifier.state.isConnected, isTrue);
    expect(notifier.disconnectCalled, isFalse);
    expect(find.byTooltip('Wallet options'), findsOneWidget);

    // Tap the avatar button
    await tester.tap(find.byTooltip('Wallet options'));
    await tester.pumpAndSettle();

    // CRITICAL: Tapping avatar MUST NOT disconnect wallet!
    expect(notifier.disconnectCalled, isFalse);
    expect(notifier.state.isConnected, isTrue);

    // WalletAccountSheet must be open
    expect(find.text('Connected Wallet'), findsOneWidget);
    expect(find.text('Disconnect Wallet'), findsOneWidget);

    // Tap "Disconnect Wallet"
    await tester.tap(find.text('Disconnect Wallet'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Disconnect Wallet?'), findsOneWidget);
    expect(
      find.text('Are you sure you want to disconnect? You will need to re-authorize with Phantom or Solflare to interact with on-chain contracts.'),
      findsOneWidget,
    );
    expect(notifier.disconnectCalled, isFalse);

    // Tap Cancel in dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Still connected!
    expect(notifier.disconnectCalled, isFalse);
    expect(notifier.state.isConnected, isTrue);

    // Open confirmation dialog again and confirm
    await tester.tap(find.text('Disconnect Wallet'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Disconnect'));
    await tester.pumpAndSettle();

    // Now disconnect was intentionally called!
    expect(notifier.disconnectCalled, isTrue);
    expect(notifier.state.isConnected, isFalse);
  });
}
