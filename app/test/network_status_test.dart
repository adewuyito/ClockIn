import 'package:clockin/core/services/network_status.dart';
import 'package:clockin/core/solana/reputation_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  NetworkStatusService service({required bool rpc, required bool internet}) =>
      NetworkStatusService(rpcResponds: () async => rpc, hasInternet: () async => internet);

  test('online when the Solana RPC answers', () async {
    expect(await service(rpc: true, internet: true).check(), NetworkStatus.online);
    await service(rpc: true, internet: true).ensureOnline();
  });

  test('offline when nothing is reachable', () async {
    expect(await service(rpc: false, internet: false).check(), NetworkStatus.offline);
  });

  test('distinguishes "Solana is down" from "you are offline"', () async {
    expect(await service(rpc: false, internet: true).check(), NetworkStatus.rpcUnreachable);
  });

  test('does not probe for internet when the RPC already answered', () async {
    var probed = false;
    final s = NetworkStatusService(
      rpcResponds: () async => true,
      hasInternet: () async => probed = true,
    );
    await s.check();
    expect(probed, isFalse);
  });

  test('ensureOnline throws a message a user can act on', () async {
    await expectLater(
      service(rpc: false, internet: false).ensureOnline(),
      throwsA(isA<NetworkUnavailableException>()
          .having((e) => e.toString(), 'message', contains('No internet connection'))),
    );
    await expectLater(
      service(rpc: false, internet: true).ensureOnline(),
      throwsA(isA<NetworkUnavailableException>()
          .having((e) => e.toString(), 'message', contains("isn't responding"))),
    );
  });

  group('default RPC probe', () {
    Future<NetworkStatus> withRpc(http.Response Function() respond) => NetworkStatusService(
          client: MockClient((_) async => respond()),
          hasInternet: () async => true,
        ).check();

    test('a JSON-RPC answer counts as reachable', () async {
      expect(await withRpc(() => http.Response('{"result":"ok"}', 200)), NetworkStatus.online);
    });

    test('rate limiting and server errors count as not responding', () async {
      expect(await withRpc(() => http.Response('', 429)), NetworkStatus.rpcUnreachable);
      expect(await withRpc(() => http.Response('', 503)), NetworkStatus.rpcUnreachable);
    });

    test('a thrown socket error counts as not responding', () async {
      expect(await withRpc(() => throw Exception('SocketException')), NetworkStatus.rpcUnreachable);
    });
  });

  test('transaction errors carry the plain message, with no class-name prefix', () {
    final e = ReputationException.from(const NetworkUnavailableException(NetworkStatus.offline));
    expect(e.kind, ReputationErrorKind.network);
    expect(e.toString(), startsWith('No internet connection'));
  });
}
