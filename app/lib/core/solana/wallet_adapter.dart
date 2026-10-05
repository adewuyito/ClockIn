import 'package:flutter/foundation.dart';
import 'package:solana/base58.dart';
import 'package:solana/solana.dart';
import 'package:solana_mobile_client/solana_mobile_client.dart';
import 'network_config.dart';

/// Connection status of the user's mobile wallet.
enum WalletStatus {
  disconnected,
  connecting,
  connected,
  noWalletFound,
  error,
}

/// Represents an active or cached authorization session with an MWA wallet.
class WalletSession {
  final String authToken;
  final Ed25519HDPublicKey publicKey;
  final String? accountLabel;
  final Uri? walletUriBase;

  const WalletSession({
    required this.authToken,
    required this.publicKey,
    this.accountLabel,
    this.walletUriBase,
  });
}

/// Mobile Wallet Adapter (MWA) client wrapper for ClockIn.
/// Zero private key custody: all signing is delegated via Android intents
/// to user-installed wallet applications (Phantom, Solflare, etc.).
class WalletAdapter {
  WalletSession? _session;
  WalletStatus _status = WalletStatus.disconnected;
  String? _errorMessage;

  WalletSession? get session => _session;
  WalletStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Ed25519HDPublicKey? get publicKey => _session?.publicKey;
  String? get address => _session?.publicKey.toBase58();
  bool get isConnected => _status == WalletStatus.connected && _session != null;

  /// Identity metadata sent to wallet apps during authorization.
  final Uri identityUri = Uri.parse('https://clockin.app');
  final Uri iconUri = Uri.parse('favicon.ico');
  final String identityName = 'ClockIn';

