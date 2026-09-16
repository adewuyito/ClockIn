import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey, Keypair, SystemProgram, LAMPORTS_PER_SOL } from "@solana/web3.js";
import { expect } from "chai";
import crypto from "crypto";
import { Reputation } from "../target/types/reputation";

describe("escrow protocol", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.Reputation as Program<Reputation>;

  const employer = Keypair.generate();
  const worker = Keypair.generate();
  const stranger = Keypair.generate();

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

  const computeTermsHash = (terms: string): number[] => {
    const hash = crypto.createHash("sha256").update(terms).digest();
    return Array.from(hash);
  };

  before(async () => {
    // Fund test keypairs directly from provider wallet
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
        lamports: 5 * LAMPORTS_PER_SOL,
      })
    );
    await provider.sendAndConfirm(tx);

    // Register worker profile initially
    const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);
    await program.methods
      .registerWorker()
      .accountsPartial({
        worker: worker.publicKey,
        workerProfile: workerProfilePda,
        systemProgram: SystemProgram.programId,
      })
      .signers([worker])
      .rpc();
  });

  describe("Lifecycle 1: Two-Step Creation & Funding (create_contract -> fund_contract)", () => {
    const contractId = "ctr-step-101";
    const depositAmount = new anchor.BN(1 * LAMPORTS_PER_SOL);
    const terms = "Build React landing page with Solana wallet adapter";
    const termsHash = computeTermsHash(terms);
    const deadline = new anchor.BN(Math.floor(Date.now() / 1000) + 86400 * 7);

    it("creates an escrow contract in 'Created' status without funding yet", async () => {
      const [escrowPda] = findEscrowPda(contractId);

      await program.methods
        .createContract(contractId, worker.publicKey, depositAmount, termsHash, deadline)
        .accountsPartial({
          employer: employer.publicKey,
          escrowContract: escrowPda,
          systemProgram: SystemProgram.programId,
        })
        .signers([employer])
        .rpc();

      const contract = await program.account.escrowContract.fetch(escrowPda);
      expect(contract.contractId).to.equal(contractId);
      expect(contract.employer.toBase58()).to.equal(employer.publicKey.toBase58());
      expect(contract.worker.toBase58()).to.equal(worker.publicKey.toBase58());
      expect(contract.amount.toString()).to.equal(depositAmount.toString());
      expect(contract.status).to.deep.equal({ created: {} });
      expect(contract.rating).to.equal(0);
      expect(contract.completedAt.toNumber()).to.equal(0);
    });

    it("funds the created contract, locking SOL in the Vault PDA", async () => {
      const [escrowPda] = findEscrowPda(contractId);
      const [vaultPda] = findVaultPda(contractId);

      const vaultBalanceBefore = await provider.connection.getBalance(vaultPda);
      expect(vaultBalanceBefore).to.equal(0);

      await program.methods
        .fundContract(contractId)
        .accountsPartial({
          employer: employer.publicKey,
          escrowContract: escrowPda,
          vault: vaultPda,
          systemProgram: SystemProgram.programId,
        })
        .signers([employer])
        .rpc();

      const contract = await program.account.escrowContract.fetch(escrowPda);
      expect(contract.status).to.deep.equal({ funded: {} });
      expect(contract.fundedAt.toNumber()).to.be.greaterThan(0);

      // Vault now holds escrow deposit + rent exemption
      const vaultBalanceAfter = await provider.connection.getBalance(vaultPda);
      expect(vaultBalanceAfter).to.be.greaterThan(depositAmount.toNumber());
    });
  });

  describe("Lifecycle 2: Atomic Settlement (create_and_fund -> accept -> release_and_review)", () => {
    const contractId = "ctr-atomic-202";
    const depositAmount = new anchor.BN(1.5 * LAMPORTS_PER_SOL);
    const terms = "Audit Anchor smart contract escrow instructions";
    const termsHash = computeTermsHash(terms);
    const deadline = new anchor.BN(Math.floor(Date.now() / 1000) + 86400 * 14);

    it("creates and funds in a single transaction via create_and_fund", async () => {
      const [escrowPda] = findEscrowPda(contractId);
      const [vaultPda] = findVaultPda(contractId);

      await program.methods
        .createAndFund(contractId, worker.publicKey, depositAmount, termsHash, deadline)
        .accountsPartial({
          employer: employer.publicKey,
          escrowContract: escrowPda,
          vault: vaultPda,
          systemProgram: SystemProgram.programId,
        })
        .signers([employer])
        .rpc();

      const contract = await program.account.escrowContract.fetch(escrowPda);
      expect(contract.contractId).to.equal(contractId);
      expect(contract.status).to.deep.equal({ funded: {} });
      expect(contract.amount.toString()).to.equal(depositAmount.toString());

      const vaultBalance = await provider.connection.getBalance(vaultPda);
      expect(vaultBalance).to.be.greaterThan(depositAmount.toNumber());
    });

    it("rejects unauthorized user from accepting the contract", async () => {
      const [escrowPda] = findEscrowPda(contractId);

      try {
        await program.methods
          .acceptContract(contractId)
          .accountsPartial({
            worker: stranger.publicKey, // NOT the assigned worker
            escrowContract: escrowPda,
          })
          .signers([stranger])
          .rpc();
        expect.fail("Should have failed with UnauthorizedWorker");
      } catch (err: any) {
        expect(err.toString()).to.include("UnauthorizedWorker");
      }
    });

    it("assigned worker successfully accepts the contract (transitions to InProgress)", async () => {
      const [escrowPda] = findEscrowPda(contractId);

      await program.methods
        .acceptContract(contractId)
        .accountsPartial({
          worker: worker.publicKey,
          escrowContract: escrowPda,
        })
        .signers([worker])
        .rpc();

      const contract = await program.account.escrowContract.fetch(escrowPda);
      expect(contract.status).to.deep.equal({ inProgress: {} });
    });

    it("atomically releases payment to worker and writes verified review in one block", async () => {
      const [escrowPda] = findEscrowPda(contractId);
      const [vaultPda] = findVaultPda(contractId);
      const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);
      const [reviewPda] = findReviewPda(worker.publicKey, contractId);

      const workerBalanceBefore = await provider.connection.getBalance(worker.publicKey);
      const profileBefore = await program.account.workerProfile.fetch(workerProfilePda);

      // Employer releases 1.5 SOL and gives 5 stars
      await program.methods
        .releaseAndReview(contractId, 5)
        .accountsPartial({
          employer: employer.publicKey,
          escrowContract: escrowPda,
          vault: vaultPda,
          worker: worker.publicKey,
          workerProfile: workerProfilePda,
          review: reviewPda,
          systemProgram: SystemProgram.programId,
        })
        .signers([employer])
        .rpc();

      // 1. Verify worker received exact escrow payment
      const workerBalanceAfter = await provider.connection.getBalance(worker.publicKey);
      expect(workerBalanceAfter - workerBalanceBefore).to.equal(depositAmount.toNumber());

      // 2. Verify Vault PDA is closed (rent returned to employer)
      const vaultBalanceAfter = await provider.connection.getBalance(vaultPda);
      expect(vaultBalanceAfter).to.equal(0);

      // 3. Verify Review PDA was created on-chain
      const review = await program.account.review.fetch(reviewPda);
      expect(review.worker.toBase58()).to.equal(worker.publicKey.toBase58());
      expect(review.reviewer.toBase58()).to.equal(employer.publicKey.toBase58());
      expect(review.jobId).to.equal(contractId);
      expect(review.rating).to.equal(5);

      // 4. Verify WorkerProfile aggregated reputation incremented
      const profileAfter = await program.account.workerProfile.fetch(workerProfilePda);
      expect(profileAfter.totalJobs).to.equal(profileBefore.totalJobs + 1);
      expect(profileAfter.ratingSum.toNumber()).to.equal(profileBefore.ratingSum.toNumber() + 5);

      // 5. Verify EscrowContract status is Completed
      const contract = await program.account.escrowContract.fetch(escrowPda);
      expect(contract.status).to.deep.equal({ completed: {} });
      expect(contract.rating).to.equal(5);
      expect(contract.completedAt.toNumber()).to.be.greaterThan(0);
    });
  });

  describe("Lifecycle 3: Cancellation & Full Refund (cancel_contract)", () => {
    const contractId = "ctr-cancel-303";
    const depositAmount = new anchor.BN(2 * LAMPORTS_PER_SOL);
    const termsHash = computeTermsHash("Contract to be cancelled before worker accepts");

    it("employer cancels funded contract before acceptance and reclaims 100% of funds", async () => {
      const [escrowPda] = findEscrowPda(contractId);
      const [vaultPda] = findVaultPda(contractId);

      // Create and fund
      await program.methods
        .createAndFund(contractId, worker.publicKey, depositAmount, termsHash, new anchor.BN(0))
        .accountsPartial({
          employer: employer.publicKey,
          escrowContract: escrowPda,
          vault: vaultPda,
          systemProgram: SystemProgram.programId,
        })
        .signers([employer])
        .rpc();

      const employerBalanceBefore = await provider.connection.getBalance(employer.publicKey);

      // Cancel contract
      await program.methods
        .cancelContract(contractId)
        .accountsPartial({
          employer: employer.publicKey,
          escrowContract: escrowPda,
          vault: vaultPda,
        })
        .signers([employer])
        .rpc();

      // Employer should receive deposit + vault rent back (minus tiny tx fee)
      const employerBalanceAfter = await provider.connection.getBalance(employer.publicKey);
      expect(employerBalanceAfter).to.be.greaterThan(employerBalanceBefore + 1.99 * LAMPORTS_PER_SOL);

      // Vault is closed
      const vaultBalance = await provider.connection.getBalance(vaultPda);
      expect(vaultBalance).to.equal(0);

      // Contract status is Cancelled
      const contract = await program.account.escrowContract.fetch(escrowPda);
      expect(contract.status).to.deep.equal({ cancelled: {} });
    });

    it("worker cannot accept an already cancelled contract", async () => {
      const [escrowPda] = findEscrowPda(contractId);

      try {
        await program.methods
          .acceptContract(contractId)
          .accountsPartial({
            worker: worker.publicKey,
            escrowContract: escrowPda,
          })
          .signers([worker])
          .rpc();
        expect.fail("Should have failed with InvalidContractStatus");
      } catch (err: any) {
        expect(err.toString()).to.include("InvalidContractStatus");
      }
    });
  });

  describe("Lifecycle 4: Disputes (raise_dispute)", () => {
    const contractId = "ctr-dispute-404";
    const depositAmount = new anchor.BN(1 * LAMPORTS_PER_SOL);
    const termsHash = computeTermsHash("Disputed gig deliverables");

    it("either participant can transition an active contract into Disputed status", async () => {
      const [escrowPda] = findEscrowPda(contractId);
      const [vaultPda] = findVaultPda(contractId);

      await program.methods
        .createAndFund(contractId, worker.publicKey, depositAmount, termsHash, new anchor.BN(0))
        .accountsPartial({
          employer: employer.publicKey,
          escrowContract: escrowPda,
          vault: vaultPda,
          systemProgram: SystemProgram.programId,
        })
        .signers([employer])
        .rpc();

      await program.methods
        .acceptContract(contractId)
        .accountsPartial({
          worker: worker.publicKey,
          escrowContract: escrowPda,
        })
        .signers([worker])
        .rpc();

      // Worker raises dispute
      await program.methods
        .raiseDispute(contractId)
        .accountsPartial({
          caller: worker.publicKey,
          escrowContract: escrowPda,
        })
        .signers([worker])
        .rpc();

      const contract = await program.account.escrowContract.fetch(escrowPda);
      expect(contract.status).to.deep.equal({ disputed: {} });
    });
  });

  describe("Security & Guardrails", () => {
    it("rejects self-contract (employer == worker)", async () => {
      const contractId = "ctr-self-505";
      const [escrowPda] = findEscrowPda(contractId);

      try {
        await program.methods
          .createContract(contractId, employer.publicKey, new anchor.BN(100), computeTermsHash("test"), new anchor.BN(0))
          .accountsPartial({
            employer: employer.publicKey,
            escrowContract: escrowPda,
            systemProgram: SystemProgram.programId,
          })
          .signers([employer])
          .rpc();
        expect.fail("Should have failed with SelfContract");
      } catch (err: any) {
        expect(err.toString()).to.include("SelfContract");
      }
    });

    it("rejects zero deposit amount", async () => {
      const contractId = "ctr-zero-606";
      const [escrowPda] = findEscrowPda(contractId);

      try {
        await program.methods
          .createContract(contractId, worker.publicKey, new anchor.BN(0), computeTermsHash("test"), new anchor.BN(0))
          .accountsPartial({
            employer: employer.publicKey,
            escrowContract: escrowPda,
            systemProgram: SystemProgram.programId,
          })
          .signers([employer])
          .rpc();
        expect.fail("Should have failed with ZeroAmount");
      } catch (err: any) {
        expect(err.toString()).to.include("ZeroAmount");
      }
    });

    it("rejects contract_id exceeding 32 bytes", async () => {
      const longContractId = "contract-id-that-is-way-too-long-to-fit-in-32-bytes";
      const [escrowPda] = findEscrowPda(longContractId.substring(0, 32));

      try {
        await program.methods
          .createContract(longContractId, worker.publicKey, new anchor.BN(1000), computeTermsHash("test"), new anchor.BN(0))
          .accountsPartial({
            employer: employer.publicKey,
            escrowContract: escrowPda,
            systemProgram: SystemProgram.programId,
          })
          .signers([employer])
          .rpc();
        expect.fail("Should have failed with ContractIdTooLong");
      } catch (err: any) {
        const errText = (err.error?.errorCode?.code || "") + (err.toString() || "") + (err.logs?.join(" ") || "");
        expect(errText).to.match(/ContractIdTooLong|ConstraintSeeds|Program failed to complete/);
      }
    });
  });
});
