import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solana/solana.dart';
import '../database/app_database.dart' hide WorkerProfile, Review, EscrowContract, SeekerAttestation;
import '../database/reputation_repository.dart';
import '../database/contract_repository.dart';
import '../database/attestation_repository.dart';
import '../database/deliverable_repository.dart';
import '../models/escrow_contract.dart';
import '../models/dispute_case.dart';
import '../models/split_proposal.dart';
import '../models/deliverable_submission.dart';
import '../models/review.dart';
import '../models/seeker_attestation.dart';
import '../models/worker_profile.dart';
import '../services/deliverable_encryption_service.dart';
import '../services/encryption_key_registry.dart';
import '../services/firebase_sync_service.dart';
import '../services/irys_storage_service.dart';
import '../solana/network_config.dart';
import '../solana/reputation_service.dart';
import '../solana/skr_staking.dart';
import '../solana/contract_service.dart';
import '../solana/wallet_adapter.dart';

// ==================== CORE INFRASTRUCTURE PROVIDERS ====================

/// Drift Database singleton provider.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Solana RPC Client provider pointing to Devnet.
final solanaClientProvider = Provider<SolanaClient>((ref) {
  return SolanaClient(
    rpcUrl: Uri.parse(NetworkConfig.devnetRpcUrl),
    websocketUrl: Uri.parse(NetworkConfig.devnetWsUrl),
  );
});

/// Anchor ReputationService provider.
final reputationServiceProvider = Provider<ReputationService>((ref) {
  final client = ref.watch(solanaClientProvider);
  return ReputationService(client: client);
});

/// Anchor ContractService provider for P2P Escrow protocol.
final contractServiceProvider = Provider<ContractService>((ref) {
  final client = ref.watch(solanaClientProvider);
  return ContractService(client: client);
});

/// Mobile Wallet Adapter provider.
final walletAdapterProvider = Provider<WalletAdapter>((ref) {
  return WalletAdapter();
});

/// Repository coordinating on-chain reputation state and Drift local cache.
final reputationRepositoryProvider = Provider<ReputationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final reputationService = ref.watch(reputationServiceProvider);
  return ReputationRepository(db: db, reputationService: reputationService);
});

/// Repository coordinating on-chain escrow contracts and Drift local cache.
final contractRepositoryProvider = Provider<ContractRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final contractService = ref.watch(contractServiceProvider);
  return ContractRepository(db: db, contractService: contractService);
});

/// Read-only source of real $SKR Guardian stake from Solana Mobile's staking
/// program. Mainnet by default; `--dart-define=CLOCKIN_SKR_STAKE_CLUSTER=devnet`
/// reads Solana Mobile's devnet deployment instead.
final skrStakeSourceProvider = Provider<SkrStakeSource>((ref) {
  return SkrStakeReader(deployment: SkrStakingDeployment.active);
});

/// Repository coordinating Seeker Attestation (real Guardian stake) and its Drift cache.
final attestationRepositoryProvider = Provider<AttestationRepository>((ref) {
  return AttestationRepository(
    db: ref.watch(databaseProvider),
    contractService: ref.watch(contractServiceProvider),
    stakeSource: ref.watch(skrStakeSourceProvider),
  );
});

/// Service providing AES-256-GCM symmetric encryption for deliverables.
final deliverableEncryptionServiceProvider = Provider<DeliverableEncryptionService>((ref) {
  return DeliverableEncryptionService();
});

/// Repository coordinating local encrypted deliverable submissions and Irys storage.
final deliverableRepositoryProvider = Provider<DeliverableRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final encryptionService = ref.watch(deliverableEncryptionServiceProvider);
  final irysService = ref.watch(irysStorageServiceProvider);
  return DeliverableRepository(
    db: db,
    encryptionService: encryptionService,
    irysService: irysService,
  );
});

/// Service coordinating real-time encrypted deliverable sync and FCM push notifications via Firebase.
final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  final deliverableRepo = ref.watch(deliverableRepositoryProvider);
  final service = FirebaseSyncService(deliverableRepository: deliverableRepo);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Publishes this device's wallet-attested X25519 public key so counterparties
/// can encrypt deliverable keys for it.
final encryptionKeyRegistryProvider = Provider<EncryptionKeyRegistry>((ref) {
  return EncryptionKeyRegistry(
    walletAdapter: ref.watch(walletAdapterProvider),
    deliverableRepository: ref.watch(deliverableRepositoryProvider),
    syncService: ref.watch(firebaseSyncServiceProvider),
  );
});

