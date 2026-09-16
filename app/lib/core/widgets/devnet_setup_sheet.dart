import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Bottom sheet modal explaining how to configure Phantom and Solflare for Solana Devnet.
class DevnetSetupSheet extends StatelessWidget {
  const DevnetSetupSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.hub_rounded, size: 18, color: AppColors.warning),
                  ),
                  const SizedBox(width: 10),
                  Text('Devnet Wallet Setup', style: AppTypography.headlineSm),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'ClockIn runs on Solana Devnet to guarantee risk-free evaluation with zero real funds. Your wallet must be set to Devnet, otherwise signatures and transactions will be rejected.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 18),

              // Phantom Card
              _buildWalletGuide(
                name: 'Phantom',
                color: const Color(0xFFAB9FF2),
                icon: Icons.account_balance_wallet_rounded,
                steps: const [
                  'Open Phantom and tap the Settings gear icon (bottom-right).',
                  'Scroll down and select "Developer Settings".',
                  'Toggle "Testnet Mode" to ON.',
                  'Under "Change Network", select "Solana Devnet".',
                ],
              ),
              const SizedBox(height: 12),

              // Solflare Card
              _buildWalletGuide(
                name: 'Solflare',
                color: const Color(0xFFFF7A00),
                icon: Icons.local_fire_department_rounded,
                steps: const [
                  'Open Solflare and tap the Settings gear icon.',
                  'Tap "General" → "Change Network".',
                  'Select "Devnet".',
                ],
              ),
              const SizedBox(height: 16),

              // Faucet Tip Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.water_drop_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Free Devnet SOL?',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fund your Devnet address for free using faucet.solana.com or run `solana airdrop 2 <address> --url devnet` from the CLI.',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Understood'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletGuide({
    required String name,
    required Color color,
    required IconData icon,
    required List<String> steps,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Text(name, style: AppTypography.titleMd),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final stepText = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$idx',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stepText,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurface,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Helper function to open the Devnet setup sheet.
void showDevnetSetupSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const DevnetSetupSheet(),
  );
}
