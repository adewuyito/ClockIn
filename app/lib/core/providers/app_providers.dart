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

  const WalletState({
    this.status = WalletStatus.disconnected,
    this.address,
    this.publicKey,
    this.errorMessage,
  });

  bool get isConnected => status == WalletStatus.connected && address != null;

  WalletState copyWith({
    WalletStatus? status,
    String? address,
    Ed25519HDPublicKey? publicKey,
    String? errorMessage,
  }) {
    return WalletState(
      status: status ?? this.status,
      address: address ?? this.address,
      publicKey: publicKey ?? this.publicKey,
      errorMessage: errorMessage,
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
