use anchor_lang::prelude::*;

declare_id!("FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9"); // program keypair at program/reputation-keypair.json (gitignored — devnet only, regenerate + update here if lost)

/// job_id is bounded since it's a PDA seed component — Solana caps total
/// seed bytes per PDA. See docs/PROGRAM_SPEC.md for the full reasoning.
pub const MAX_JOB_ID_LEN: usize = 32;

#[program]
pub mod reputation {
    use super::*;

    /// Worker registers themself. Signed by `worker` — enforced structurally
    /// by the `Signer` + `init` constraints on `RegisterWorker`, not a
    /// separate runtime check the way Soroban's `require_auth()` needed.
    pub fn register_worker(ctx: Context<RegisterWorker>) -> Result<()> {
        let profile = &mut ctx.accounts.worker_profile;
        profile.worker = ctx.accounts.worker.key();
        profile.total_jobs = 0;
        profile.rating_sum = 0;
        profile.created_at = Clock::get()?.unix_timestamp;
        profile.bump = ctx.bumps.worker_profile;
        Ok(())
    }

    /// Reviewer submits a review for a worker's completed job. Signed by
    /// `reviewer`, NOT `worker` — mirrors StellarRep's sybil-resistance
    /// anchor exactly (see docs/ARCHITECTURE.md).
    pub fn submit_review(ctx: Context<SubmitReview>, job_id: String, rating: u8) -> Result<()> {
        require!(job_id.len() <= MAX_JOB_ID_LEN, ReputationError::JobIdTooLong);
        require!(
            (1..=5).contains(&rating),
            ReputationError::InvalidRating
        );
        require!(
            ctx.accounts.worker_profile.worker != ctx.accounts.reviewer.key(),
            ReputationError::SelfReview
        );
        // Duplicate-review protection is structural, not a manual check: the
        // `review` account's `init` constraint (seeded off worker + job_id)
        // already fails the whole instruction if this exact PDA exists.

        let review = &mut ctx.accounts.review;
        review.worker = ctx.accounts.worker_profile.worker;
        review.reviewer = ctx.accounts.reviewer.key();
        review.job_id = job_id;
        review.rating = rating;
        review.timestamp = Clock::get()?.unix_timestamp;
        review.bump = ctx.bumps.review;

        let profile = &mut ctx.accounts.worker_profile;
        profile.total_jobs = profile
            .total_jobs
            .checked_add(1)
            .ok_or(ReputationError::Overflow)?;
        profile.rating_sum = profile
            .rating_sum
            .checked_add(rating as u64)
            .ok_or(ReputationError::Overflow)?;
        Ok(())
    }
}

/// PDA seeds: [b"worker", worker.key().as_ref()]
/// One per worker; existence of this account is exactly "is this address
/// registered." No get_reputation instruction — read this account directly
/// via RPC (getAccountInfo), see docs/PROGRAM_SPEC.md.
#[account]
pub struct WorkerProfile {
    pub worker: Pubkey,
    pub total_jobs: u32,
    pub rating_sum: u64,
    pub created_at: i64,
    pub bump: u8,
}
impl WorkerProfile {
    pub const SPACE: usize = 8 + 32 + 4 + 8 + 8 + 1;
}

/// PDA seeds: [b"review", worker.key().as_ref(), job_id.as_bytes()]
/// No on-chain review-index list — a worker's reviews are fetched via
/// getProgramAccounts + a memcmp filter on `worker`, see
/// docs/PROGRAM_SPEC.md for why that's a deliberate simplification versus
/// StellarRep's Soroban `ReviewIds` vector.
#[account]
pub struct Review {
    pub worker: Pubkey,
    pub reviewer: Pubkey,
    pub job_id: String,
    pub rating: u8,
    pub timestamp: i64,
    pub bump: u8,
}
impl Review {
    pub const SPACE: usize = 8 + 32 + 32 + (4 + MAX_JOB_ID_LEN) + 1 + 8 + 1;
}

#[error_code]
pub enum ReputationError {
    #[msg("This address is already registered.")]
    AlreadyRegistered,
    #[msg("This address has not registered yet.")]
    NotRegistered,
    #[msg("Rating must be between 1 and 5.")]
    InvalidRating,
    #[msg("A review for this job has already been submitted.")]
    DuplicateReview,
    #[msg("A worker cannot review themself.")]
    SelfReview,
    #[msg("job_id is too long.")]
    JobIdTooLong,
    #[msg("Arithmetic overflow.")]
    Overflow,
}

#[derive(Accounts)]
pub struct RegisterWorker<'info> {
    #[account(mut)]
    pub worker: Signer<'info>,
    #[account(
        init,
        payer = worker,
        space = WorkerProfile::SPACE,
        seeds = [b"worker", worker.key().as_ref()],
        bump,
    )]
    pub worker_profile: Account<'info, WorkerProfile>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(job_id: String)]
pub struct SubmitReview<'info> {
    #[account(mut)]
    pub reviewer: Signer<'info>,
    #[account(
        mut,
        seeds = [b"worker", worker_profile.worker.as_ref()],
        bump = worker_profile.bump,
    )]
    pub worker_profile: Account<'info, WorkerProfile>,
    #[account(
        init,
        payer = reviewer,
        space = Review::SPACE,
        seeds = [b"review", worker_profile.worker.as_ref(), job_id.as_bytes()],
        bump,
    )]
    pub review: Account<'info, Review>,
    pub system_program: Program<'info, System>,
}
