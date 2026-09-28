import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey, Keypair, SystemProgram, LAMPORTS_PER_SOL } from "@solana/web3.js";
import {
  createMint,
  createAssociatedTokenAccount,
  mintTo,
  getAccount,
  getAssociatedTokenAddressSync,
  TOKEN_PROGRAM_ID,
  ASSOCIATED_TOKEN_PROGRAM_ID,
} from "@solana/spl-token";
import { expect } from "chai";
import crypto from "crypto";
import { Reputation } from "../target/types/reputation";

describe("SPL token ($SKR) escrow protocol", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.Reputation as Program<Reputation>;

  const employer = Keypair.generate();
  const worker = Keypair.generate();
  const stranger = Keypair.generate();

  let mockSkrMint: PublicKey;
  let otherTokenMint: PublicKey;
  let employerSkrAta: PublicKey;
  let workerSkrAta: PublicKey;

  // PDA helper utilities
  const findWorkerProfilePda = (workerPubkey: PublicKey): [PublicKey, number] => {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("worker"), workerPubkey.toBuffer()],
      program.programId
    );
  };

  const findReviewPda = (workerPubkey: PublicKey, jobId: string): [PublicKey, number] => {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("review"), workerPubkey.toBuffer(), Buffer.from(jobId)],
      program.programId
    );
  };

  const findEscrowPda = (contractId: string): [PublicKey, number] => {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("escrow"), Buffer.from(contractId)],
      program.programId
    );
  };

  const findVaultPda = (contractId: string): [PublicKey, number] => {
    return PublicKey.findProgramAddressSync(
      [Buffer.from("vault"), Buffer.from(contractId)],
      program.programId
    );
  };

  const getVaultTokenAddress = (contractId: string, mint: PublicKey): PublicKey => {
    const [vaultPda] = findVaultPda(contractId);
    return getAssociatedTokenAddressSync(mint, vaultPda, true);
  };

  const computeTermsHash = (terms: string): number[] => {
    const hash = crypto.createHash("sha256").update(terms).digest();
    return Array.from(hash);
  };

  before(async () => {
    // 1. Fund test keypairs with native SOL for fees & rent
    const tx = new anchor.web3.Transaction().add(
      SystemProgram.transfer({
        fromPubkey: provider.wallet.publicKey,
        toPubkey: employer.publicKey,
        lamports: 10 * LAMPORTS_PER_SOL,
      }),
      SystemProgram.transfer({
        fromPubkey: provider.wallet.publicKey,
        toPubkey: worker.publicKey,
        lamports: 5 * LAMPORTS_PER_SOL,
      }),
      SystemProgram.transfer({
        fromPubkey: provider.wallet.publicKey,
        toPubkey: stranger.publicKey,
        lamports: 2 * LAMPORTS_PER_SOL,
      })
    );
    await provider.sendAndConfirm(tx);

    // 2. Register worker profile
    const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);
    await program.methods
      .registerWorker()
      .accounts({
        worker: worker.publicKey,
      })
      .signers([worker])
      .rpc();

    // 3. Create mock $SKR mint and a separate token mint for guardrail tests
    mockSkrMint = await createMint(
      provider.connection,
      (provider.wallet as any).payer,
      provider.wallet.publicKey,
      null,
      6 // 6 decimal places like standard SPL tokens
    );

    otherTokenMint = await createMint(
      provider.connection,
      (provider.wallet as any).payer,
      provider.wallet.publicKey,
      null,
      6
    );

    // 4. Create ATAs for employer and worker
    employerSkrAta = await createAssociatedTokenAccount(
      provider.connection,
      (provider.wallet as any).payer,
      mockSkrMint,
      employer.publicKey
    );

    workerSkrAta = await createAssociatedTokenAccount(
      provider.connection,
      (provider.wallet as any).payer,
      mockSkrMint,
      worker.publicKey
    );

    // 5. Mint 5,000 $SKR tokens (base units = 5,000 * 10^6) to employer
    await mintTo(
      provider.connection,
      (provider.wallet as any).payer,
      mockSkrMint,
      employerSkrAta,
      provider.wallet.publicKey,
      5000 * 1_000_000
    );
  });

  describe("Lifecycle: Full $SKR Token Settlement (create_and_fund_token -> accept -> release_and_review_token)", () => {
    const contractId = "skr_contract_full_001";
    const depositAmount = new anchor.BN(500 * 1_000_000); // 500 $SKR
    const terms = "Audit Solana Anchor smart contract and verify SPL token vaults";
    const termsHash = computeTermsHash(terms);
    const deadline = new anchor.BN(0);

    const [escrowPda] = findEscrowPda(contractId);
    const [vaultPda] = findVaultPda(contractId);

    it("creates and funds an SPL token ($SKR) escrow contract in one transaction", async () => {
      const vaultTokenAccount = getVaultTokenAddress(contractId, mockSkrMint);
      const employerBalBefore = (await getAccount(provider.connection, employerSkrAta)).amount;

      await program.methods
        .createAndFundToken(contractId, worker.publicKey, depositAmount, termsHash, deadline)
        .accounts({
          employer: employer.publicKey,
          mint: mockSkrMint,
          employerTokenAccount: employerSkrAta,
          tokenProgram: TOKEN_PROGRAM_ID,
          associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
        })
        .signers([employer])
        .rpc();

      // Assert on-chain EscrowContract state
      const contract = await program.account.escrowContract.fetch(escrowPda);
      expect(contract.contractId).to.equal(contractId);
      expect(contract.employer.toBase58()).to.equal(employer.publicKey.toBase58());
      expect(contract.worker.toBase58()).to.equal(worker.publicKey.toBase58());
      expect(contract.amount.toString()).to.equal(depositAmount.toString());
      expect(contract.isToken).to.be.true;
      expect(contract.tokenMint.toBase58()).to.equal(mockSkrMint.toBase58());
      expect(contract.status).to.deep.equal({ funded: {} });

      // Verify Vault ATA holds the exact 500 $SKR tokens
      const vaultAtaAccount = await getAccount(provider.connection, vaultTokenAccount);
      expect(vaultAtaAccount.amount.toString()).to.equal(depositAmount.toString());

      // Verify employer balance was deducted
      const employerBalAfter = (await getAccount(provider.connection, employerSkrAta)).amount;
      expect(employerBalBefore - employerBalAfter).to.equal(BigInt(depositAmount.toString()));
    });

    it("worker accepts the $SKR token contract terms (transitions to InProgress)", async () => {
      await program.methods
        .acceptContract(contractId)
        .accounts({
          worker: worker.publicKey,
        })
        .signers([worker])
        .rpc();

      const contract = await program.account.escrowContract.fetch(escrowPda);
      expect(contract.status).to.deep.equal({ inProgress: {} });
    });

    it("atomically releases $SKR payment to worker and writes verified review", async () => {
      const vaultTokenAccount = getVaultTokenAddress(contractId, mockSkrMint);
      const workerBalBefore = (await getAccount(provider.connection, workerSkrAta)).amount;
      const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);
      const [reviewPda] = findReviewPda(worker.publicKey, contractId);

      const rating = 5;
      await program.methods
        .releaseAndReviewToken(contractId, rating)
        .accounts({
          employer: employer.publicKey,
          mint: mockSkrMint,
          worker: worker.publicKey,
          workerTokenAccount: workerSkrAta,
          tokenProgram: TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
        })
        .signers([employer])
        .rpc();

      // 1. Worker's ATA received the 500 $SKR
      const workerBalAfter = (await getAccount(provider.connection, workerSkrAta)).amount;
      expect(workerBalAfter - workerBalBefore).to.equal(BigInt(depositAmount.toString()));

      // 2. Vault ATA is closed
      const vaultAtaInfo = await provider.connection.getAccountInfo(vaultTokenAccount);
      expect(vaultAtaInfo).to.be.null;

      // 3. Review PDA was minted atomically
      const review = await program.account.review.fetch(reviewPda);
      expect(review.worker.toBase58()).to.equal(worker.publicKey.toBase58());
      expect(review.reviewer.toBase58()).to.equal(employer.publicKey.toBase58());
      expect(review.jobId).to.equal(contractId);
      expect(review.rating).to.equal(rating);

      // 4. WorkerProfile aggregates updated
      const profile = await program.account.workerProfile.fetch(workerProfilePda);
      expect(profile.totalJobs).to.be.greaterThanOrEqual(1);

      // 5. Contract marked Completed
      const contract = await program.account.escrowContract.fetch(escrowPda);
      expect(contract.status).to.deep.equal({ completed: {} });
      expect(contract.rating).to.equal(rating);
    });
  });

  describe("Lifecycle: $SKR Token Cancellation & Refund (create_and_fund_token -> cancel_token_contract)", () => {
    const contractId = "skr_contract_cancel_002";
    const depositAmount = new anchor.BN(200 * 1_000_000); // 200 $SKR
    const terms = "Temporary $SKR contract to test cancellation";
    const termsHash = computeTermsHash(terms);
    const deadline = new anchor.BN(0);

    const [escrowPda] = findEscrowPda(contractId);
    const [vaultPda] = findVaultPda(contractId);

    it("employer cancels funded token contract and reclaims 100% of $SKR tokens", async () => {
      const vaultTokenAccount = getVaultTokenAddress(contractId, mockSkrMint);
      // 1. Create and fund token contract
      await program.methods
        .createAndFundToken(contractId, worker.publicKey, depositAmount, termsHash, deadline)
        .accounts({
          employer: employer.publicKey,
          mint: mockSkrMint,
          employerTokenAccount: employerSkrAta,
          tokenProgram: TOKEN_PROGRAM_ID,
          associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
        })
        .signers([employer])
        .rpc();

      const employerBalBeforeCancel = (await getAccount(provider.connection, employerSkrAta)).amount;

      // 2. Cancel token contract
      await program.methods
        .cancelTokenContract(contractId)
        .accounts({
          employer: employer.publicKey,
          mint: mockSkrMint,
          employerTokenAccount: employerSkrAta,
          tokenProgram: TOKEN_PROGRAM_ID,
        })
        .signers([employer])
        .rpc();

      // 3. Verify employer received full 200 $SKR back
      const employerBalAfterCancel = (await getAccount(provider.connection, employerSkrAta)).amount;
      expect(employerBalAfterCancel - employerBalBeforeCancel).to.equal(BigInt(depositAmount.toString()));

      // 4. Verify Vault ATA is closed
      const vaultAtaInfo = await provider.connection.getAccountInfo(vaultTokenAccount);
      expect(vaultAtaInfo).to.be.null;

      // 5. Contract status is Cancelled
      const contract = await program.account.escrowContract.fetch(escrowPda);
      expect(contract.status).to.deep.equal({ cancelled: {} });
    });
  });

  describe("Security & Cross-Protocol Guardrails", () => {
    it("rejects calling native SOL release_and_review on an SPL token contract", async () => {
      const contractId = "skr_cross_guard_003";
      const depositAmount = new anchor.BN(100 * 1_000_000);
      const termsHash = computeTermsHash("cross protocol guardrail test");

      await program.methods
        .createAndFundToken(contractId, worker.publicKey, depositAmount, termsHash, new anchor.BN(0))
        .accounts({
          employer: employer.publicKey,
          mint: mockSkrMint,
          employerTokenAccount: employerSkrAta,
          tokenProgram: TOKEN_PROGRAM_ID,
          associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
        })
        .signers([employer])
        .rpc();

      await program.methods
        .acceptContract(contractId)
        .accounts({ worker: worker.publicKey })
        .signers([worker])
        .rpc();

      // Try calling native SOL release_and_review
      try {
        await program.methods
          .releaseAndReview(contractId, 5)
          .accounts({
            employer: employer.publicKey,
            worker: worker.publicKey,
          })
          .signers([employer])
          .rpc();
        expect.fail("Should have failed with TokenContract error");
      } catch (err: any) {
        expect(err.error?.errorCode?.code).to.equal("TokenContract");
      }
    });

    it("rejects token release with a mismatched mint", async () => {
      const contractId = "skr_mint_guard_004";
      const depositAmount = new anchor.BN(50 * 1_000_000);
      const termsHash = computeTermsHash("mint mismatch test");

      await program.methods
        .createAndFundToken(contractId, worker.publicKey, depositAmount, termsHash, new anchor.BN(0))
        .accounts({
          employer: employer.publicKey,
          mint: mockSkrMint,
          employerTokenAccount: employerSkrAta,
          tokenProgram: TOKEN_PROGRAM_ID,
          associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
        })
        .signers([employer])
        .rpc();

      await program.methods
        .acceptContract(contractId)
        .accounts({ worker: worker.publicKey })
        .signers([worker])
        .rpc();

      // Attempt release with otherTokenMint
      try {
        await program.methods
          .releaseAndReviewToken(contractId, 5)
          .accounts({
            employer: employer.publicKey,
            mint: otherTokenMint, // Wrong mint!
            worker: worker.publicKey,
            workerTokenAccount: workerSkrAta,
            tokenProgram: TOKEN_PROGRAM_ID,
            systemProgram: SystemProgram.programId,
          })
          .signers([employer])
          .rpc();
        expect.fail("Should have rejected mint mismatch");
      } catch (err: any) {
        expect(err.toString()).to.satisfy(
          (msg: string) =>
            msg.includes("MintMismatch") ||
            msg.includes("vault_token_account") ||
            msg.includes("ConstraintAssociatedToken")
        );
      }
    });
  });
});
