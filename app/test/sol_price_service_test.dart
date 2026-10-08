import 'package:clockin/core/services/sol_price_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const jupiterOk =
      '{"So11111111111111111111111111111111111111112":{"usdPrice":109.98,"decimals":9}}';
  const geckoOk = '{"solana":{"usd":110.05}}';

  SolPriceService serviceWith(http.Response Function(Uri) respond) =>
      SolPriceService(client: MockClient((req) async => respond(req.url)));

  test('uses Jupiter when it answers', () async {
    final q = await serviceWith((_) => http.Response(jupiterOk, 200)).fetch();
    expect(q!.usd, 109.98);
    expect(q.source, 'Jupiter');
  });

  test('falls back to CoinGecko when Jupiter fails', () async {
    final q = await serviceWith((u) => u.host.contains('jup')
        ? http.Response('rate limited', 429)
        : http.Response(geckoOk, 200)).fetch();
    expect(q!.usd, 110.05);
    expect(q.source, 'CoinGecko');
  });

  test('returns null rather than a made-up number when both fail', () async {
    expect(await serviceWith((_) => http.Response('down', 503)).fetch(), isNull);
  });

  test('rejects malformed, zero, or negative prices', () async {
    for (final body in [
      '{"So11111111111111111111111111111111111111112":{"usdPrice":0}}',
      '{"So11111111111111111111111111111111111111112":{"usdPrice":-3}}',
      '{"So11111111111111111111111111111111111111112":{"usdPrice":"110"}}',
      'not json',
    ]) {
      final q = await serviceWith((u) =>
              u.host.contains('jup') ? http.Response(body, 200) : http.Response('x', 500))
          .fetch();
      expect(q, isNull, reason: body);
    }
  });

  test('formatSolUsd multiplies by the live quote and hides without one', () {
    final q = SolUsdQuote(usd: 110, source: 'Jupiter', fetchedAt: DateTime(2026));
    expect(formatSolUsd(0.5, q), '≈ \$55.00 USD');
    expect(formatSolUsd(2, q, fractionDigits: 0), '≈ \$220 USD');
    expect(formatSolUsd(0.5, null), isNull);
  });
}
