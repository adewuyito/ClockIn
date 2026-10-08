import 'dart:convert';
import 'dart:typed_data';

import 'package:clockin/core/solana/account_decoders.dart';
import 'package:clockin/core/solana/network_config.dart';
import 'package:clockin/core/solana/program_instructions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';

/// The 50/50 split needs both parties: one sends `propose_split`, the other
/// accepts with `resolve_dispute(Split5050)`, which must pass the proposal PDA.
/// These tests pin the app's instruction encoding to the deployed program.
void main() {
  const contractId = 'ctr-split-42';
  final employer = Ed25519HDPublicKey.fromBase58('Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ');
  final worker = Ed25519HDPublicKey.fromBase58('A1b2C3d4E5f6G7h8J9kLMnPQRsTUVWXYZabcdefghijk');

  List<int> anchorDiscriminator(String name) =>
      sha256.convert(utf8.encode('global:$name')).bytes.sublist(0, 8);

  List<int> idArg(String id) {
    final b = utf8.encode(id);
    return [...(ByteData(4)..setUint32(0, b.length, Endian.little)).buffer.asUint8List(), ...b];
  }

  group('discriminators match the program', () {
    test('propose_split and cancel_split_proposal', () {
      expect(ProgramInstructions.proposeSplitDiscriminator, anchorDiscriminator('propose_split'));
      expect(ProgramInstructions.cancelSplitProposalDiscriminator,
          anchorDiscriminator('cancel_split_proposal'));
    });

    test('SplitProposal account', () {
      expect(
        AccountDecoders.splitProposalDiscriminator,
        sha256.convert(utf8.encode('account:SplitProposal')).bytes.sublist(0, 8),
      );
    });
  });

  group('instruction builders', () {
    test('propose_split: proposer signs and pays; escrow read-only; proposal writable', () async {
      final ix = await ProgramInstructions.proposeSplit(proposer: worker, contractId: contractId);
      final proposal = await NetworkConfig.findSplitProposalPda(contractId);

      expect(ix.programId, NetworkConfig.programId);
      expect(ix.accounts.map((a) => a.pubKey).toList(), [
        worker,
        await NetworkConfig.findEscrowPda(contractId),
        proposal,
        Ed25519HDPublicKey.fromBase58('11111111111111111111111111111111'),
      ]);
      expect(ix.accounts[0].isSigner && ix.accounts[0].isWriteable, isTrue);
      expect(ix.accounts[1].isWriteable, isFalse);
      expect(ix.accounts[2].isWriteable, isTrue);
      expect(ix.data.toList(), [...anchorDiscriminator('propose_split'), ...idArg(contractId)]);
    });

    test('cancel_split_proposal: proposer + proposal only', () async {
      final ix = await ProgramInstructions.cancelSplitProposal(proposer: employer, contractId: contractId);
      expect(ix.accounts.map((a) => a.pubKey).toList(), [
        employer,
        await NetworkConfig.findSplitProposalPda(contractId),
      ]);
      expect(ix.accounts[0].isSigner, isTrue);
      expect(ix.accounts[1].isWriteable, isTrue);
      expect(ix.data.toList(), [...anchorDiscriminator('cancel_split_proposal'), ...idArg(contractId)]);
    });

    test('resolve_dispute passes the split proposal PDA last, writable', () async {
      final ix = await ProgramInstructions.resolveDispute(
        caller: employer,
        employer: employer,
        worker: worker,
        contractId: contractId,
        resolution: DisputeResolution.split5050,
      );
      expect(ix.accounts.length, 7);
      expect(ix.accounts.last.pubKey, await NetworkConfig.findSplitProposalPda(contractId));
      expect(ix.accounts.last.isWriteable, isTrue);
      expect(ix.accounts.last.isSigner, isFalse);
    });

    test('resolve_token_dispute passes the split proposal PDA last, writable', () async {
      final ix = await ProgramInstructions.resolveTokenDispute(
        caller: worker,
        employer: employer,
        worker: worker,
        mint: NetworkConfig.usdcMint,
        contractId: contractId,
        resolution: DisputeResolution.split5050,
      );
      expect(ix.accounts.last.pubKey, await NetworkConfig.findSplitProposalPda(contractId));
      expect(ix.accounts.last.isWriteable, isTrue);
    });
  });

  group('SplitProposal decoding', () {
    Uint8List encode({List<int>? discriminator}) {
      final b = BytesBuilder()
        ..add(discriminator ?? AccountDecoders.splitProposalDiscriminator)
        ..add(employer.bytes) // escrow_contract (any 32 bytes)
        ..add(worker.bytes) // proposer
        ..add((ByteData(8)..setInt64(0, 1791400000, Endian.little)).buffer.asUint8List())
        ..addByte(254); // bump
      return b.toBytes();
    }

    test('decodes proposer and timestamp', () {
      final p = AccountDecoders.decodeSplitProposal(encode())!;
      expect(p.proposer, worker.toBase58());
      expect(p.createdAt, DateTime.fromMillisecondsSinceEpoch(1791400000 * 1000, isUtc: true));
      expect(p.isProposedBy(worker.toBase58()), isTrue);
      expect(p.isProposedBy(employer.toBase58()), isFalse);
      expect(p.isProposedBy(null), isFalse);
    });

    test('rejects other account types and short data', () {
      expect(AccountDecoders.decodeSplitProposal(encode(discriminator: List.filled(8, 0))), isNull);
      expect(AccountDecoders.decodeSplitProposal(encode().sublist(0, 40)), isNull);
    });
  });
}
