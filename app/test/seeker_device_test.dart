import 'package:clockin/core/models/review.dart';
import 'package:clockin/core/models/seeker_attestation.dart';
import 'package:clockin/core/models/worker_profile.dart';
import 'package:clockin/core/providers/app_providers.dart';
import 'package:clockin/core/services/device_service.dart';
import 'package:clockin/core/solana/wallet_adapter.dart';
import 'package:clockin/core/widgets/seeker_logo.dart';
import 'package:clockin/features/profile/my_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSeekerDeviceService extends DeviceService {
  final bool isSeeker;
  final DeviceInfo mockInfo;

  MockSeekerDeviceService({
    this.isSeeker = false,
    this.mockInfo = const DeviceInfo(),
  });

  @override
  Future<bool> isSeekerDevice() async => isSeeker;

  @override
  Future<DeviceInfo> getDeviceInfo() async => mockInfo;
}

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

  group('SeekerLogo Widget Tests', () {
    testWidgets('renders SeekerLogo inactive and active without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SeekerLogo(size: 20, isActive: false),
                SeekerLogo(size: 20, isActive: true, withGlow: true),
                SeekerHardwareChip(isSeeker: false),
                SeekerHardwareChip(isSeeker: true),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SeekerLogo), findsNWidgets(4));
      expect(find.text('MOBILE'), findsOneWidget);
      expect(find.text('SEEKER'), findsOneWidget);
    });
  });

  group('DeviceService & SeekerDeviceNotifier Tests', () {
    test('SeekerDeviceNotifier updates hardware state and simulation toggle', () async {
      final mockService = MockSeekerDeviceService(
        isSeeker: true,
        mockInfo: const DeviceInfo(
          model: 'Seeker',
          brand: 'Solana Mobile',
          manufacturer: 'Solana',
          hasSeedVault: true,
          isSeeker: true,
        ),
      );

      final notifier = SeekerDeviceNotifier(mockService);
      await notifier.checkDevice();

      expect(notifier.state.isPhysicalSeeker, isTrue);
      expect(notifier.state.isSeeker, isTrue);
      expect(notifier.state.deviceInfo.model, equals('Seeker'));
      expect(notifier.state.deviceInfo.hasSeedVault, isTrue);

      // Test simulation toggle on non-seeker
      final mockNonSeeker = MockSeekerDeviceService(
        isSeeker: false,
        mockInfo: const DeviceInfo(model: 'SM-G973F', brand: 'Samsung'),
      );
      final notifier2 = SeekerDeviceNotifier(mockNonSeeker);
      await notifier2.checkDevice();
      expect(notifier2.state.isPhysicalSeeker, isFalse);
      expect(notifier2.state.isSeeker, isFalse);

      notifier2.toggleSimulation(true);
      expect(notifier2.state.isSimulated, isTrue);
      expect(notifier2.state.isSeeker, isTrue);
    });
  });

  group('Seeker Attestation Banner Tests', () {
    testWidgets('Profile banner displays SeekerLogo, shows SEEKER HARDWARE badge when active, and has NO cooldown text',
        (tester) async {
      final mockService = MockSeekerDeviceService(
        isSeeker: true,
        mockInfo: const DeviceInfo(isSeeker: true, model: 'Seeker'),
      );

      const testAddress = 'ClockInTestWorker1111111111111111111111111';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockService),
            walletStateProvider.overrideWith((ref) => TestWalletNotifier(testAddress)),
            walletBalanceProvider.overrideWith((ref) => Future.value(1000000000)),
            walletSkrBalanceProvider.overrideWith((ref) => Future.value(500.0)),
            myProfileProvider.overrideWith(
              (ref) => Stream.value(
                WorkerProfile(
                  address: testAddress,
                  totalJobs: 5,
                  ratingSum: BigInt.from(24),
                  createdAt: DateTime.now(),
                ),
              ),
            ),
            workerReviewsProvider(testAddress).overrideWith(
              (ref) => Stream.value(<Review>[]),
            ),
            seekerAttestationProvider(testAddress).overrideWith(
              (ref) => Stream.value(
                SeekerAttestation(
                  address: testAddress,
                  isAttested: true,
                  stakedAmount: 250.0,
                  guardianName: 'Solana Mobile',
                  cooldownActive: false,
                  syncedAt: DateTime.now(),
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: MyProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Seeker logo is rendered
      expect(find.byType(SeekerLogo), findsWidgets);

      // Verify Seeker Attested title is rendered
      expect(find.text('SEEKER ATTESTED'), findsOneWidget);

      // Verify SEEKER HARDWARE chip is illuminated
      expect(find.text('SEEKER HARDWARE'), findsOneWidget);

      // CRITICAL REQUIREMENT: Verify 48h Cooldown is completely REMOVED
      expect(find.textContaining('Cooldown'), findsNothing);
      expect(find.textContaining('48h'), findsNothing);
    });

    testWidgets('Profile banner renders cleanly on narrow screen (320dp) with NO flex overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockService = MockSeekerDeviceService(
        isSeeker: true,
        mockInfo: const DeviceInfo(isSeeker: true, model: 'Seeker'),
      );

      const testAddress = 'ClockInTestWorker1111111111111111111111111';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceServiceProvider.overrideWithValue(mockService),
            walletStateProvider.overrideWith((ref) => TestWalletNotifier(testAddress)),
            walletBalanceProvider.overrideWith((ref) => Future.value(1000000000)),
            walletSkrBalanceProvider.overrideWith((ref) => Future.value(500.0)),
            myProfileProvider.overrideWith(
              (ref) => Stream.value(
                WorkerProfile(
                  address: testAddress,
                  totalJobs: 5,
                  ratingSum: BigInt.from(24),
                  createdAt: DateTime.now(),
                ),
              ),
            ),
            workerReviewsProvider(testAddress).overrideWith(
              (ref) => Stream.value(<Review>[]),
            ),
            seekerAttestationProvider(testAddress).overrideWith(
              (ref) => Stream.value(
                SeekerAttestation(
                  address: testAddress,
                  isAttested: true,
                  stakedAmount: 250.0,
                  guardianName: 'Solana Mobile Guardian Juror',
                  cooldownActive: false,
                  syncedAt: DateTime.now(),
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: MyProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure no exceptions (e.g. RenderFlex overflow) occurred during layout
      expect(tester.takeException(), isNull);
      expect(find.text('SEEKER ATTESTED'), findsOneWidget);
      expect(find.text('SEEKER HARDWARE'), findsOneWidget);
    });
  });
}