// ==================== WALLET STATE MANAGEMENT ====================

class WalletState {
  final WalletStatus status;
  final String? address;
  final Ed25519HDPublicKey? publicKey;
  final String? errorMessage;
  final String? accountLabel;

  const WalletState({
    this.status = WalletStatus.disconnected,
    this.address,
    this.publicKey,
    this.errorMessage,
    this.accountLabel,
  });

  bool get isConnected => status == WalletStatus.connected && address != null;

  WalletState copyWith({
    WalletStatus? status,
    String? address,
    Ed25519HDPublicKey? publicKey,
    String? errorMessage,
    String? accountLabel,
  }) {
    return WalletState(
      status: status ?? this.status,
      address: address ?? this.address,
      publicKey: publicKey ?? this.publicKey,
      errorMessage: errorMessage,
      accountLabel: accountLabel ?? this.accountLabel,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletAdapter _adapter;

  WalletNotifier(this._adapter) : super(const WalletState());

  /// Triggers MWA connection flow via Android intent.
  Future<bool> connect() async {
    state = state.copyWith(status: WalletStatus.connecting, errorMessage: null);

    final session = await _adapter.connect();

    if (session != null) {
      state = state.copyWith(
        status: WalletStatus.connected,
        address: session.publicKey.toBase58(),
        publicKey: session.publicKey,
        accountLabel: session.accountLabel,
      );
      return true;
    } else {
      state = state.copyWith(
        status: _adapter.status,
        errorMessage: _adapter.errorMessage,
      );
      return false;
    }
  }

  /// Disconnects the wallet session.
  Future<void> disconnect() async {
    await _adapter.disconnect();
    state = const WalletState(status: WalletStatus.disconnected);
  }
}

/// Reactive wallet state notifier provider.
final walletStateProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final adapter = ref.watch(walletAdapterProvider);
  return WalletNotifier(adapter);
});

// ==================== WORKER & REVIEWS REACTIVE PROVIDERS ====================

/// Reactive stream provider for a worker's profile by address.
/// Reads from Drift local cache while triggering on-chain RPC refresh.
final workerProfileProvider =
    StreamProvider.family<WorkerProfile?, String>((ref, address) {
  final repository = ref.watch(reputationRepositoryProvider);

  // Trigger initial cache/RPC fetch
  repository.getWorkerProfile(address);

  // Watch local cache reactively
  return repository.watchWorkerProfile(address);
});

/// Reactive stream provider for a worker's reviews.
final workerReviewsProvider =
    StreamProvider.family<List<Review>, String>((ref, address) {
  final repository = ref.watch(reputationRepositoryProvider);

  // Trigger initial cache/RPC fetch
  repository.getWorkerReviews(address);

  // Watch local cache reactively
  return repository.watchWorkerReviews(address);
});

