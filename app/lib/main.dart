import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/my_profile_screen.dart';
import 'features/reviews/submit_review_screen.dart';
import 'features/search/lookup_worker_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/wallet_connect/connect_wallet_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  int _currentIndex = 0;
  String? _prefilledWorkerForReview;

  void _onSelectWorkerForReview(String workerAddress) {
    setState(() {
      _prefilledWorkerForReview = workerAddress;
      _currentIndex = 2; // Switch to Submit Review tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStateProvider);

    final screens = [
      // Tab 0: Profile / Connect
      wallet.isConnected
          ? const MyProfileScreen()
          : const ConnectWalletScreen(),

      // Tab 1: Look Up Worker
      LookupWorkerScreen(
        onSelectWorkerForReview: _onSelectWorkerForReview,
      ),

      // Tab 2: Submit Review
      SubmitReviewScreen(
        initialWorkerAddress: _prefilledWorkerForReview,
      ),

      // Tab 3: Settings & Devnet Info
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
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
            label: wallet.isConnected ? 'My Profile' : 'Connect',
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
