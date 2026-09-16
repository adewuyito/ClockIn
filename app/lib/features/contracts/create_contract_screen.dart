import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solana/solana.dart';
import '../../core/providers/app_providers.dart';
import '../../core/solana/contract_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/qr_scanner_sheet.dart';
import 'contract_detail_screen.dart';

class CreateContractScreen extends ConsumerStatefulWidget {
  final String? initialWorkerAddress;

  const CreateContractScreen({
    super.key,
    this.initialWorkerAddress,
  });

  @override
  ConsumerState<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends ConsumerState<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _workerController;
  late final TextEditingController _contractIdController;
  late final TextEditingController _amountController;
  late final TextEditingController _termsController;

  DateTime? _selectedDeadline;
  int _selectedPresetDays = 7;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _workerController = TextEditingController(text: widget.initialWorkerAddress ?? '');
    // Generate a unique 8-character contract ID suffix
    final randomSuffix = (Random().nextInt(900000) + 100000).toString();
    _contractIdController = TextEditingController(text: 'ctr-$randomSuffix');
    _amountController = TextEditingController(text: '0.5');
    _termsController = TextEditingController();
    _selectedDeadline = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _workerController.dispose();
    _contractIdController.dispose();
    _amountController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _selectPresetDays(int days) {
    setState(() {
      _selectedPresetDays = days;
      _selectedDeadline = DateTime.now().add(Duration(days: days));
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _workerController.text = data.text!.trim();
      });
    }
  }

  Future<void> _scanWorkerAddressQr() async {
    final result = await QrScannerSheet.show(
      context,
      title: 'Scan Worker QR',
      hintText: 'Scan worker wallet address or Solana Pay code',
    );
    if (result != null && mounted) {
      if (result.solanaAddress != null) {
        setState(() {
          _workerController.text = result.solanaAddress!;
          if (result.amountSol != null && _amountController.text.trim().isEmpty) {
            _amountController.text = result.amountSol.toString();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scanned address: ${result.solanaAddress!.substring(0, 4)}…${result.solanaAddress!.substring(result.solanaAddress!.length - 4)}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unrecognized QR payload: ${result.raw}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String? _validateAddress(String? val, String? currentWallet) {
    if (val == null || val.trim().isEmpty) {
      return 'Worker address is required';
    }
    final trimmed = val.trim();
    try {
      Ed25519HDPublicKey.fromBase58(trimmed);
    } catch (_) {
      return 'Invalid Solana public key format';
    }
    if (currentWallet != null && trimmed.toLowerCase() == currentWallet.toLowerCase()) {
      return 'You cannot hire your own wallet address';
    }
    return null;
  }

  void _showReviewModal(BuildContext context, String currentWallet) {
    if (!_formKey.currentState!.validate()) return;

    final workerAddress = _workerController.text.trim();
    final contractId = _contractIdController.text.trim();
    final termsText = _termsController.text.trim();
    final amountSol = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final termsHash = ContractService.computeTermsHash(termsText);
    final termsHashHex = termsHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Review & Lock Funds',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Step 2 of 2',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount Callout
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryContainer.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ESCROW AMOUNT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${amountSol.toStringAsFixed(2)} SOL',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '≈ \$${(amountSol * 140).toStringAsFixed(2)} USD',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Review items
                _buildReviewItem('Contract ID', contractId, isMono: true),
                const Divider(height: 16, color: AppColors.surfaceContainerHigh),
                _buildReviewItem(
                  'Worker',
                  '${workerAddress.substring(0, 6)}…${workerAddress.substring(workerAddress.length - 6)}',
                  isMono: true,
                ),
                const Divider(height: 16, color: AppColors.surfaceContainerHigh),
                _buildReviewItem(
                  'Terms',
                  termsText,
                  maxLines: 2,
                ),
                const Divider(height: 16, color: AppColors.surfaceContainerHigh),
                _buildReviewItem(
                  'SHA-256 Terms Hash',
                  '${termsHashHex.substring(0, 8)}…${termsHashHex.substring(termsHashHex.length - 8)}',
                  isMono: true,
                ),
                const Divider(height: 16, color: AppColors.surfaceContainerHigh),
                _buildReviewItem(
                  'Deadline',
                  _selectedDeadline != null
                      ? '${_selectedDeadline!.month}/${_selectedDeadline!.day}/${_selectedDeadline!.year}'
                      : 'None',
                ),

                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setModalState(() => _isSubmitting = true);
                            setState(() => _isSubmitting = true);

                            try {
                              final wallet = ref.read(walletStateProvider);
                              final walletAdapter = ref.read(walletAdapterProvider);
                              final contractRepo = ref.read(contractRepositoryProvider);

                              if (!wallet.isConnected || wallet.publicKey == null) {
                                throw Exception('Please connect your Solana wallet first.');
                              }

                              final lamports = BigInt.from((amountSol * 1e9).round());

                              await contractRepo.createAndFund(
                                contractId: contractId,
                                workerAddress: workerAddress,
                                amountLamports: lamports,
                                termsText: termsText,
                                deadline: _selectedDeadline,
                                employer: wallet.publicKey!,
                                walletAdapter: walletAdapter,
                              );

                              if (modalContext.mounted) {
                                Navigator.of(modalContext).pop();
                              }
                              if (context.mounted) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ContractDetailScreen(contractId: contractId),
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() {
                                _isSubmitting = false;
                                _errorMessage = e.toString();
                              });
                              setState(() {
                                _isSubmitting = false;
                                _errorMessage = e.toString();
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Sign & Lock $amountSol SOL',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewItem(String label, String value, {bool isMono = false, int maxLines = 1}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: isMono
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  )
                : GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletStateProvider);
    final currentAddress = wallet.address;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Contract',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Step 1 of 2',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Instructions Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 20, color: AppColors.primaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Locked funds will stay safely inside the Solana escrow vault until you approve completion and release payment.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Worker Address Field
            Text(
              'Worker Solana Address',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _workerController,
              validator: (val) => _validateAddress(val, currentAddress),
              style: GoogleFonts.jetBrainsMono(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. 4ojA…VAqq',
                hintStyle: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primaryContainer),
                      onPressed: _scanWorkerAddressQr,
                      tooltip: 'Scan QR code',
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_paste_rounded, size: 20),
                      onPressed: _pasteFromClipboard,
                      tooltip: 'Paste address',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Escrow Amount Field
            Text(
              'Escrow Amount (SOL)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Amount is required';
                final num = double.tryParse(val.trim());
                if (num == null || num <= 0) return 'Enter a valid amount > 0 SOL';
                return null;
              },
              style: GoogleFonts.jetBrainsMono(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                suffixText: 'SOL',
                suffixStyle: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Terms & Scope Field
            Text(
              'Contract Scope & Deliverables',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This text will be SHA-256 hashed and permanently anchored on-chain.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _termsController,
              maxLines: 4,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Contract terms are required';
                return null;
              },
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: 'e.g. Design & implement Solana wallet connection in Flutter app with unit tests.',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.outline),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Deadline Preset Chips
            Text(
              'Expected Deadline',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPresetChip(3, '3 Days'),
                const SizedBox(width: 8),
                _buildPresetChip(7, '7 Days'),
                const SizedBox(width: 8),
                _buildPresetChip(14, '14 Days'),
                const SizedBox(width: 8),
                _buildPresetChip(30, '30 Days'),
              ],
            ),
            const SizedBox(height: 32),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _showReviewModal(context, currentAddress ?? ''),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Review & Lock Funds',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(int days, String label) {
    final isSelected = _selectedPresetDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectPresetDays(days),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryContainer
                  : AppColors.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