/// Watches the profile for the currently connected wallet.
final myProfileProvider = StreamProvider<WorkerProfile?>((ref) {
  final wallet = ref.watch(walletStateProvider);
  if (!wallet.isConnected || wallet.address == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(reputationRepositoryProvider);
  repository.getWorkerProfile(wallet.address!);

  return repository.watchWorkerProfile(wallet.address!);
});

/// Watches all offline drafts stored in Drift.
final draftReviewsProvider = StreamProvider<List<DraftReview>>((ref) {
  final repository = ref.watch(reputationRepositoryProvider);
  return repository.watchDraftReviews();
});

/// Watches the Look Up screen's recent-lookups history (most recent first).
final recentLookupsProvider = StreamProvider<List<WorkerProfile>>((ref) {
  final repository = ref.watch(reputationRepositoryProvider);
  return repository.watchRecentLookups();
});

// ==================== ESCROW CONTRACTS REACTIVE PROVIDERS ====================

/// Watches all contracts for the currently connected wallet (as employer or worker).
final myContractsProvider = StreamProvider<List<EscrowContract>>((ref) {
  final wallet = ref.watch(walletStateProvider);
  if (!wallet.isConnected || wallet.address == null) {
    return Stream.value(const []);
  }

  final repository = ref.watch(contractRepositoryProvider);
  // Trigger background refresh from RPC
  repository.refreshContractsForWallet(wallet.address!);

  // Watch Drift database reactively
  return repository.watchContractsForWallet(wallet.address!);
});

/// Watches a single contract by its contractId from local Drift database,
/// while triggering an on-chain refresh from RPC.
final contractProvider = StreamProvider.family<EscrowContract?, String>((ref, contractId) {
  final repository = ref.watch(contractRepositoryProvider);
  repository.getContract(contractId);
  return repository.watchContract(contractId);
});

/// The contract's open 50/50 split proposal, read from chain. Invalidate after
/// proposing, withdrawing, or settling a dispute.
final splitProposalProvider =
    FutureProvider.autoDispose.family<SplitProposal?, String>((ref, contractId) {
  return ref.watch(contractRepositoryProvider).getSplitProposal(contractId);
});

/// Watches a DisputeCase for a contract reactively from local Drift database,
/// while triggering an on-chain refresh from Solana RPC.
final disputeCaseProvider = StreamProvider.family<DisputeCase?, String>((ref, contractId) {
  final repository = ref.watch(contractRepositoryProvider);
  repository.getDisputeCase(contractId);
  return repository.watchDisputeCase(contractId);
});

/// Watches all offline draft contracts from local Drift database.
final draftContractsProvider = StreamProvider<List<DraftContract>>((ref) {
  final repository = ref.watch(contractRepositoryProvider);
  return repository.watchDraftContracts();
});

/// Watches all encrypted deliverable submissions for a contract from Drift database.
final contractDeliverablesProvider =
    StreamProvider.family<List<DeliverableSubmission>, String>((ref, contractId) {
  final repository = ref.watch(deliverableRepositoryProvider);
  return repository.watchSubmissionsForContract(contractId);
});

/// Watches the latest encrypted deliverable submission for a contract from Drift database.
final latestDeliverableProvider =
    StreamProvider.family<DeliverableSubmission?, String>((ref, contractId) {
  final repository = ref.watch(deliverableRepositoryProvider);
  return repository.watchLatestSubmission(contractId);
});

// ==================== SETTINGS SCREEN: REAL NETWORK DATA ====================
//
// The Settings screen's Stitch source design invents several numbers that
// look plausible but aren't real: RPC latency, network epoch, slot
// commitment. All three are cheap, real RPC calls — fetch them for real
// instead of hardcoding fake ones.

/// The connected wallet's real devnet SOL balance, in lamports.
final walletBalanceProvider = FutureProvider<int?>((ref) async {
  final wallet = ref.watch(walletStateProvider);
  if (!wallet.isConnected || wallet.address == null) return null;

  final client = ref.watch(solanaClientProvider);
  final result = await client.rpcClient.getBalance(
    wallet.address!,
    commitment: Commitment.confirmed,
  );
  return result.value;
});

/// The connected wallet's real devnet $SKR token balance (UI units).
final walletSkrBalanceProvider = FutureProvider<double>((ref) async {
  final wallet = ref.watch(walletStateProvider);
  if (!wallet.isConnected || wallet.address == null) return 0.0;

  final contractService = ref.watch(contractServiceProvider);
  return contractService.getSkrBalance(wallet.address!);
});

/// Reactive stream of a worker's Seeker Attestation (Guardian stake & $SKR verification).
final seekerAttestationProvider =
    StreamProvider.family<SeekerAttestation, String>((ref, address) {
  final repo = ref.watch(attestationRepositoryProvider);
  return repo.watchAttestation(address);
});

/// A snapshot of real network facts for the Settings screen's diagnostics
/// panel — measured, not invented.
class NetworkDiagnostics {
  final int latencyMs;
  final int epoch;
  final int slotIndex;
  final int slotsInEpoch;
  final int finalizedSlot;

  const NetworkDiagnostics({
    required this.latencyMs,
    required this.epoch,
    required this.slotIndex,
    required this.slotsInEpoch,
    required this.finalizedSlot,
  });

  double get epochProgress => slotsInEpoch == 0 ? 0 : slotIndex / slotsInEpoch;
}

/// Fetches real, current network diagnostics: a round-trip latency
/// measurement against the RPC endpoint, the current epoch and how far
/// through it the network is, and the latest finalized slot.
final networkDiagnosticsProvider = FutureProvider<NetworkDiagnostics>((ref) async {
  final client = ref.watch(solanaClientProvider);

  final stopwatch = Stopwatch()..start();
  final epochInfo = await client.rpcClient.getEpochInfo(commitment: Commitment.confirmed);
  stopwatch.stop();

  final finalizedSlot = await client.rpcClient.getSlot(commitment: Commitment.finalized);

  return NetworkDiagnostics(
    latencyMs: stopwatch.elapsedMilliseconds,
    epoch: epochInfo.epoch,
    slotIndex: epochInfo.slotIndex,
    slotsInEpoch: epochInfo.slotsInEpoch,
    finalizedSlot: finalizedSlot,
  );
});
