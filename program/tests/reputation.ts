import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey, Keypair, SystemProgram, LAMPORTS_PER_SOL } from "@solana/web3.js";
import { expect } from "chai";
import { Reputation } from "../target/types/reputation";

describe("reputation", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.Reputation as Program<Reputation>;

  const worker = Keypair.generate();
  const reviewer = Keypair.generate();
  const reviewer2 = Keypair.generate();

  // PDA helper
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

  before(async () => {
    // Fund test keypairs directly from provider wallet (500M SOL on test validator)
    const tx = new anchor.web3.Transaction().add(
      SystemProgram.transfer({
        fromPubkey: provider.wallet.publicKey,
        toPubkey: worker.publicKey,
        lamports: 2 * LAMPORTS_PER_SOL,
      }),
      SystemProgram.transfer({
        fromPubkey: provider.wallet.publicKey,
        toPubkey: reviewer.publicKey,
        lamports: 2 * LAMPORTS_PER_SOL,
      }),
      SystemProgram.transfer({
        fromPubkey: provider.wallet.publicKey,
        toPubkey: reviewer2.publicKey,
        lamports: 2 * LAMPORTS_PER_SOL,
      })
    );
    await provider.sendAndConfirm(tx);
  });

  describe("Phase 1: Worker Registration", () => {
    it("successfully registers a new worker profile", async () => {
      const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);

      await program.methods
        .registerWorker()
        .accounts({
          worker: worker.publicKey,
          workerProfile: workerProfilePda,
          systemProgram: SystemProgram.programId,
        })
        .signers([worker])
        .rpc();

      const profileAccount = await program.account.workerProfile.fetch(
        workerProfilePda
      );

      expect(profileAccount.worker.toBase58()).to.equal(
        worker.publicKey.toBase58()
      );
      expect(profileAccount.totalJobs).to.equal(0);
      expect(profileAccount.ratingSum.toNumber()).to.equal(0);
      expect(profileAccount.createdAt.toNumber()).to.be.greaterThan(0);
    });

    it("rejects re-registration of an already registered worker", async () => {
      const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);

      try {
        await program.methods
          .registerWorker()
          .accounts({
            worker: worker.publicKey,
            workerProfile: workerProfilePda,
            systemProgram: SystemProgram.programId,
          })
          .signers([worker])
          .rpc();
        expect.fail("Should have failed to re-register worker");
      } catch (err: any) {
        // Anchor init constraint fails when account already exists
        expect(err).to.exist;
      }
    });
  });

  describe("Phase 2: Review Submissions & Reputation Read Path", () => {
    const jobId1 = "job-cleaning-101";
    const jobId2 = "job-plumbing-202";

    it("submits a valid review from a reviewer", async () => {
      const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);
      const [reviewPda] = findReviewPda(worker.publicKey, jobId1);

      await program.methods
        .submitReview(jobId1, 5)
        .accounts({
          reviewer: reviewer.publicKey,
          workerProfile: workerProfilePda,
          review: reviewPda,
          systemProgram: SystemProgram.programId,
        })
        .signers([reviewer])
        .rpc();

      const reviewAccount = await program.account.review.fetch(reviewPda);
      expect(reviewAccount.worker.toBase58()).to.equal(worker.publicKey.toBase58());
      expect(reviewAccount.reviewer.toBase58()).to.equal(reviewer.publicKey.toBase58());
      expect(reviewAccount.jobId).to.equal(jobId1);
      expect(reviewAccount.rating).to.equal(5);
      expect(reviewAccount.timestamp.toNumber()).to.be.greaterThan(0);

      // Verify worker profile aggregates updated
      const profileAccount = await program.account.workerProfile.fetch(workerProfilePda);
      expect(profileAccount.totalJobs).to.equal(1);
      expect(profileAccount.ratingSum.toNumber()).to.equal(5);
    });

    it("submits a second review from a different reviewer", async () => {
      const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);
      const [reviewPda] = findReviewPda(worker.publicKey, jobId2);

      await program.methods
        .submitReview(jobId2, 4)
        .accounts({
          reviewer: reviewer2.publicKey,
          workerProfile: workerProfilePda,
          review: reviewPda,
          systemProgram: SystemProgram.programId,
        })
        .signers([reviewer2])
        .rpc();

      const profileAccount = await program.account.workerProfile.fetch(workerProfilePda);
      expect(profileAccount.totalJobs).to.equal(2);
      expect(profileAccount.ratingSum.toNumber()).to.equal(9); // 5 + 4
    });

    it("rejects self-review (worker reviewing themself)", async () => {
      const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);
      const [reviewPda] = findReviewPda(worker.publicKey, "self-review-attempt");

      try {
        await program.methods
          .submitReview("self-review-attempt", 5)
          .accounts({
            reviewer: worker.publicKey, // Same as worker!
            workerProfile: workerProfilePda,
            review: reviewPda,
            systemProgram: SystemProgram.programId,
          })
          .signers([worker])
          .rpc();
        expect.fail("Should have failed with SelfReview");
      } catch (err: any) {
        expect(err.error?.errorCode?.code || err.toString()).to.include(
          "SelfReview"
        );
      }
    });

    it("rejects rating out of bounds (0)", async () => {
      const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);
      const [reviewPda] = findReviewPda(worker.publicKey, "job-zero-rating");

      try {
        await program.methods
          .submitReview("job-zero-rating", 0)
          .accounts({
            reviewer: reviewer.publicKey,
            workerProfile: workerProfilePda,
            review: reviewPda,
            systemProgram: SystemProgram.programId,
          })
          .signers([reviewer])
          .rpc();
        expect.fail("Should have failed with InvalidRating");
      } catch (err: any) {
        expect(err.error?.errorCode?.code || err.toString()).to.include(
          "InvalidRating"
        );
      }
    });

    it("rejects rating out of bounds (6)", async () => {
      const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);
      const [reviewPda] = findReviewPda(worker.publicKey, "job-six-rating");

      try {
        await program.methods
          .submitReview("job-six-rating", 6)
          .accounts({
            reviewer: reviewer.publicKey,
            workerProfile: workerProfilePda,
            review: reviewPda,
            systemProgram: SystemProgram.programId,
          })
          .signers([reviewer])
          .rpc();
        expect.fail("Should have failed with InvalidRating");
      } catch (err: any) {
        expect(err.error?.errorCode?.code || err.toString()).to.include(
          "InvalidRating"
        );
      }
    });

    it("rejects duplicate review for the same (worker, job_id)", async () => {
      const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);
      const [reviewPda] = findReviewPda(worker.publicKey, jobId1); // Already reviewed jobId1!

      try {
        await program.methods
          .submitReview(jobId1, 4)
          .accounts({
            reviewer: reviewer.publicKey,
            workerProfile: workerProfilePda,
            review: reviewPda,
            systemProgram: SystemProgram.programId,
          })
          .signers([reviewer])
          .rpc();
        expect.fail("Should have failed duplicate review via PDA init constraint");
      } catch (err: any) {
        expect(err).to.exist;
      }
    });

    it("rejects job_id exceeding 32 characters", async () => {
      const longJobId = "this-job-id-is-way-too-long-and-exceeds-32-chars";
      const [workerProfilePda] = findWorkerProfilePda(worker.publicKey);
      const [reviewPda] = findReviewPda(worker.publicKey, longJobId.substring(0, 32));

      try {
        await program.methods
          .submitReview(longJobId, 5)
          .accounts({
            reviewer: reviewer.publicKey,
            workerProfile: workerProfilePda,
            review: reviewPda,
            systemProgram: SystemProgram.programId,
          })
          .signers([reviewer])
          .rpc();
        expect.fail("Should have failed with JobIdTooLong");
      } catch (err: any) {
        const errText = (err.error?.errorCode?.code || "") + (err.toString() || "") + (err.logs?.join(" ") || "");
        expect(errText).to.match(/JobIdTooLong|ConstraintSeeds|Program failed to complete/);
      }
    });

    it("reads back reviews using getProgramAccounts and memcmp filter", async () => {
      // Anchor's review.all applies the 8-byte Review discriminator + our memcmp on worker (offset 8)
      const reviews = await program.account.review.all([
        {
          memcmp: {
            offset: 8,
            bytes: worker.publicKey.toBase58(),
          },
        },
      ]);

      // We submitted 2 successful reviews for this worker (jobId1 and jobId2)
      expect(reviews.length).to.equal(2);

      const jobIds = reviews.map((r) => r.account.jobId);
      expect(jobIds).to.include(jobId1);
      expect(jobIds).to.include(jobId2);
    });
  });
});
