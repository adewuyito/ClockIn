import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:solana/solana.dart';

void main() async {
  final target = 'Ac4CjecDdASGmd3y4UPGXrutxEV9Prh5d4e1YS5bFhrm';
  print('Target: $target');

  // Check some common phrases
  final phrases = [
    'helius',
    'guardian_helius',
    'guardian_1',
    'juror_1',
    'juror1',
    'seeker_guardian_1',
    'seeker_helius',
  ];

  for (final p in phrases) {
    final seed = sha256.convert(utf8.encode(p)).bytes;
    final kp = await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: seed);
    if (kp.publicKey.toBase58() == target) {
      print('FOUND SEED: $p');
      return;
    }
  }
  print('Not a simple sha256 phrase');
}
