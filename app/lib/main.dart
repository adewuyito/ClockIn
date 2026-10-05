import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/contracts/contract_detail_screen.dart';
import 'features/contracts/contracts_list_screen.dart';
import 'features/profile/my_profile_screen.dart';
import 'features/reviews/submit_review_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/search/lookup_worker_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/wallet_connect/connect_wallet_screen.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint('[FCM Background] Message: ${message.messageId}, Data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] Initialization error: $e');
  }
  runApp(
    const ProviderScope(
      child: ClockInApp(),
    ),
  );
}

/// Root ClockIn Application.
class ClockInApp extends StatelessWidget {
  const ClockInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClockIn',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}

/// Navigation Shell for ClockIn mobile dApp.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 3; // Defaults to Connect tab (index 3) when disconnected
  String? _prefilledWorkerForReview;

  @override
  void initState() {
    super.initState();
    final wallet = ref.read(walletStateProvider);
    _currentIndex = wallet.isConnected ? 0 : 3;
    if (wallet.isConnected && wallet.address != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeNotifications(wallet.address!);
      });
    }

    ref.listenManual(walletStateProvider, (prev, next) {
      if (next.isConnected && next.address != null && prev?.address != next.address) {
        _initializeNotifications(next.address!);
      }
    });
  }

  Future<void> _initializeNotifications(String walletAddress) async {
    final syncService = ref.read(firebaseSyncServiceProvider);
    syncService.initializeFcm(
      walletAddress: walletAddress,
      onForegroundMessage: (msg) {
        final title = msg.notification?.title ?? 'Contract Alert';
        final body = msg.notification?.body ?? '';
        final contractId = msg.data['contractId'] as String?;
        _showNotificationBanner(title, body, contractId);
      },
    );
    _setupNotificationListener(walletAddress);

    // Refresh this device's published X25519 key if it already carries a wallet
    // attestation. Deliberately never prompts: requesting an MWA signature here
    // would chain a second wallet handoff onto the connect flow. The one-time
    // attestation is a user-driven action in Settings instead.
    await ref.read(encryptionKeyRegistryProvider).publishIfAttested(walletAddress);
  }

  void _setupNotificationListener(String walletAddress) {
    ref.read(firebaseSyncServiceProvider).listenToUserNotifications(
      walletAddress,
      (notification) {
        if (!mounted) return;
        final title = notification['title'] as String? ?? 'Contract Alert';
        final body = notification['body'] as String? ?? '';
        final contractId = notification['contractId'] as String?;
        _showNotificationBanner(title, body, contractId);
      },
    );
  }

  void _showNotificationBanner(String title, String body, String? contractId) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (body.isNotEmpty)
              Text(
                body,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: AppColors.primaryContainer,
        behavior: SnackBarBehavior.floating,
        action: contractId != null
            ? SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ContractDetailScreen(contractId: contractId),
                    ),
                  );
                },
              )
            : null,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _onSelectWorkerForReview(String workerAddress) {
    setState(() {
      _prefilledWorkerForReview = workerAddress;
      _currentIndex = 2; // Switch to Submit Review tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStateProvider);

    // If wallet transitions from connected to disconnected, route back to Connect tab
    ref.listen<WalletState>(walletStateProvider, (previous, next) {
      if (previous?.isConnected == true && !next.isConnected) {
        setState(() {
          _currentIndex = 3;
        });
      }
    });

    final screens = [
      // Tab 0: Contracts (P2P Escrow)
      const ContractsListScreen(),

      // Tab 1: Look Up Worker
      LookupWorkerScreen(
        onSelectWorkerForReview: _onSelectWorkerForReview,
      ),

      // Tab 2: Submit Review
      SubmitReviewScreen(
        initialWorkerAddress: _prefilledWorkerForReview,
      ),

      // Tab 3: Profile / Connect
      wallet.isConnected
          ? const MyProfileScreen()
          : const ConnectWalletScreen(),

      // Tab 4: Settings & Devnet Info
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor: AppColors.secondaryContainer.withValues(alpha: 0.5),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake_rounded, color: AppColors.primary),
            label: 'Contracts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search, color: AppColors.primary),
            label: 'Look Up',
          ),
          const NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review_rounded, color: AppColors.primary),
            label: 'Review',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
            label: wallet.isConnected ? 'Profile' : 'Connect',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
