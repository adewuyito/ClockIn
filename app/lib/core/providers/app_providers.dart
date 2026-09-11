import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solana/solana.dart';
import '../database/app_database.dart' hide WorkerProfile, Review;
import '../database/reputation_repository.dart';
import '../models/review.dart';
import '../models/worker_profile.dart';
import '../solana/network_config.dart';
import '../solana/reputation_service.dart';
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

/// Mobile Wallet Adapter provider.
final walletAdapterProvider = Provider<WalletAdapter>((ref) {
  return WalletAdapter();
});

/// Repository coordinating on-chain state and Drift local cache.
final reputationRepositoryProvider = Provider<ReputationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final reputationService = ref.watch(reputationServiceProvider);
  return ReputationRepository(db: db, reputationService: reputationService);
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
