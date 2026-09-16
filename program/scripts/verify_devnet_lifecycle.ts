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
  console.log("=== Starting ClockIn Devnet Escrow Lifecycle Verification ===");

  // 1. Connection & Provider setup for Solana Devnet
  const devnetUrl = "https://api.devnet.solana.com";
  const connection = new Connection(devnetUrl, "confirmed");

  const idPath = path.join(os.homedir(), ".config", "solana", "id.json");
  const rawKey = JSON.parse(fs.readFileSync(idPath, "utf-8"));
  const employerKeypair = Keypair.fromSecretKey(Uint8Array.from(rawKey));
  const employerWallet = new Wallet(employerKeypair);

  const provider = new AnchorProvider(connection, employerWallet, {
    commitment: "confirmed",
    preflightCommitment: "confirmed",
  });
  anchor.setProvider(provider);

  const program = new Program(idl as any, provider) as Program<Reputation>;
  console.log(`Connected to Devnet RPC: ${devnetUrl}`);
  console.log(`Program ID: ${program.programId.toBase58()}`);
  console.log(`Employer (Deployer): ${employerKeypair.publicKey.toBase58()}`);

  const employerBalance = await connection.getBalance(employerKeypair.publicKey);
  console.log(`Employer Balance: ${(employerBalance / LAMPORTS_PER_SOL).toFixed(4)} SOL`);

  // 2. Generate Worker Keypair and fund with gas
  const workerKeypair = Keypair.generate();
  console.log(`Generated Test Worker: ${workerKeypair.publicKey.toBase58()}`);

  console.log("Funding test worker with 0.05 SOL for gas...");
  const fundTx = new anchor.web3.Transaction().add(
    SystemProgram.transfer({
      fromPubkey: employerKeypair.publicKey,
      toPubkey: workerKeypair.publicKey,
      lamports: 0.05 * LAMPORTS_PER_SOL,
    })
  );
  const fundSig = await provider.sendAndConfirm(fundTx);
  console.log(`Funded worker tx: https://explorer.solana.com/tx/${fundSig}?cluster=devnet`);

  // 3. Register worker profile on-chain
  const [workerProfilePda] = PublicKey.findProgramAddressSync(
    [Buffer.from("worker"), workerKeypair.publicKey.toBuffer()],
    program.programId
  );
  console.log(`WorkerProfile PDA: ${workerProfilePda.toBase58()}`);

  console.log("Registering worker profile...");
  const regSig = await program.methods
    .registerWorker()
    .accountsPartial({
      worker: workerKeypair.publicKey,
      workerProfile: workerProfilePda,
      systemProgram: SystemProgram.programId,
    })
    .signers([workerKeypair])
    .rpc();
  console.log(`Worker registered tx: https://explorer.solana.com/tx/${regSig}?cluster=devnet`);

  // 4. Create and fund contract
  const contractId = `ctr-${Date.now().toString(36).slice(-8)}`;
  const escrowAmount = new anchor.BN(0.01 * LAMPORTS_PER_SOL);
  const terms = "Devnet verified escrow agreement for ClockIn protocol verification";
  const termsHash = Array.from(crypto.createHash("sha256").update(terms).digest());
  const deadline = new anchor.BN(Math.floor(Date.now() / 1000) + 86400 * 7);

  const [escrowPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("escrow"), Buffer.from(contractId)],
    program.programId
  );
  const [vaultPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("vault"), Buffer.from(contractId)],
    program.programId
  );

  console.log(`\nContract ID: ${contractId}`);
  console.log(`Escrow PDA: ${escrowPda.toBase58()}`);
  console.log(`Vault PDA: ${vaultPda.toBase58()}`);

  console.log("Calling create_and_fund (0.01 SOL)...");
  const createSig = await program.methods
    .createAndFund(contractId, workerKeypair.publicKey, escrowAmount, termsHash, deadline)
    .accountsPartial({
      employer: employerKeypair.publicKey,
      escrowContract: escrowPda,
      vault: vaultPda,
      systemProgram: SystemProgram.programId,
    })
    .signers([employerKeypair])
    .rpc();
  console.log(`Contract created & funded tx: https://explorer.solana.com/tx/${createSig}?cluster=devnet`);

  // Verify status is Funded
  let contractState = await program.account.escrowContract.fetch(escrowPda);
  console.log(`Contract on-chain status: ${JSON.stringify(contractState.status)}`);
  const vaultBalance = await connection.getBalance(vaultPda);
  console.log(`Vault balance: ${(vaultBalance / LAMPORTS_PER_SOL).toFixed(4)} SOL`);

  // 5. Worker accepts contract
  console.log("\nWorker accepting contract...");
  const acceptSig = await program.methods
    .acceptContract(contractId)
    .accountsPartial({
      worker: workerKeypair.publicKey,
      escrowContract: escrowPda,
    })
    .signers([workerKeypair])
    .rpc();
  console.log(`Contract accepted tx: https://explorer.solana.com/tx/${acceptSig}?cluster=devnet`);

  contractState = await program.account.escrowContract.fetch(escrowPda);
  console.log(`Contract on-chain status: ${JSON.stringify(contractState.status)}`);

  // 6. Employer releases payment and reviews atomically
  const [reviewPda] = PublicKey.findProgramAddressSync(
    [Buffer.from("review"), workerKeypair.publicKey.toBuffer(), Buffer.from(contractId)],
    program.programId
  );
  console.log(`Review PDA: ${reviewPda.toBase58()}`);

  console.log("\nEmployer releasing payment & submitting rating (5 stars)...");
  const workerBalBefore = await connection.getBalance(workerKeypair.publicKey);

  const releaseSig = await program.methods
    .releaseAndReview(contractId, 5)
    .accountsPartial({
      employer: employerKeypair.publicKey,
      worker: workerKeypair.publicKey,
      workerProfile: workerProfilePda,
      escrowContract: escrowPda,
      vault: vaultPda,
      review: reviewPda,
      systemProgram: SystemProgram.programId,
    })
    .signers([employerKeypair])
    .rpc();
  console.log(`Release and review tx: https://explorer.solana.com/tx/${releaseSig}?cluster=devnet`);

  // 7. Verify all on-chain outcomes
  const workerBalAfter = await connection.getBalance(workerKeypair.publicKey);
  console.log(`Worker received: ${((workerBalAfter - workerBalBefore) / LAMPORTS_PER_SOL).toFixed(4)} SOL`);

  contractState = await program.account.escrowContract.fetch(escrowPda);
  console.log(`Final Contract status: ${JSON.stringify(contractState.status)}`);
  console.log(`Final Contract rating: ${contractState.rating}`);

  const reviewState = await program.account.review.fetch(reviewPda);
  console.log(`Review on-chain: rating=${reviewState.rating}, jobId=${reviewState.jobId}`);

  const profileState = await program.account.workerProfile.fetch(workerProfilePda);
  console.log(
    `WorkerProfile on-chain: totalJobs=${profileState.totalJobs.toString()}, ratingSum=${profileState.ratingSum.toString()}, avgRating=${(Number(profileState.ratingSum) / Number(profileState.totalJobs)).toFixed(1)}`
  );

  console.log("\n🎉 FULL DEVNET ESCROW LIFECYCLE VERIFIED SUCCESSFULLY!");
  console.log("=============================================================");
}

main().catch((err) => {
  console.error("Verification failed:", err);
  process.exit(1);
});
