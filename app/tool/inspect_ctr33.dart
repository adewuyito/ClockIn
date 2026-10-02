import 'package:solana/dto.dart' hide Instruction;
import 'package:solana/solana.dart';
import 'package:clockin/core/solana/network_config.dart';
import 'package:clockin/core/solana/account_decoders.dart';

void main() async {
  final client = SolanaClient(
    rpcUrl: Uri.parse(NetworkConfig.devnetRpcUrl),
    websocketUrl: Uri.parse(NetworkConfig.devnetWsUrl),
  );

  print('Fetching all program accounts for ${NetworkConfig.programId.toBase58()}...');
  final accounts = await client.rpcClient.getProgramAccounts(
    NetworkConfig.programId.toBase58(),
    encoding: Encoding.base64,
    commitment: Commitment.confirmed,
  );

  print('Total program accounts found: ${accounts.length}');

  for (final acc in accounts) {
    final data = acc.account.data;
    if (data is BinaryAccountData) {
      final bytes = data.data;
      if (bytes.length >= 8) {
        final disc = bytes.sublist(0, 8);
        bool isEscrow = true;
        for (int i = 0; i < 8; i++) {
          if (disc[i] != AccountDecoders.escrowContractDiscriminator[i]) {
            isEscrow = false;
            break;
          }
        }
        bool isDispute = true;
        for (int i = 0; i < 8; i++) {
          if (disc[i] != AccountDecoders.disputeCaseDiscriminator[i]) {
            isDispute = false;
            break;
          }
        }

        if (isEscrow) {
          try {
            final c = AccountDecoders.decodeEscrowContract(bytes);
            print('ESCROW: id=${c.contractId}, status=${c.status}, emp=${c.employer}, wrk=${c.worker}');
          } catch (e) {
            print('ESCROW decode error: $e');
          }
        } else if (isDispute) {
          try {
            final d = AccountDecoders.decodeDisputeCase(bytes);
            print('DISPUTE CASE: contractId=${d.contractId}, status=${d.status}, j1=${d.juror1} (v=${d.vote1}), j2=${d.juror2} (v=${d.vote2}), j3=${d.juror3} (v=${d.vote3})');
          } catch (e) {
            print('DISPUTE decode error: $e');
          }
        }
      }
    }
  }
}
