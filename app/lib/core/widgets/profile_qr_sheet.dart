import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_colors.dart';

/// Modal bottom sheet and inline card for rendering a scannable Solana QR code
/// directly within ClockIn, eliminating the need to open Solflare or Phantom
/// to display wallet identity or profile public keys.
class ProfileQrSheet extends StatefulWidget {
  final String address;
  final String? label;
  final bool isRegistered;

  const ProfileQrSheet({
    super.key,
    required this.address,
    this.label,
    this.isRegistered = true,
  });

  /// Opens the QR code modal sheet.
  static Future<void> show(
    BuildContext context, {
    required String address,
    String? label,
    bool isRegistered = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileQrSheet(
        address: address,
        label: label,
        isRegistered: isRegistered,
      ),
    );
  }

  @override
  State<ProfileQrSheet> createState() => _ProfileQrSheetState();
}

class _ProfileQrSheetState extends State<ProfileQrSheet> {
  bool _useSolanaPayUri = true;

  String get _qrPayload =>
      _useSolanaPayUri ? 'solana:${widget.address}' : widget.address;

  void _copy(String text, String message) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label ?? 'Profile QR Code',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: widget.isRegistered
                                      ? AppColors.success
                                      : AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.isRegistered
                                    ? 'On-Chain • Solana Devnet'
                                    : 'Connected Wallet • Devnet',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // QR Code Box
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrPayload,
                  version: QrVersions.auto,
                  size: 210,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Format selector tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _formatTab(
                      label: 'Solana Pay URI',
                      isSelected: _useSolanaPayUri,
                      onTap: () => setState(() => _useSolanaPayUri = true),
                    ),
                    _formatTab(
                      label: 'Raw Address',
                      isSelected: !_useSolanaPayUri,
                      onTap: () => setState(() => _useSolanaPayUri = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Address container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: AppColors.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.address,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _copy(
                        widget.address,
                        'Solana address copied to clipboard',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Copy',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Scan compatibility note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_outlined, size: 14, color: AppColors.outline),
                  const SizedBox(width: 6),
                  Text(
                    'Compatible with ClockIn, Phantom, & Solflare',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Primary Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      onPressed: () => _copy(
                        'solana:${widget.address}',
                        'Solana Pay URI copied',
                      ),
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Copy Solana URI'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _copy(
                        widget.address,
                        'Address copied! Share with client',
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy Address'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// An inline, interactive card displaying the worker's or user's QR code.
/// Can be embedded directly onto [MyProfileScreen] or [WorkerProfileScreen].
class ProfileQrCard extends StatelessWidget {
  final String address;
  final bool isRegistered;
  final String? title;
  final String? subtitle;
  final bool isCompact;

  const ProfileQrCard({
    super.key,
    required this.address,
    this.isRegistered = true,
    this.title,
    this.subtitle,
    this.isCompact = false,
  });

  static String _shorten(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 4)}…${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final qrData = 'solana:$address';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title ?? 'Profile QR Code',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => ProfileQrSheet.show(
                  context,
                  address: address,
                  label: title,
                  isRegistered: isRegistered,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fullscreen_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Enlarge',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            subtitle ??
                'Scan directly with ClockIn, Phantom, or Solflare to view record or hire.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // High-contrast QR preview box
          GestureDetector(
            onTap: () => ProfileQrSheet.show(
              context,
              address: address,
              label: title,
              isRegistered: isRegistered,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: isCompact ? 140 : 170,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Address pill with copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _shorten(address),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
