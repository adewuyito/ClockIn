# Program Spec — Reputation Program (Anchor)

This is a spec and reference skeleton, not copy-paste-final code — same caveat StellarRep's version had. It's written against a current Anchor version, but exact macro/constraint behavior shifts across Anchor releases; cross-check against the current [Anchor docs](https://www.anchor-lang.com/docs) during Phase 1–2 rather than trusting this file blindly. See `CLAUDE.md`'s ground rules on not hardcoding versions.

## Account model

Solana's account-based storage doesn't map 1:1 onto Soroban's key-value `DataKey` enum — this section documents the actual design decisions made translating StellarRep's model, not just a mechanical port.

**Decision: no on-chain review-index list.** StellarRep's Soroban version needed a `DataKey::ReviewIds(Address) -> Vec<Symbol>` just to support pagination, because Soroban has no way to query storage by anything other than an exact key. Solana's RPC has `getProgramAccounts` with `memcmp` filters — the client can ask "give me every `Review` account whose `worker` field matches this pubkey" directly, no index structure needed on-chain. This avoids the unbounded-growth-vector problem entirely rather than working around it, and is a genuine simplification, not just a different flavor of the same design.

```rust
use anchor_lang::prelude::*;

/// PDA seeds: [b"worker", worker.key().as_ref()]
/// One per worker; existence of this account is exactly "is this address registered."
#[account]
pub struct WorkerProfile {
    pub worker: Pubkey,
    pub total_jobs: u32,
    pub rating_sum: u64,   // sum of all ratings; average = rating_sum / total_jobs
    pub created_at: i64,   // Unix timestamp at registration (Clock sysvar)
    pub bump: u8,
}
impl WorkerProfile {
    // discriminator (8) + worker (32) + total_jobs (4) + rating_sum (8) + created_at (8) + bump (1)
    pub const SPACE: usize = 8 + 32 + 4 + 8 + 8 + 1;
}

/// PDA seeds: [b"review", worker.key().as_ref(), job_id.as_bytes()]
/// job_id length is bounded (see MAX_JOB_ID_LEN) since it's a PDA seed component —
/// Solana caps total seed bytes per PDA (32 bytes per seed, 16 seeds max as of
/// this writing; confirm current limits before assuming). This account's mere
/// existence at this PDA is what blocks a duplicate review for the same
/// (worker, job_id) — Anchor's `init` constraint fails if it already exists,
/// no explicit "has this job_id been used" check needed.
pub const MAX_JOB_ID_LEN: usize = 32;

#[account]
pub struct Review {
    pub worker: Pubkey,
    pub reviewer: Pubkey,
    pub job_id: String,    // <= MAX_JOB_ID_LEN
    pub rating: u8,        // 1-5
    pub timestamp: i64,
    pub bump: u8,
}
impl Review {
    // discriminator (8) + worker (32) + reviewer (32) + job_id (4 len-prefix + MAX_JOB_ID_LEN)
    // + rating (1) + timestamp (8) + bump (1)
    pub const SPACE: usize = 8 + 32 + 32 + (4 + MAX_JOB_ID_LEN) + 1 + 8 + 1;
}
```

**No rent-exemption/TTL concern the way Soroban had one.** Solana accounts are either rent-exempt (funded with enough lamports to be permanently exempt — the normal case, and what `init` with a correctly computed `space` gives you) or they get garbage-collected; there's no separate "extend the TTL periodically" maintenance call needed like Soroban's persistent-storage archival. Confirm the current rent-exemption minimum via `solana rent <space>` rather than assuming a number.

## Errors

```rust
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
}
```

Unlike Soroban's `#[contracterror]` (a plain numeric-discriminant enum the client decodes from a diagnostic string — see StellarRep's `ReputationService.run(_:)` for how awkward that ended up being), Anchor's `#[error_code]` errors arrive at the client as structured, decodable program errors via the RPC simulation/transaction response. Confirm the exact client-side decoding path (`solana` Dart package's error handling) during Phase 5 rather than assuming it's as awkward as the Soroban case was.

## Instructions

```rust
use anchor_lang::prelude::*;

declare_id!("REPLACE_WITH_DEPLOYED_PROGRAM_ID"); // set for real after Phase 3's `anchor deploy`

#[program]
pub mod reputation {
    use super::*;

    /// Worker registers themself. Signed by `worker` (Anchor's `init` +
    /// `Signer` constraint on the worker account enforces this — there's no
    /// separate `require_auth()` call the way Soroban needed).
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
    /// anchor exactly.
    pub fn submit_review(ctx: Context<SubmitReview>, job_id: String, rating: u8) -> Result<()> {
        require!(job_id.len() <= MAX_JOB_ID_LEN, ReputationError::JobIdTooLong);
        require!(rating >= 1 && rating <= 5, ReputationError::InvalidRating);
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
        profile.total_jobs += 1;
        profile.rating_sum += rating as u64;
        Ok(())
    }
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
```

**Note what's missing on purpose:** no `get_reputation`/`get_reviews` instructions. Reads happen client-side via plain RPC account fetches (`getAccountInfo` for a known worker PDA, `getProgramAccounts` with a `memcmp` filter on the `worker` field for that worker's reviews) — no transaction, no fee, no instruction needed, same "reads are free and simulate-only" spirit as the Soroban version but achieved through Solana's native account-query RPCs rather than a dedicated read function. Confirm the exact `memcmp` offset (past the 8-byte Anchor discriminator, then whatever precedes the `worker` field in `Review`'s layout) against the actual compiled IDL during Phase 5, not by hand-counting bytes from this doc.

## Testing plan

Every failure path needs a test that actually triggers it:

- `register_worker` succeeds on first call
- `register_worker` fails on a second call for the same worker (Anchor's `init` constraint rejects re-initializing an existing PDA — confirm the actual error kind Anchor surfaces here, e.g. account-already-in-use, rather than assuming it maps to a custom error)
- `submit_review` succeeds and correctly updates `total_jobs`/`rating_sum`
- `submit_review` fails if the worker was never registered (the `worker_profile` account fetch/seeds constraint should fail — confirm whether this surfaces as an Anchor account-not-found error or needs an explicit check)
- `submit_review` fails with `SelfReview` if `reviewer == worker_profile.worker`
- `submit_review` fails with `InvalidRating` for 0 and for 6
- `submit_review` fails (structurally, via the `review` PDA's `init` constraint) for a repeated `(worker, job_id)`
- `submit_review` fails if not actually signed by the claimed reviewer (Anchor's `Signer<'info>` type should make an unsigned reviewer impossible to construct a valid transaction with — confirm this holds via a test that tries anyway, not just by trusting the type system, mirroring how StellarRep explicitly tested `require_auth` rather than assuming it worked because it compiled)

Run with `anchor test` (spins up a local validator, runs against it) during Phase 1–2. Deploy the actual devnet artifact separately in Phase 3 with `anchor deploy` — confirm the current recommended local-vs-devnet test workflow against the Anchor docs, since `anchor test` can be configured to run against either.