  /// Checks if any MWA-compatible wallet app is installed on the Android device.
  Future<bool> isWalletAvailable() async {
    try {
      return await LocalAssociationScenario.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Connects and authorizes with an installed wallet application via MWA.
  Future<WalletSession?> connect() async {
    _status = WalletStatus.connecting;
    _errorMessage = null;

    final available = await isWalletAvailable();
    if (!available) {
      _status = WalletStatus.noWalletFound;
      _errorMessage =
          'No compatible Solana wallet found. Please install Phantom or Solflare.';
      return null;
    }

    LocalAssociationScenario? scenario;
    try {
      scenario = await LocalAssociationScenario.create();
      scenario.startActivityForResult(null).ignore();
      final client = await scenario.start();

      // Attempt authorization with devnet cluster first, falling back to default cluster
      // in case the wallet (e.g. Phantom) is in generic testnet mode.
      var authResult = await client.authorize(
        identityUri: identityUri,
        iconUri: iconUri,
        identityName: identityName,
        cluster: NetworkConfig.clusterName,
      );

      if (authResult != null) {
        debugPrint('[MWA] connect(): devnet-scoped authorize succeeded.');
      } else {
        debugPrint('[MWA] connect(): devnet-scoped authorize returned null, falling back to no-cluster authorize...');
        authResult = await client.authorize(
          identityUri: identityUri,
          iconUri: iconUri,
          identityName: identityName,
        );
        debugPrint('[MWA] connect(): no-cluster authorize ${authResult != null ? "succeeded" : "also returned null"}.');
      }

      if (authResult == null) {
        _status = WalletStatus.error;
        _errorMessage = 'Wallet authorization was declined.';
        return null;
      }

      final pubKey = Ed25519HDPublicKey(authResult.publicKey);
      _session = WalletSession(
        authToken: authResult.authToken,
        publicKey: pubKey,
        accountLabel: authResult.accountLabel,
        walletUriBase: authResult.walletUriBase,
      );

      _status = WalletStatus.connected;
      return _session;
    } catch (e) {
      _status = WalletStatus.error;
      _errorMessage = 'Failed to connect wallet: $e';
      return null;
    } finally {
      await scenario?.close();
    }
  }

  /// Disconnects the wallet and deauthorizes the auth token.
  Future<void> disconnect() async {
    final token = _session?.authToken;
    _session = null;
    _status = WalletStatus.disconnected;
    _errorMessage = null;

    if (token != null) {
      LocalAssociationScenario? scenario;
      try {
        scenario = await LocalAssociationScenario.create();
        final client = await scenario.start();
        await client.deauthorize(authToken: token);
      } catch (_) {
        // Ignore deauthorize cleanup errors
      } finally {
        await scenario?.close();
      }
    }
  }

  /// Refreshes the MWA authorization for an open scenario, replacing [_session]
  /// with the renewed authorization.
  ///
  /// Prefers `reauthorize` with the cached auth token; if the wallet rejects or
  /// has forgotten it, falls back to a devnet-scoped `authorize` and then to a
  /// cluster-less `authorize` (some wallets reject the `cluster` parameter while
  /// in a generic testnet mode). Throws if every path is declined.
  Future<void> _reauthorize(MobileWalletAdapterClient client) async {
    final reauth = await client.reauthorize(
      identityUri: identityUri,
      iconUri: iconUri,
      identityName: identityName,
      authToken: _session!.authToken,
    );

    if (reauth != null) {
      _session = WalletSession(
        authToken: reauth.authToken,
        publicKey: Ed25519HDPublicKey(reauth.publicKey),
        accountLabel: reauth.accountLabel,
        walletUriBase: reauth.walletUriBase,
      );
      return;
    }

    debugPrint('[MWA] Reauthorization returned null, falling back to authorize...');
    var auth = await client.authorize(
      identityUri: identityUri,
      iconUri: iconUri,
      identityName: identityName,
      cluster: NetworkConfig.clusterName,
    );
    if (auth != null) {
      debugPrint('[MWA] sign(): devnet-scoped authorize succeeded.');
    } else {
      debugPrint('[MWA] sign(): devnet-scoped authorize returned null, falling back to no-cluster authorize...');
      auth = await client.authorize(
        identityUri: identityUri,
        iconUri: iconUri,
        identityName: identityName,
      );
      debugPrint('[MWA] sign(): no-cluster authorize ${auth != null ? "succeeded" : "also returned null"}.');
    }
    if (auth == null) {
      throw Exception('Wallet authorization was declined.');
    }
    _session = WalletSession(
      authToken: auth.authToken,
      publicKey: Ed25519HDPublicKey(auth.publicKey),
      accountLabel: auth.accountLabel,
      walletUriBase: auth.walletUriBase,
    );
  }

  /// Prompts the connected wallet to sign an arbitrary off-chain message and
  /// returns the raw 64-byte Ed25519 signature.
  ///
  /// Used to attest ownership of this device's X25519 encryption key (see
  /// [KeyAttestationService]) — nothing is broadcast and no fee is paid. Wallets
  /// render [message] in their approval prompt, so keep it short and printable.
  Future<Uint8List> signMessage(Uint8List message) async {
    if (!isConnected || _session == null) {
      throw StateError('Cannot sign message: Wallet is not connected.');
    }

    LocalAssociationScenario? scenario;
    try {
      scenario = await LocalAssociationScenario.create();
      scenario.startActivityForResult(null).ignore();
      final client = await scenario.start();

      await _reauthorize(client);

      debugPrint('[MWA] Requesting wallet to sign off-chain message...');
      final result = await client.signMessages(
        messages: [message],
        addresses: [Uint8List.fromList(_session!.publicKey.bytes)],
      );

      final signatures = result.signedMessages
          .expand((signed) => signed.signatures)
          .where((signature) => signature.length == 64)
          .toList();

      if (signatures.isEmpty) {
        throw Exception('Message signing was rejected by wallet.');
      }

      debugPrint('[MWA] Off-chain message signed.');
      return signatures.first;
    } catch (e, st) {
      debugPrint('[MWA] Error in signMessage: $e\n$st');
      rethrow;
    } finally {
      await scenario?.close();
    }
  }

  /// Prompts the connected wallet to sign and broadcast a compiled transaction on Devnet.
  Future<String> signAndSendTransaction(Uint8List compiledTransaction) async {
    if (!isConnected || _session == null) {
      throw StateError('Cannot sign transaction: Wallet is not connected.');
    }

    LocalAssociationScenario? scenario;
    try {
      scenario = await LocalAssociationScenario.create();
      scenario.startActivityForResult(null).ignore();
      final client = await scenario.start();

      await _reauthorize(client);

      debugPrint('[MWA] session walletUriBase=${_session!.walletUriBase}');
      debugPrint('[MWA] Requesting wallet to sign and send transaction...');
      final result = await client.signAndSendTransactions(
        transactions: [compiledTransaction],
      );
      debugPrint('[MWA] signAndSendTransactions returned ${result.signatures.length} signatures');

      if (result.signatures.isEmpty) {
        throw Exception('Transaction was rejected by wallet.');
      }

      final signatureBytes = result.signatures.first;
      final sigStr = base58encode(signatureBytes);
      debugPrint('[MWA] Transaction signed & submitted: $sigStr');
      return sigStr;
    } catch (e, st) {
      debugPrint('[MWA] Error in signAndSendTransaction: $e\n$st');
      rethrow;
    } finally {
      await scenario?.close();
    }
  }
}
