import * as anchor from "@coral-xyz/anchor";
import { Program, AnchorProvider, Wallet } from "@coral-xyz/anchor";
import { Connection, Keypair, PublicKey, SystemProgram, LAMPORTS_PER_SOL } from "@solana/web3.js";
import crypto from "crypto";
import fs from "fs";
import os from "os";
import path from "path";
import idl from "../target/idl/reputation.json";
import { Reputation } from "../target/types/reputation";

async function main() {
  console.log("================================================================");
  console.log("🌱 ClockIn Devnet Contract & Reputation Seeder");
  console.log("================================================================");

  const devnetUrl = "https://api.devnet.solana.com";
  const connection = new Connection(devnetUrl, "confirmed");

  const idPath = path.join(os.homedir(), ".config", "solana", "id.json");
  const rawKey = JSON.parse(fs.readFileSync(idPath, "utf-8"));
  const deployerKeypair = Keypair.fromSecretKey(Uint8Array.from(rawKey));
  const deployerWallet = new Wallet(deployerKeypair);

  const provider = new AnchorProvider(connection, deployerWallet, {
    commitment: "confirmed",
    preflightCommitment: "confirmed",
  });
  anchor.setProvider(provider);

  const program = new Program(idl as any, provider) as Program<Reputation>;

  console.log(`Connected to Solana Devnet RPC`);
  console.log(`Program ID: ${program.programId.toBase58()}`);
  console.log(`Deployer / Primary Wallet: ${deployerKeypair.publicKey.toBase58()}`);

  const startBalance = await connection.getBalance(deployerKeypair.publicKey);
  console.log(`Initial Balance: ${(startBalance / LAMPORTS_PER_SOL).toFixed(4)} SOL\n`);

  // Keypairs for multi-party simulation
  const workerAlex = Keypair.generate();
  const workerElena = Keypair.generate();
  const employerDao = Keypair.generate();

  console.log(`Created Worker Alex: ${workerAlex.publicKey.toBase58()}`);
  console.log(`Created Worker Elena: ${workerElena.publicKey.toBase58()}`);
  console.log(`Created Employer DAO: ${employerDao.publicKey.toBase58()}\n`);

  // Step 1: Fund auxiliary test wallets
  console.log("1. Funding auxiliary keypairs with small gas & escrow balances...");
  const fundTx = new anchor.web3.Transaction().add(
    SystemProgram.transfer({
      fromPubkey: deployerKeypair.publicKey,
      toPubkey: workerAlex.publicKey,
      lamports: 0.04 * LAMPORTS_PER_SOL,
    }),
    SystemProgram.transfer({
      fromPubkey: deployerKeypair.publicKey,
      toPubkey: workerElena.publicKey,
      lamports: 0.02 * LAMPORTS_PER_SOL,
    }),
    SystemProgram.transfer({
      fromPubkey: deployerKeypair.publicKey,
      toPubkey: employerDao.publicKey,
      lamports: 0.06 * LAMPORTS_PER_SOL,
    })
  );
  const fundSig = await provider.sendAndConfirm(fundTx);
  console.log(`   Gas funded tx: https://explorer.solana.com/tx/${fundSig}?cluster=devnet\n`);

  // Helper to ensure worker profile exists
  async function ensureWorkerRegistered(worker: Keypair, label: string) {
    const [workerProfilePda] = PublicKey.findProgramAddressSync(
      [Buffer.from("worker"), worker.publicKey.toBuffer()],
      program.programId
    );
    const existing = await connection.getAccountInfo(workerProfilePda);
    if (!existing) {
      console.log(`   Registering ${label} (${worker.publicKey.toBase58()})...`);
      const sig = await program.methods
        .registerWorker()
        .accountsPartial({
          worker: worker.publicKey,
          workerProfile: workerProfilePda,
          systemProgram: SystemProgram.programId,
        })
        .signers([worker])
        .rpc();
      console.log(`   ${label} registered tx: https://explorer.solana.com/tx/${sig}?cluster=devnet`);
    } else {
      console.log(`   ${label} profile already registered.`);
    }
    return workerProfilePda;
  }

  // Ensure deployer and workerAlex are registered as workers
  console.log("2. Ensuring Worker Profiles are registered on-chain...");
  const deployerProfilePda = await ensureWorkerRegistered(deployerKeypair, "Deployer (as Worker)");
  const alexProfilePda = await ensureWorkerRegistered(workerAlex, "Worker Alex");
  const elenaProfilePda = await ensureWorkerRegistered(workerElena, "Worker Elena");
  console.log("");

  // Helper for computing terms hash
  function computeHash(text: string): number[] {
    return Array.from(crypto.createHash("sha256").update(text).digest());
  }

  // =========================================================================
  // CONTRACT 1: Completed & 5-Star Reviewed
  // Deployer (Employer) -> Worker Alex
  // =========================================================================
  const cid1 = `aud-${Date.now().toString(36).slice(-6)}`;
  console.log(`3. Seeding Contract 1 [COMPLETED & REVIEWED]: ${cid1}`);
  {
    const [escrowPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("escrow"), Buffer.from(cid1)],
      program.programId
    );
    const [vaultPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("vault"), Buffer.from(cid1)],
      program.programId
    );
    const [reviewPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("review"), workerAlex.publicKey.toBuffer(), Buffer.from(cid1)],
      program.programId
    );

    const amount = new anchor.BN(0.015 * LAMPORTS_PER_SOL);
    const terms = "Smart Contract Audit for Anchor Escrow Protocol v1.0";
    const deadline = new anchor.BN(Math.floor(Date.now() / 1000) + 86400 * 14);

    // a) Create and fund
    const createSig = await program.methods
      .createAndFund(cid1, workerAlex.publicKey, amount, computeHash(terms), deadline)
      .accountsPartial({
        employer: deployerKeypair.publicKey,
        escrowContract: escrowPda,
        vault: vaultPda,
        systemProgram: SystemProgram.programId,
      })
      .signers([deployerKeypair])
      .rpc();
    console.log(`   Created & Funded tx: https://explorer.solana.com/tx/${createSig}?cluster=devnet`);

    // b) Accept
    const acceptSig = await program.methods
      .acceptContract(cid1)
      .accountsPartial({
        worker: workerAlex.publicKey,
        escrowContract: escrowPda,
      })
      .signers([workerAlex])
      .rpc();
    console.log(`   Accepted tx: https://explorer.solana.com/tx/${acceptSig}?cluster=devnet`);

    // c) Release and 5-star review
    const releaseSig = await program.methods
      .releaseAndReview(cid1, 5)
      .accountsPartial({
        employer: deployerKeypair.publicKey,
        worker: workerAlex.publicKey,
        workerProfile: alexProfilePda,
        escrowContract: escrowPda,
        vault: vaultPda,
        review: reviewPda,
        systemProgram: SystemProgram.programId,
      })
      .signers([deployerKeypair])
      .rpc();
    console.log(`   Released & 5-Star Reviewed tx: https://explorer.solana.com/tx/${releaseSig}?cluster=devnet`);
  }
  console.log("");

  // =========================================================================
  // CONTRACT 2: In-Progress (Active Work)
  // Deployer (Employer) -> Worker Alex
  // =========================================================================
  const cid2 = `ui-${Date.now().toString(36).slice(-6)}`;
  console.log(`4. Seeding Contract 2 [IN PROGRESS / ACTIVE]: ${cid2}`);
  {
    const [escrowPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("escrow"), Buffer.from(cid2)],
      program.programId
    );
    const [vaultPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("vault"), Buffer.from(cid2)],
      program.programId
    );

    const amount = new anchor.BN(0.02 * LAMPORTS_PER_SOL);
    const terms = "Solana Mobile dApp Store UI components & dark mode theme";
    const deadline = new anchor.BN(Math.floor(Date.now() / 1000) + 86400 * 7);

    // a) Create and fund
    const createSig = await program.methods
      .createAndFund(cid2, workerAlex.publicKey, amount, computeHash(terms), deadline)
      .accountsPartial({
        employer: deployerKeypair.publicKey,
        escrowContract: escrowPda,
        vault: vaultPda,
        systemProgram: SystemProgram.programId,
      })
      .signers([deployerKeypair])
      .rpc();
    console.log(`   Created & Funded tx: https://explorer.solana.com/tx/${createSig}?cluster=devnet`);

    // b) Accept
    const acceptSig = await program.methods
      .acceptContract(cid2)
      .accountsPartial({
        worker: workerAlex.publicKey,
        escrowContract: escrowPda,
      })
      .signers([workerAlex])
      .rpc();
    console.log(`   Accepted tx (Now InProgress): https://explorer.solana.com/tx/${acceptSig}?cluster=devnet`);
  }
  console.log("");

  // =========================================================================
  // CONTRACT 3: Funded & Awaiting Worker Acceptance
  // Deployer (Employer) -> Worker Elena
  // =========================================================================
  const cid3 = `dft-${Date.now().toString(36).slice(-6)}`;
  console.log(`5. Seeding Contract 3 [FUNDED / AWAITING ACCEPTANCE]: ${cid3}`);
  {
    const [escrowPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("escrow"), Buffer.from(cid3)],
      program.programId
    );
    const [vaultPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("vault"), Buffer.from(cid3)],
      program.programId
    );

    const amount = new anchor.BN(0.01 * LAMPORTS_PER_SOL);
    const terms = "Drift SQLite local cache background sync optimization";
    const deadline = new anchor.BN(Math.floor(Date.now() / 1000) + 86400 * 5);

    const createSig = await program.methods
      .createAndFund(cid3, workerElena.publicKey, amount, computeHash(terms), deadline)
      .accountsPartial({
        employer: deployerKeypair.publicKey,
        escrowContract: escrowPda,
        vault: vaultPda,
        systemProgram: SystemProgram.programId,
      })
      .signers([deployerKeypair])
      .rpc();
    console.log(`   Created & Funded tx: https://explorer.solana.com/tx/${createSig}?cluster=devnet`);
  }
  console.log("");

  // =========================================================================
  // CONTRACT 4: Deployer as Worker (Completed & 5-Star Reviewed)
  // Employer DAO -> Deployer (Worker)
  // =========================================================================
  const cid4 = `mwa-${Date.now().toString(36).slice(-6)}`;
  console.log(`6. Seeding Contract 4 [DEPLOYER AS WORKER - COMPLETED]: ${cid4}`);
  {
    const [escrowPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("escrow"), Buffer.from(cid4)],
      program.programId
    );
    const [vaultPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("vault"), Buffer.from(cid4)],
      program.programId
    );
    const [reviewPda] = PublicKey.findProgramAddressSync(
      [Buffer.from("review"), deployerKeypair.publicKey.toBuffer(), Buffer.from(cid4)],
      program.programId
    );

    const amount = new anchor.BN(0.02 * LAMPORTS_PER_SOL);
    const terms = "Mobile Wallet Adapter v2.0 handshake integration and testing";
    const deadline = new anchor.BN(Math.floor(Date.now() / 1000) + 86400 * 10);

    // a) Employer DAO creates and funds
    const createSig = await program.methods
      .createAndFund(cid4, deployerKeypair.publicKey, amount, computeHash(terms), deadline)
      .accountsPartial({
        employer: employerDao.publicKey,
        escrowContract: escrowPda,
        vault: vaultPda,
        systemProgram: SystemProgram.programId,
      })
      .signers([employerDao])
      .rpc();
    console.log(`   Employer DAO created & funded tx: https://explorer.solana.com/tx/${createSig}?cluster=devnet`);

    // b) Deployer accepts as worker
    const acceptSig = await program.methods
      .acceptContract(cid4)
      .accountsPartial({
        worker: deployerKeypair.publicKey,
        escrowContract: escrowPda,
      })
      .signers([deployerKeypair])
      .rpc();
    console.log(`   Deployer accepted tx: https://explorer.solana.com/tx/${acceptSig}?cluster=devnet`);

    // c) Employer DAO releases payment and gives 5-star review
    const releaseSig = await program.methods
      .releaseAndReview(cid4, 5)
      .accountsPartial({
        employer: employerDao.publicKey,
        worker: deployerKeypair.publicKey,
        workerProfile: deployerProfilePda,
        escrowContract: escrowPda,
        vault: vaultPda,
        review: reviewPda,
        systemProgram: SystemProgram.programId,
      })
      .signers([employerDao])
      .rpc();
    console.log(`   Employer DAO released & 5-Star Reviewed tx: https://explorer.solana.com/tx/${releaseSig}?cluster=devnet`);
  }

  // Summary
  console.log("\n================================================================");
  console.log("✅ DEVNET SEEDING COMPLETE!");
  console.log("================================================================");
  console.log(`Primary Wallet (${deployerKeypair.publicKey.toBase58()}):`);
  console.log(`  - 3 Contracts as Employer (${cid1} [Completed], ${cid2} [InProgress], ${cid3} [Funded])`);
  console.log(`  - 1 Contract as Worker (${cid4} [Completed])`);

  const profile = await program.account.workerProfile.fetch(deployerProfilePda);
  console.log(`  - WorkerProfile On-Chain: ${profile.totalJobs} jobs completed, ${profile.ratingSum} rating sum`);
  console.log("================================================================");
}

main().catch((err) => {
  console.error("Seeding failed:", err);
  process.exit(1);
});
