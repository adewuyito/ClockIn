import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:clockin/core/database/app_database.dart' hide WorkerProfile, Review, EscrowContract;
import 'package:clockin/core/database/contract_repository.dart';
import 'package:clockin/core/models/escrow_contract.dart';
import 'package:clockin/core/solana/account_decoders.dart';
import 'package:clockin/core/solana/contract_service.dart';
import 'package:clockin/core/solana/network_config.dart';
import 'package:clockin/core/solana/program_instructions.dart';

void main() {
  group('Escrow NetworkConfig & PDAs', () {
    test('Escrow and Vault PDAs derive correctly and deterministically', () async {
      const contractId = 'ctr-dev-999';

      final escrowPda1 = await NetworkConfig.findEscrowPda(contractId);
      final escrowPda2 = await NetworkConfig.findEscrowPda(contractId);
      final vaultPda = await NetworkConfig.findVaultPda(contractId);

      expect(escrowPda1.toBase58(), equals(escrowPda2.toBase58()));
      expect(escrowPda1.bytes.length, equals(32));
      expect(vaultPda.bytes.length, equals(32));
      // Escrow and Vault PDAs must be distinct
      expect(escrowPda1.toBase58(), isNot(equals(vaultPda.toBase58())));
    });
  });

  group('EscrowCurrency classification & exact amount formatting', () {
    const otherMint = 'So11111111111111111111111111111111111111112';

    EscrowContract contractWith({
      required BigInt amount,
      bool isToken = false,
      String? tokenMint,
    }) =>
        EscrowContract(
          contractId: 'ctr-fmt',
          employer: 'Fx1gLqXSeYBMwTM4VvFJ8pQPY1dPDLBsMFJNNVVPYPkZ',
          worker: 'A1b2C3d4E5f6G7h8J9kLMnPQRsTUVWXYZabcdefghijk',
          amount: amount,
          termsHash: '00',
          status: ContractStatus.funded,
          createdAt: DateTime.utc(2026, 10, 6),
          isToken: isToken,
          tokenMint: tokenMint,
        );

    test('classifies SOL, USDC and \$SKR by mint', () {
      expect(EscrowCurrency.fromMintOrToken(isToken: false), EscrowCurrency.sol);
      expect(
        EscrowCurrency.fromMintOrToken(isToken: true, tokenMint: NetworkConfig.devnetUsdcMint),
        EscrowCurrency.usdc,
      );
      expect(
        EscrowCurrency.fromMintOrToken(isToken: true, tokenMint: NetworkConfig.devnetSkrMint),
        EscrowCurrency.skr,
      );
    });

    test('an unrecognised mint is UNKNOWN, never mislabelled as \$SKR', () {
      final c = contractWith(
        amount: BigInt.from(500000000),
        isToken: true,
        tokenMint: otherMint,
      );
      expect(c.currency, EscrowCurrency.unknown);
      expect(c.isUnknownMint, isTrue);
      expect(c.isSkr, isFalse);
      expect(c.currencySymbol, isNot(contains('SKR')));
      expect(c.formattedAmount, equals('500000000 base units (unverified token)'));
      expect(EscrowCurrency.unknown.mintAddress, isNull);
      expect(EscrowCurrency.unknown.isRecognised, isFalse);
    });

    test('a legacy token row with no recorded mint is treated as \$SKR', () {
      // Rows cached before multi-currency support had no mint; $SKR was the
      // only token escrow that existed then.
      expect(EscrowCurrency.fromMintOrToken(isToken: true), EscrowCurrency.skr);
      expect(EscrowCurrency.fromMintOrToken(isToken: true, tokenMint: ''), EscrowCurrency.skr);
    });

    test('formats each currency by its own decimals', () {
      expect(contractWith(amount: BigInt.from(1500000000)).formattedAmount, '1.5 SOL');
      expect(
        contractWith(amount: BigInt.from(50000000), isToken: true, tokenMint: NetworkConfig.devnetUsdcMint)
            .formattedAmount,
        '50 USDC',
      );
      expect(
        contractWith(amount: BigInt.from(500000000), isToken: true, tokenMint: NetworkConfig.devnetSkrMint)
            .formattedAmount,
        '500 \$SKR',
      );
    });

    test('formatting is exact — no float rounding of sub-cent amounts', () {
      final usdc = contractWith(
        amount: BigInt.from(12345678),
        isToken: true,
        tokenMint: NetworkConfig.devnetUsdcMint,
      );
      expect(usdc.formattedAmount, '12.345678 USDC');
      expect(usdc.formatBaseUnits(BigInt.one), '0.000001 USDC');
      expect(contractWith(amount: BigInt.from(400000)).formattedAmount, '0.0004 SOL');
      expect(contractWith(amount: BigInt.from(1)).formattedAmount, '0.000000001 SOL');
    });

    test('50/50 split mirrors the program: worker floors, employer gets the remainder', () {
      final odd = contractWith(
        amount: BigInt.from(50000001),
        isToken: true,
        tokenMint: NetworkConfig.devnetUsdcMint,
      );
      expect(odd.splitWorkerShare, BigInt.from(25000000));
      expect(odd.splitEmployerShare, BigInt.from(25000001));
      expect(odd.splitWorkerShare + odd.splitEmployerShare, odd.amount);
      expect(odd.formatBaseUnits(odd.splitWorkerShare), '25 USDC');
      expect(odd.formatBaseUnits(odd.splitEmployerShare), '25.000001 USDC');
    });

    test('amountUi scales by the contract currency, not a fixed SOL divisor', () {
      final usdc = contractWith(
        amount: BigInt.from(50000000),
        isToken: true,
        tokenMint: NetworkConfig.devnetUsdcMint,
      );
      expect(usdc.amountUi, 50.0);
      expect(contractWith(amount: BigInt.from(500000000)).amountUi, 0.5);
    });
  });

  group('ContractStatus.isTerminal — notification suppression gate', () {
    test('settled states are terminal', () {
      expect(ContractStatus.completed.isTerminal, isTrue);
      expect(ContractStatus.cancelled.isTerminal, isTrue);
    });

    test('in-flight states are not terminal', () {
      expect(ContractStatus.created.isTerminal, isFalse);
      expect(ContractStatus.funded.isTerminal, isFalse);
      expect(ContractStatus.inProgress.isTerminal, isFalse);
    });

    test('disputed is NOT terminal — a dispute is still live work', () {
      // Both parties still need events while a dispute is open, whether it
      // resolves directly or through juror arbitration.
      expect(ContractStatus.disputed.isTerminal, isFalse);
    });

    test('every status is classified', () {
      for (final status in ContractStatus.values) {
        expect(status.isTerminal, isA<bool>());
      }
      expect(
        ContractStatus.values.where((s) => s.isTerminal).length,
        equals(2),
      );
    });
  });

  group('Escrow AccountDecoders', () {
    test('Decodes valid EscrowContract binary account data', () {
      final employerKey = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );
      final workerKey = Ed25519HDPublicKey.fromBase58(
        'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9',
      );
      const contractId = 'ctr-sol-42';
      final contractIdBytes = utf8.encode(contractId);
      final termsHash = List<int>.generate(32, (i) => i);

      final totalLen = 8 + 4 + contractIdBytes.length + 32 + 32 + 8 + 32 + 1 + 8 + 8 + 8 + 8 + 1 + 1 + 1;
      final buffer = Uint8List(totalLen);
      final byteData = ByteData.sublistView(buffer);

      // Discriminator
      buffer.setRange(0, 8, AccountDecoders.escrowContractDiscriminator);
      int offset = 8;

      // contract_id
      byteData.setUint32(offset, contractIdBytes.length, Endian.little);
      offset += 4;
      buffer.setRange(offset, offset + contractIdBytes.length, contractIdBytes);
      offset += contractIdBytes.length;

      // employer
      buffer.setRange(offset, offset + 32, employerKey.bytes);
      offset += 32;

      // worker
      buffer.setRange(offset, offset + 32, workerKey.bytes);
      offset += 32;

      // amount = 1.5 SOL (1_500_000_000 lamports)
      byteData.setUint64(offset, 1500000000, Endian.little);
      offset += 8;

      // terms_hash
      buffer.setRange(offset, offset + 32, termsHash);
      offset += 32;

      // status = 1 (funded)
      buffer[offset] = 1;
      offset += 1;

      // deadline = 1750000000
      byteData.setInt64(offset, 1750000000, Endian.little);
      offset += 8;

      // created_at = 1700000000
      byteData.setInt64(offset, 1700000000, Endian.little);
      offset += 8;

      // funded_at = 1700000100
      byteData.setInt64(offset, 1700000100, Endian.little);
      offset += 8;

      // completed_at = 0
      byteData.setInt64(offset, 0, Endian.little);
      offset += 8;

      // rating = 0
      buffer[offset] = 0;
      offset += 1;

      // bump
      buffer[offset] = 255;
      offset += 1;

      // vault_bump
      buffer[offset] = 254;

      final contract = AccountDecoders.decodeEscrowContract(buffer);

      expect(contract.contractId, equals(contractId));
      expect(contract.employer, equals(employerKey.toBase58()));
      expect(contract.worker, equals(workerKey.toBase58()));
      expect(contract.amount, equals(BigInt.from(1500000000)));
      expect(contract.amountUi, equals(1.5));
      expect(contract.formattedAmount, equals('1.5 SOL'));
      expect(contract.status, equals(ContractStatus.funded));
      expect(contract.deadline, isNotNull);
      expect(contract.rating, equals(0));
    });
  });

  group('Escrow ProgramInstructions', () {
    test('Builds valid createAndFund instruction with correct accounts and data', () async {
      final employer = Ed25519HDPublicKey.fromBase58('GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P');
      final worker = Ed25519HDPublicKey.fromBase58('FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9');
      const contractId = 'ctr-123';
      final termsHash = ContractService.computeTermsHash('Build flutter mobile app');

      final ix = await ProgramInstructions.createAndFund(
        employer: employer,
        worker: worker,
        contractId: contractId,
        amountLamports: BigInt.from(1000000000),
        termsHash: termsHash,
      );

      expect(ix.accounts.length, equals(4));
      expect(ix.accounts[0].pubKey, equals(employer));
      expect(ix.accounts[0].isSigner, isTrue);
      expect(ix.accounts[0].isWriteable, isTrue);
      // system_program is account 3
      expect(ix.accounts[3].pubKey, equals(ProgramInstructions.systemProgramId));

      // Verify discriminator matches createAndFundDiscriminator
      final dataBytes = ix.data.toList();
      expect(dataBytes.sublist(0, 8), equals(ProgramInstructions.createAndFundDiscriminator));
    });

    test('Builds valid acceptContract instruction', () async {
      final worker = Ed25519HDPublicKey.fromBase58('FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9');
      const contractId = 'ctr-123';

      final ix = await ProgramInstructions.acceptContract(
        worker: worker,
        contractId: contractId,
      );

      expect(ix.accounts.length, equals(2));
      expect(ix.accounts[0].pubKey, equals(worker));
      expect(ix.accounts[0].isSigner, isTrue);
      final dataBytes = ix.data.toList();
      expect(dataBytes.sublist(0, 8), equals(ProgramInstructions.acceptContractDiscriminator));
    });

    test('Builds valid releaseAndReview instruction', () async {
      final employer = Ed25519HDPublicKey.fromBase58('GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P');
      final worker = Ed25519HDPublicKey.fromBase58('FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9');
      const contractId = 'ctr-123';

      final ix = await ProgramInstructions.releaseAndReview(
        employer: employer,
        worker: worker,
        contractId: contractId,
        rating: 5,
      );

      expect(ix.accounts.length, equals(7));
      expect(ix.accounts[0].pubKey, equals(employer));
      expect(ix.accounts[0].isSigner, isTrue);
      expect(ix.accounts[3].pubKey, equals(worker));
      final dataBytes = ix.data.toList();
      expect(dataBytes.sublist(0, 8), equals(ProgramInstructions.releaseAndReviewDiscriminator));
      expect(dataBytes.last, equals(5)); // Rating u8
    });
  });

  group('ContractRepository Drift Local Database', () {
    late AppDatabase db;
    late ContractRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = ContractRepository(
        db: db,
        contractService: ContractService(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Saves and watches escrow contracts reactively from Drift', () async {
      const employer = 'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P';
      const worker = 'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9';
      const contractId = 'ctr-test-drift-1';

      // Insert directly into Drift table
      await db.into(db.escrowContracts).insert(
        EscrowContractsCompanion.insert(
          contractId: contractId,
          employer: employer,
          worker: worker,
          amount: BigInt.from(2000000000),
          termsHash: 'abcdef0123456789',
          termsText: const Value('Full stack website development'),
          status: ContractStatus.funded.name,
          deadline: BigInt.from(1750000000),
          createdAt: BigInt.from(1700000000),
          fundedAt: BigInt.from(1700000050),
          completedAt: BigInt.zero,
          rating: 0,
        ),
      );

      // Watch from Drift
      final contracts = await repository.watchContractsForWallet(employer).first;
      expect(contracts.length, equals(1));
      expect(contracts.first.contractId, equals(contractId));
      expect(contracts.first.amountUi, equals(2.0));
      expect(contracts.first.termsText, equals('Full stack website development'));
      expect(contracts.first.status, equals(ContractStatus.funded));

      // Worker should also see the contract
      final workerContracts = await repository.watchContractsForWallet(worker).first;
      expect(workerContracts.length, equals(1));
      expect(workerContracts.first.contractId, equals(contractId));
    });

    test('Saves, retrieves, updates, and deletes draft contracts in Drift', () async {
      const contractId = 'ctr-draft-123';
      const worker = 'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9';

      // 1. Save new draft
      final draftId = await repository.saveDraftContract(
        contractId: contractId,
        workerAddress: worker,
        amountSol: 1.25,
        termsText: 'Build mobile UI',
        deadline: BigInt.from(1750000000),
      );
      expect(draftId, isPositive);

      // 2. Retrieve drafts
      final drafts = await repository.getDraftContracts();
      expect(drafts.length, equals(1));
      expect(drafts.first.id, equals(draftId));
      expect(drafts.first.contractId, equals(contractId));
      expect(drafts.first.workerAddress, equals(worker));
      expect(drafts.first.amountSol, equals(1.25));
      expect(drafts.first.termsText, equals('Build mobile UI'));

      // 3. Update existing draft
      await repository.saveDraftContract(
        id: draftId,
        contractId: contractId,
        workerAddress: worker,
        amountSol: 2.5,
        termsText: 'Build mobile UI + backend',
        deadline: BigInt.from(1750000000),
      );

      final updatedDrafts = await repository.getDraftContracts();
      expect(updatedDrafts.length, equals(1));
      expect(updatedDrafts.first.amountSol, equals(2.5));
      expect(updatedDrafts.first.termsText, equals('Build mobile UI + backend'));

      // 4. Delete draft
      await repository.deleteDraftContract(draftId);
      final emptyDrafts = await repository.getDraftContracts();
      expect(emptyDrafts, isEmpty);
    });

    test(r'Saves, retrieves, and watches SPL token ($SKR) contracts and drafts in Drift', () async {
      const contractId = 'ctr-skr-drift-1';
      const employer = 'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P';
      const worker = 'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9';
      const skrMint = NetworkConfig.devnetSkrMint;

      // 1. Save draft with isToken = true
      final draftId = await repository.saveDraftContract(
        contractId: contractId,
        workerAddress: worker,
        amountSol: 500.0,
        termsText: r'Complete Solana Hackathon $SKR deliverables',
        deadline: BigInt.from(1750000000),
        isToken: true,
        tokenMint: skrMint,
      );
      expect(draftId, isPositive);

      final drafts = await repository.getDraftContracts();
      expect(drafts.length, equals(1));
      expect(drafts.first.isToken, isTrue);
      expect(drafts.first.tokenMint, equals(skrMint));

      // 2. Insert token escrow contract directly into Drift
      final now = DateTime.now().toUtc();
      final contract = EscrowContract(
        contractId: contractId,
        employer: employer,
        worker: worker,
        amount: BigInt.from(500 * 1000000), // 500 $SKR
        termsHash: 'abcdef0123456789',
        termsText: r'Complete Solana Hackathon $SKR deliverables',
        status: ContractStatus.funded,
        createdAt: now,
        isToken: true,
        tokenMint: skrMint,
      );

      expect(contract.isSkr, isTrue);
      expect(contract.currencySymbol, equals(r'$SKR'));
      expect(contract.formattedAmount, equals('500 \$SKR'));

      await db.into(db.escrowContracts).insert(
            EscrowContractsCompanion.insert(
              contractId: contract.contractId,
              employer: contract.employer,
              worker: contract.worker,
              amount: contract.amount,
              termsHash: contract.termsHash,
              termsText: Value(contract.termsText),
              status: contract.status.name,
              deadline: BigInt.zero,
              createdAt: BigInt.from(now.millisecondsSinceEpoch ~/ 1000),
              fundedAt: BigInt.from(now.millisecondsSinceEpoch ~/ 1000),
              completedAt: BigInt.zero,
              rating: 0,
              syncedAt: Value(now),
              isToken: Value(true),
              tokenMint: Value(skrMint),
            ),
          );

      final retrieved = await repository.getContract(contractId);
      expect(retrieved, isNotNull);
      expect(retrieved!.isToken, isTrue);
      expect(retrieved.isSkr, isTrue);
      expect(retrieved.isUsdc, isFalse);
      expect(retrieved.currency, equals(EscrowCurrency.skr));
      expect(retrieved.tokenMint, equals(skrMint));
      expect(retrieved.formattedAmount, equals('500 \$SKR'));
    });

    test('USDC escrow draft saving and Drift round-trip with 6 decimals', () async {
      const contractId = 'ctr-usdc-drift-test';
      final employer = 'EmployerTest11111111111111111111111111111111';
      final worker = 'WorkerTest111111111111111111111111111111111111';
      final usdcMint = NetworkConfig.devnetUsdcMint;

      // 1. Save draft with USDC token settings
      final draftId = await repository.saveDraftContract(
        contractId: contractId,
        workerAddress: worker,
        amountSol: 150.0,
        termsText: 'Deliver USDC audited deliverables',
        deadline: BigInt.from(1750000000),
        isToken: true,
        tokenMint: usdcMint,
      );
      expect(draftId, isPositive);

      final drafts = await repository.getDraftContracts();
      final usdcDraft = drafts.firstWhere((d) => d.contractId == contractId);
      expect(usdcDraft.isToken, isTrue);
      expect(usdcDraft.tokenMint, equals(usdcMint));

      // 2. Insert USDC contract into Drift
      final now = DateTime.now().toUtc();
      final contract = EscrowContract(
        contractId: contractId,
        employer: employer,
        worker: worker,
        amount: BigInt.from(150 * 1000000), // 150 USDC (6 decimals)
        termsHash: 'usdc1234567890abcdef',
        termsText: 'Deliver USDC audited deliverables',
        status: ContractStatus.funded,
        createdAt: now,
        isToken: true,
        tokenMint: usdcMint,
      );

      expect(contract.isToken, isTrue);
      expect(contract.isUsdc, isTrue);
      expect(contract.isSkr, isFalse);
      expect(contract.currency, equals(EscrowCurrency.usdc));
      expect(contract.currencySymbol, equals('USDC'));
      expect(contract.formattedAmount, equals('150 USDC'));

      await db.into(db.escrowContracts).insert(
            EscrowContractsCompanion.insert(
              contractId: contract.contractId,
              employer: contract.employer,
              worker: contract.worker,
              amount: contract.amount,
              termsHash: contract.termsHash,
              termsText: Value(contract.termsText),
              status: contract.status.name,
              deadline: BigInt.zero,
              createdAt: BigInt.from(now.millisecondsSinceEpoch ~/ 1000),
              fundedAt: BigInt.from(now.millisecondsSinceEpoch ~/ 1000),
              completedAt: BigInt.zero,
              rating: 0,
              syncedAt: Value(now),
              isToken: Value(true),
              tokenMint: Value(usdcMint),
            ),
          );

      final retrieved = await repository.getContract(contractId);
      expect(retrieved, isNotNull);
      expect(retrieved!.isToken, isTrue);
      expect(retrieved.isUsdc, isTrue);
      expect(retrieved.isSkr, isFalse);
      expect(retrieved.tokenMint, equals(usdcMint));
      expect(retrieved.formattedAmount, equals('150 USDC'));
    });
  });

  group(r'SPL Token ($SKR) ProgramInstructions & AccountDecoders', () {
    test('Derives Vault Token ATA deterministically', () async {
      const contractId = 'ctr-skr-pda-1';
      final mint = Ed25519HDPublicKey.fromBase58(NetworkConfig.devnetSkrMint);

      final vaultAta1 = await NetworkConfig.findVaultTokenAddress(
        contractId: contractId,
        mint: mint,
      );
      final vaultAta2 = await NetworkConfig.findVaultTokenAddress(
        contractId: contractId,
        mint: mint,
      );

      expect(vaultAta1.toBase58(), equals(vaultAta2.toBase58()));
      expect(vaultAta1.bytes.length, equals(32));
    });

    test('Decodes SPL token EscrowContract binary account data', () {
      final employerKey = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );
      final workerKey = Ed25519HDPublicKey.fromBase58(
        'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9',
      );
      final mintKey = Ed25519HDPublicKey.fromBase58(NetworkConfig.devnetSkrMint);
      const contractId = 'ctr-skr-binary-1';
      final contractIdBytes = utf8.encode(contractId);
      final termsHash = List<int>.generate(32, (i) => i);

      // Total length: 8 + 4 + idLen + 32 + 32 + 8 + 32 + 1 + 8 + 8 + 8 + 8 + 1 + 1 + 1 + 1 (is_token) + 32 (token_mint)
      final totalLen = 8 + 4 + contractIdBytes.length + 32 + 32 + 8 + 32 + 1 + 8 + 8 + 8 + 8 + 1 + 1 + 1 + 1 + 32;
      final buffer = Uint8List(totalLen);
      final byteData = ByteData.sublistView(buffer);

      // Discriminator
      buffer.setRange(0, 8, AccountDecoders.escrowContractDiscriminator);
      int offset = 8;

      // contract_id
      byteData.setUint32(offset, contractIdBytes.length, Endian.little);
      offset += 4;
      buffer.setRange(offset, offset + contractIdBytes.length, contractIdBytes);
      offset += contractIdBytes.length;

      // employer
      buffer.setRange(offset, offset + 32, employerKey.bytes);
      offset += 32;

      // worker
      buffer.setRange(offset, offset + 32, workerKey.bytes);
      offset += 32;

      // amount = 500 $SKR (500_000_000 base units)
      byteData.setUint64(offset, 500000000, Endian.little);
      offset += 8;

      // terms_hash
      buffer.setRange(offset, offset + 32, termsHash);
      offset += 32;

      // status = 1 (funded)
      buffer[offset] = 1;
      offset += 1;

      // deadline = 1750000000
      byteData.setInt64(offset, 1750000000, Endian.little);
      offset += 8;

      // created_at = 1700000000
      byteData.setInt64(offset, 1700000000, Endian.little);
      offset += 8;

      // funded_at = 1700000100
      byteData.setInt64(offset, 1700000100, Endian.little);
      offset += 8;

      // completed_at = 0
      byteData.setInt64(offset, 0, Endian.little);
      offset += 8;

      // rating = 0
      buffer[offset] = 0;
      offset += 1;

      // bump
      buffer[offset] = 255;
      offset += 1;

      // vault_bump
      buffer[offset] = 254;
      offset += 1;

      // is_token = true (1)
      buffer[offset] = 1;
      offset += 1;

      // token_mint
      buffer.setRange(offset, offset + 32, mintKey.bytes);
      offset += 32;

      final contract = AccountDecoders.decodeEscrowContract(buffer);

      expect(contract.contractId, equals(contractId));
      expect(contract.isToken, isTrue);
      expect(contract.isSkr, isTrue);
      expect(contract.tokenMint, equals(mintKey.toBase58()));
      expect(contract.amount, equals(BigInt.from(500000000)));
      expect(contract.formattedAmount, equals('500 \$SKR'));
    });

    test('ProgramInstructions builds valid createAndFundToken instruction', () async {
      final employerKey = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );
      final workerKey = Ed25519HDPublicKey.fromBase58(
        'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9',
      );
      final mintKey = Ed25519HDPublicKey.fromBase58(NetworkConfig.devnetSkrMint);
      const contractId = 'ctr-skr-ins-1';
      final termsHash = List<int>.filled(32, 7);

      final instruction = await ProgramInstructions.createAndFundToken(
        employer: employerKey,
        worker: workerKey,
        contractId: contractId,
        amountTokenBaseUnits: BigInt.from(500000000),
        termsHash: termsHash,
        mint: mintKey,
      );

      expect(instruction.programId, equals(NetworkConfig.programId));
      expect(instruction.accounts.length, equals(9));
      expect(instruction.accounts[0].pubKey, equals(employerKey));
      expect(instruction.accounts[0].isSigner, isTrue);
      expect(instruction.accounts[1].pubKey, equals(mintKey));
      expect(instruction.accounts[6].pubKey, equals(NetworkConfig.tokenProgramId));
      expect(instruction.accounts[7].pubKey, equals(NetworkConfig.associatedTokenProgramId));

      final dataList = instruction.data.toList();
      expect(
        dataList.sublist(0, 8),
        equals(ProgramInstructions.createAndFundTokenDiscriminator),
      );
    });

    test('ProgramInstructions builds valid releaseAndReviewToken instruction', () async {
      final employerKey = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );
      final workerKey = Ed25519HDPublicKey.fromBase58(
        'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9',
      );
      final mintKey = Ed25519HDPublicKey.fromBase58(NetworkConfig.devnetSkrMint);
      const contractId = 'ctr-skr-rel-1';

      final instruction = await ProgramInstructions.releaseAndReviewToken(
        employer: employerKey,
        worker: workerKey,
        contractId: contractId,
        rating: 5,
        mint: mintKey,
      );

      expect(instruction.programId, equals(NetworkConfig.programId));
      expect(instruction.accounts.length, equals(11));
      expect(instruction.accounts[0].pubKey, equals(employerKey));
      expect(instruction.accounts[0].isSigner, isTrue);
      expect(instruction.accounts[2].pubKey, equals(mintKey));
      expect(instruction.accounts[9].pubKey, equals(NetworkConfig.tokenProgramId));

      final dataList = instruction.data.toList();
      expect(
        dataList.sublist(0, 8),
        equals(ProgramInstructions.releaseAndReviewTokenDiscriminator),
      );
    });

    test('ProgramInstructions builds valid cancelTokenContract instruction', () async {
      final employerKey = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );
      final mintKey = Ed25519HDPublicKey.fromBase58(NetworkConfig.devnetSkrMint);
      const contractId = 'ctr-skr-cancel-1';

      final instruction = await ProgramInstructions.cancelTokenContract(
        employer: employerKey,
        contractId: contractId,
        mint: mintKey,
      );

      expect(instruction.programId, equals(NetworkConfig.programId));
      expect(instruction.accounts.length, equals(7));
      expect(instruction.accounts[0].pubKey, equals(employerKey));
      expect(instruction.accounts[0].isSigner, isTrue);
      expect(instruction.accounts[2].pubKey, equals(mintKey));

      final dataList = instruction.data.toList();
      expect(
        dataList.sublist(0, 8),
        equals(ProgramInstructions.cancelTokenContractDiscriminator),
      );
    });

    test('Decodes USDC token EscrowContract binary account data with 6 decimals', () {
      final employerKey = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );
      final workerKey = Ed25519HDPublicKey.fromBase58(
        'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9',
      );
      final usdcMintKey = Ed25519HDPublicKey.fromBase58(NetworkConfig.devnetUsdcMint);
      const contractId = 'ctr-usdc-decode-1';

      final buffer = Uint8List(220);
      final byteData = ByteData.sublistView(buffer);

      // Discriminator (8 bytes)
      buffer.setRange(0, 8, AccountDecoders.escrowContractDiscriminator);
      var offset = 8;

      // contract_id: string
      final idBytes = utf8.encode(contractId);
      byteData.setUint32(offset, idBytes.length, Endian.little);
      offset += 4;
      buffer.setRange(offset, offset + idBytes.length, idBytes);
      offset += idBytes.length;

      // employer (32 bytes)
      buffer.setRange(offset, offset + 32, employerKey.bytes);
      offset += 32;

      // worker (32 bytes)
      buffer.setRange(offset, offset + 32, workerKey.bytes);
      offset += 32;

      // amount: 250 USDC = 250,000,000 micro-USDC (6 decimals)
      byteData.setUint64(offset, 250000000, Endian.little);
      offset += 8;

      // terms_hash: [u8; 32]
      offset += 32;

      // status: 1 (funded)
      buffer[offset] = 1;
      offset += 1;

      // deadline: i64 (8 bytes)
      byteData.setInt64(offset, 1750000000, Endian.little);
      offset += 8;

      // created_at: i64 (8 bytes)
      byteData.setInt64(offset, 1710000000, Endian.little);
      offset += 8;

      // funded_at: i64 (8 bytes)
      byteData.setInt64(offset, 1710000010, Endian.little);
      offset += 8;

      // completed_at: i64 (8 bytes)
      byteData.setInt64(offset, 0, Endian.little);
      offset += 8;

      // rating: u8 (1 byte)
      buffer[offset] = 0;
      offset += 1;

      // bump
      buffer[offset] = 255;
      offset += 1;

      // vault_bump
      buffer[offset] = 254;
      offset += 1;

      // is_token = true (1)
      buffer[offset] = 1;
      offset += 1;

      // token_mint (USDC mint)
      buffer.setRange(offset, offset + 32, usdcMintKey.bytes);
      offset += 32;

      final contract = AccountDecoders.decodeEscrowContract(buffer);

      expect(contract.contractId, equals(contractId));
      expect(contract.isToken, isTrue);
      expect(contract.isUsdc, isTrue);
      expect(contract.isSkr, isFalse);
      expect(contract.currency, equals(EscrowCurrency.usdc));
      expect(contract.tokenMint, equals(usdcMintKey.toBase58()));
      expect(contract.amount, equals(BigInt.from(250000000)));
      expect(contract.formattedAmount, equals('250 USDC'));
    });

    test('ProgramInstructions builds valid createAndFundToken instruction for USDC', () async {
      final employerKey = Ed25519HDPublicKey.fromBase58(
        'GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P',
      );
      final workerKey = Ed25519HDPublicKey.fromBase58(
        'FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9',
      );
      final usdcMintKey = NetworkConfig.usdcMint;
      const contractId = 'ctr-usdc-ins-1';
      final termsHash = List<int>.filled(32, 9);

      final instruction = await ProgramInstructions.createAndFundToken(
        employer: employerKey,
        worker: workerKey,
        contractId: contractId,
        amountTokenBaseUnits: BigInt.from(250000000), // 250 USDC
        termsHash: termsHash,
        mint: usdcMintKey,
      );

      expect(instruction.programId, equals(NetworkConfig.programId));
      expect(instruction.accounts.length, equals(9));
      expect(instruction.accounts[0].pubKey, equals(employerKey));
      expect(instruction.accounts[1].pubKey, equals(usdcMintKey));
    });
  });
}
