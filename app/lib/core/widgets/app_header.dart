import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Sticky top header matching the Stitch design's chrome, used across
/// tabs: wordmark + tagline, a "DEVNET" chip, and — when a wallet is
/// connected — a tappable short-address pill plus an avatar action.
/// Screens reachable without a connected wallet (Look Up, Settings) pass
/// `address: null` and get just the wordmark + DEVNET chip.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.address,
    this.onCopyAddress,
    this.onAvatarTap,
  });

  final String? address;
  final VoidCallback? onCopyAddress;
  final VoidCallback? onAvatarTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ClockIn',
                style: AppTypography.headlineSm.copyWith(color: AppColors.primary, height: 1),
              ),
              Text(
                'SOLANA PASS',
                style: AppTypography.labelSm.copyWith(color: AppColors.outline, letterSpacing: 1),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'DEVNET',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        if (address != null) ...[
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onCopyAddress,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 14, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Text(_shorten(address!), style: AppTypography.labelSm.copyWith(color: AppColors.onSurface)),
                  const SizedBox(width: 4),
                  const Icon(Icons.copy_rounded, size: 14, color: AppColors.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            tooltip: 'Wallet options',
            onPressed: onAvatarTap,
          ),
        ] else
          const SizedBox(width: 4),
      ],
    );
  }

  static String _shorten(String address) =>
      '${address.substring(0, 4)}…${address.substring(address.length - 4)}';
}
