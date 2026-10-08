import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A SOL/USD quote and where it came from.
class SolUsdQuote {
  final double usd;
  final String source;
  final DateTime fetchedAt;

  const SolUsdQuote({required this.usd, required this.source, required this.fetchedAt});
}

/// Live SOL/USD market price, used only to show an indicative "≈ $X USD" next
/// to SOL amounts. It is never used for any on-chain amount.
///
/// Read-only HTTPS: Jupiter's price API first (Solana-native, keyless), then
/// CoinGecko as a fallback. Returns null when both fail, so the UI hides the
/// figure instead of showing a stale or invented one.
///
/// This is the mainnet market price. Devnet SOL itself has no value; the figure
/// shows what the same amount would be worth on mainnet.
class SolPriceService {
  final http.Client _client;

  SolPriceService({http.Client? client}) : _client = client ?? http.Client();

  static const _wrappedSolMint = 'So11111111111111111111111111111111111111112';
  static const _timeout = Duration(seconds: 6);

  static final Uri jupiterUri =
      Uri.parse('https://lite-api.jup.ag/price/v3?ids=$_wrappedSolMint');
  static final Uri coingeckoUri =
      Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=solana&vs_currencies=usd');

  Future<SolUsdQuote?> fetch() async {
    final jupiter = await _get(jupiterUri, (json) => json[_wrappedSolMint]?['usdPrice']);
    if (jupiter != null) {
      return SolUsdQuote(usd: jupiter, source: 'Jupiter', fetchedAt: DateTime.now());
    }
    final gecko = await _get(coingeckoUri, (json) => json['solana']?['usd']);
    if (gecko != null) {
      return SolUsdQuote(usd: gecko, source: 'CoinGecko', fetchedAt: DateTime.now());
    }
    return null;
  }

  Future<double?> _get(Uri uri, Object? Function(dynamic json) pick) async {
    try {
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final value = pick(jsonDecode(res.body));
      // Reject anything that isn't a plausible positive price.
      if (value is num && value.isFinite && value > 0) return value.toDouble();
    } catch (e) {
      debugPrint('[SolPrice] $uri failed: $e');
    }
    return null;
  }
}

/// "≈ $12.34 USD" for [sol] at [quote], or null when there is no live quote.
String? formatSolUsd(double sol, SolUsdQuote? quote, {int fractionDigits = 2}) {
  if (quote == null) return null;
  return '≈ \$${(sol * quote.usd).toStringAsFixed(fractionDigits)} USD';
}
