import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../solana/network_config.dart';

/// What stands between the app and Solana right now.
enum NetworkStatus {
  /// The Solana RPC answered.
  online,

  /// The device has no internet connection at all.
  offline,

  /// The device is online but the Solana RPC did not answer.
  rpcUnreachable,
}

/// Thrown before an on-chain operation starts when it could not succeed.
/// [toString] is the user-facing message, so screens that show `e.toString()`
/// display it as is.
class NetworkUnavailableException implements Exception {
  final NetworkStatus status;

  const NetworkUnavailableException(this.status);

  String get message => status == NetworkStatus.offline
      ? 'No internet connection. Connect to Wi-Fi or mobile data and try again.'
      : "You're online, but Solana ${NetworkConfig.clusterName} isn't responding. "
          'Wait a moment and try again.';

  @override
  String toString() => message;
}

/// Checks connectivity immediately before operations that need the chain, so
/// the user is told plainly instead of being handed to their wallet app for a
/// transaction that cannot be built or sent.
///
/// It probes the thing the operation depends on (the Solana RPC) rather than
/// the OS "connected" flag, which is true on Wi-Fi with no internet behind it.
class NetworkStatusService {
  final Future<bool> Function() _hasInternet;
  final Future<bool> Function() _rpcResponds;

  NetworkStatusService({
    Future<bool> Function()? hasInternet,
    Future<bool> Function()? rpcResponds,
    http.Client? client,
  })  : _hasInternet = hasInternet ?? _defaultHasInternet,
        _rpcResponds = rpcResponds ?? (() => _defaultRpcResponds(client ?? http.Client()));

  static const _dnsTimeout = Duration(seconds: 4);
  static const _rpcTimeout = Duration(seconds: 6);

  Future<NetworkStatus> check() async {
    if (await _rpcResponds()) return NetworkStatus.online;
    return await _hasInternet() ? NetworkStatus.rpcUnreachable : NetworkStatus.offline;
  }

  /// Completes if the chain is reachable; otherwise throws
  /// [NetworkUnavailableException] saying which part is down.
  Future<void> ensureOnline() async {
    final status = await check();
    if (status != NetworkStatus.online) throw NetworkUnavailableException(status);
  }

  static Future<bool> _defaultRpcResponds(http.Client client) async {
    try {
      final res = await client
          .post(
            Uri.parse(NetworkConfig.rpcUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'getHealth'}),
          )
          .timeout(_rpcTimeout);
      // Any JSON-RPC answer means the node is reachable; 429 and 5xx mean it
      // can't serve a transaction right now.
      return res.statusCode < 400;
    } catch (e) {
      debugPrint('[Network] RPC probe failed: $e');
      return false;
    }
  }

  static Future<bool> _defaultHasInternet() async {
    // Two unrelated hosts, so one provider's outage isn't read as "offline".
    for (final host in const ['one.one.one.one', 'dns.google']) {
      try {
        final result = await InternetAddress.lookup(host).timeout(_dnsTimeout);
        if (result.isNotEmpty) return true;
      } catch (_) {}
    }
    return false;
  }
}
