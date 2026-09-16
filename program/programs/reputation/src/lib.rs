use anchor_lang::prelude::*;
use anchor_lang::system_program;

declare_id!("FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9"); // program keypair at program/reputation-keypair.json (gitignored — devnet only, regenerate + update here if lost)

/// job_id is bounded since it's a PDA seed component — Solana caps total
/// seed bytes per PDA. See docs/PROGRAM_SPEC.md for the full reasoning.
pub const MAX_JOB_ID_LEN: usize = 32;
pub const MAX_CONTRACT_ID_LEN: usize = 32;

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

    // =========================================================================
    // P2P ESCROW CONTRACT PROTOCOL INSTRUCTIONS
    // =========================================================================

    /// Employer creates an escrow contract specification without funding yet.
    pub fn create_contract(
        ctx: Context<CreateContract>,
        contract_id: String,
        worker: Pubkey,
        amount: u64,
        terms_hash: [u8; 32],
        deadline: i64,
    ) -> Result<()> {
        require!(contract_id.len() <= MAX_CONTRACT_ID_LEN, ReputationError::ContractIdTooLong);
        require!(amount > 0, ReputationError::ZeroAmount);
        require!(ctx.accounts.employer.key() != worker, ReputationError::SelfContract);
        if deadline > 0 {
            require!(deadline > Clock::get()?.unix_timestamp, ReputationError::InvalidDeadline);
        }

        let contract = &mut ctx.accounts.escrow_contract;
        contract.contract_id = contract_id;
        contract.employer = ctx.accounts.employer.key();
        contract.worker = worker;
        contract.amount = amount;
        contract.terms_hash = terms_hash;
        contract.status = ContractStatus::Created;
        contract.deadline = deadline;
        contract.created_at = Clock::get()?.unix_timestamp;
        contract.funded_at = 0;
        contract.completed_at = 0;
        contract.rating = 0;
        contract.bump = ctx.bumps.escrow_contract;
        contract.vault_bump = 0;
        Ok(())
    }

    /// Employer funds an already-created contract, locking `amount` lamports into Vault PDA.
    pub fn fund_contract(ctx: Context<FundContract>, _contract_id: String) -> Result<()> {
        let contract = &mut ctx.accounts.escrow_contract;
        require!(contract.status == ContractStatus::Created, ReputationError::InvalidContractStatus);

        // Transfer funds from employer to Vault PDA
        let cpi_context = CpiContext::new(
            ctx.accounts.system_program.key(),
            system_program::Transfer {
                from: ctx.accounts.employer.to_account_info(),
                to: ctx.accounts.vault.to_account_info(),
            },
        );
        system_program::transfer(cpi_context, contract.amount)?;

        let vault = &mut ctx.accounts.vault;
        vault.bump = ctx.bumps.vault;

        contract.vault_bump = ctx.bumps.vault;
        contract.status = ContractStatus::Funded;
        contract.funded_at = Clock::get()?.unix_timestamp;
        Ok(())
    }

    /// Convenience instruction: Employer creates and funds contract in a single transaction.
    pub fn create_and_fund(
        ctx: Context<CreateAndFundContract>,
        contract_id: String,
        worker: Pubkey,
        amount: u64,
        terms_hash: [u8; 32],
        deadline: i64,
    ) -> Result<()> {
        require!(contract_id.len() <= MAX_CONTRACT_ID_LEN, ReputationError::ContractIdTooLong);
        require!(amount > 0, ReputationError::ZeroAmount);
        require!(ctx.accounts.employer.key() != worker, ReputationError::SelfContract);
        if deadline > 0 {
            require!(deadline > Clock::get()?.unix_timestamp, ReputationError::InvalidDeadline);
        }

        let contract = &mut ctx.accounts.escrow_contract;
        contract.contract_id = contract_id;
        contract.employer = ctx.accounts.employer.key();
        contract.worker = worker;
        contract.amount = amount;
        contract.terms_hash = terms_hash;
        contract.status = ContractStatus::Funded;
        contract.deadline = deadline;
        contract.created_at = Clock::get()?.unix_timestamp;
        contract.funded_at = Clock::get()?.unix_timestamp;
        contract.completed_at = 0;
        contract.rating = 0;
        contract.bump = ctx.bumps.escrow_contract;
        contract.vault_bump = ctx.bumps.vault;

        let vault = &mut ctx.accounts.vault;
        vault.bump = ctx.bumps.vault;

        // Transfer escrow amount to Vault PDA
        let cpi_context = CpiContext::new(
            ctx.accounts.system_program.key(),
            system_program::Transfer {
                from: ctx.accounts.employer.to_account_info(),
                to: ctx.accounts.vault.to_account_info(),
            },
        );
        system_program::transfer(cpi_context, amount)?;
        Ok(())
    }

    /// Worker accepts the funded contract terms. Status transitions to InProgress.
    pub fn accept_contract(ctx: Context<AcceptContract>, _contract_id: String) -> Result<()> {
        let contract = &mut ctx.accounts.escrow_contract;
        require!(contract.status == ContractStatus::Funded, ReputationError::InvalidContractStatus);

        contract.status = ContractStatus::InProgress;
        Ok(())
    }

    /// Employer releases escrow payment to worker and writes verified on-chain review atomically.
    pub fn release_and_review(
        ctx: Context<ReleaseAndReview>,
        contract_id: String,
        rating: u8,
    ) -> Result<()> {
        require!((1..=5).contains(&rating), ReputationError::InvalidRating);

        let contract = &mut ctx.accounts.escrow_contract;
        require!(contract.status == ContractStatus::InProgress, ReputationError::InvalidContractStatus);
        require!(contract.worker == ctx.accounts.worker.key(), ReputationError::WorkerMismatch);
        require!(ctx.accounts.worker_profile.worker == ctx.accounts.worker.key(), ReputationError::WorkerMismatch);

        let amount = contract.amount;

        // 1. Transfer escrowed amount from Vault PDA to Worker account
        **ctx.accounts.vault.to_account_info().try_borrow_mut_lamports()? = ctx
            .accounts
            .vault
            .to_account_info()
            .lamports()
            .checked_sub(amount)
            .ok_or(ReputationError::Overflow)?;

        **ctx.accounts.worker.to_account_info().try_borrow_mut_lamports()? = ctx
            .accounts
            .worker
            .to_account_info()
            .lamports()
            .checked_add(amount)
            .ok_or(ReputationError::Overflow)?;

        // Note: Vault account's remaining rent lamports are automatically returned to employer
        // via Anchor's `close = employer` constraint on `vault`.

        // 2. Initialize the immutable Review PDA
        let review = &mut ctx.accounts.review;
        review.worker = ctx.accounts.worker.key();
        review.reviewer = ctx.accounts.employer.key();
        review.job_id = contract_id;
        review.rating = rating;
        review.timestamp = Clock::get()?.unix_timestamp;
        review.bump = ctx.bumps.review;

        // 3. Update worker profile aggregated reputation
        let profile = &mut ctx.accounts.worker_profile;
        profile.total_jobs = profile
            .total_jobs
            .checked_add(1)
            .ok_or(ReputationError::Overflow)?;
        profile.rating_sum = profile
            .rating_sum
            .checked_add(rating as u64)
            .ok_or(ReputationError::Overflow)?;

        // 4. Update contract status to Completed
        contract.status = ContractStatus::Completed;
        contract.completed_at = Clock::get()?.unix_timestamp;
        contract.rating = rating;
        Ok(())
    }

    /// Employer cancels a funded contract before worker accepts. Reclaims all vault funds.
    pub fn cancel_contract(ctx: Context<CancelContract>, _contract_id: String) -> Result<()> {
        let contract = &mut ctx.accounts.escrow_contract;
        require!(contract.status == ContractStatus::Funded, ReputationError::InvalidContractStatus);

        // Vault is closed to employer via `close = employer`, refunding both the escrow amount and vault rent!
        contract.status = ContractStatus::Cancelled;
        Ok(())
    }

    /// Either party (employer or worker) raises a dispute on an active InProgress contract.
    pub fn raise_dispute(ctx: Context<RaiseDispute>, _contract_id: String) -> Result<()> {
        let contract = &mut ctx.accounts.escrow_contract;
        require!(contract.status == ContractStatus::InProgress, ReputationError::InvalidContractStatus);
        let caller = ctx.accounts.caller.key();
        require!(
            caller == contract.employer || caller == contract.worker,
            ReputationError::UnauthorizedParticipant
        );

        contract.status = ContractStatus::Disputed;
        Ok(())
    }
}

// =============================================================================
// STATE ACCOUNTS & DATA MODELS
// =============================================================================

/// PDA seeds: [b"worker", worker.key().as_ref()]
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

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq, Debug)]
pub enum ContractStatus {
    Created,
    Funded,
    InProgress,
    Completed,
    Disputed,
    Cancelled,
}

/// PDA seeds: [b"escrow", contract_id.as_bytes()]
#[account]
pub struct EscrowContract {
    pub contract_id: String,       // 4 + MAX_CONTRACT_ID_LEN
    pub employer: Pubkey,          // 32
    pub worker: Pubkey,            // 32
    pub amount: u64,               // 8 (lamports)
    pub terms_hash: [u8; 32],      // 32 (SHA-256)
    pub status: ContractStatus,    // 1
    pub deadline: i64,             // 8
    pub created_at: i64,           // 8
    pub funded_at: i64,            // 8
    pub completed_at: i64,         // 8
    pub rating: u8,                // 1
    pub bump: u8,                  // 1
    pub vault_bump: u8,            // 1
}

impl EscrowContract {
    pub const SPACE: usize = 8
        + (4 + MAX_CONTRACT_ID_LEN)
        + 32
        + 32
        + 8
        + 32
        + 1
        + 8
        + 8
        + 8
        + 8
        + 1
        + 1
        + 1;
}

/// PDA seeds: [b"vault", contract_id.as_bytes()]
#[account]
pub struct EscrowVault {
    pub bump: u8,
}

impl EscrowVault {
    pub const SPACE: usize = 8 + 1;
}

// =============================================================================
// ERROR CODES
// =============================================================================

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
    #[msg("contract_id exceeds maximum length of 32 bytes.")]
    ContractIdTooLong,
    #[msg("Escrow amount must be greater than zero.")]
    ZeroAmount,
    #[msg("Employer cannot hire themself.")]
    SelfContract,
    #[msg("Contract deadline must be in the future.")]
    InvalidDeadline,
    #[msg("Contract is not in the required status for this action.")]
    InvalidContractStatus,
    #[msg("Only the assigned worker can accept this contract.")]
    UnauthorizedWorker,
    #[msg("Only the employer can perform this action.")]
    UnauthorizedEmployer,
    #[msg("Only a contract participant (employer or worker) can perform this action.")]
    UnauthorizedParticipant,
    #[msg("Worker account does not match the contract recipient.")]
    WorkerMismatch,
}

// =============================================================================
// INSTRUCTION CONTEXT STRUCTS
// =============================================================================

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

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct CreateContract<'info> {
    #[account(mut)]
    pub employer: Signer<'info>,
    #[account(
        init,
        payer = employer,
        space = EscrowContract::SPACE,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct FundContract<'info> {
    #[account(mut)]
    pub employer: Signer<'info>,
    #[account(
        mut,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        has_one = employer @ ReputationError::UnauthorizedEmployer,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
    #[account(
        init,
        payer = employer,
        space = EscrowVault::SPACE,
        seeds = [b"vault", contract_id.as_bytes()],
        bump,
    )]
    pub vault: Account<'info, EscrowVault>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct CreateAndFundContract<'info> {
    #[account(mut)]
    pub employer: Signer<'info>,
    #[account(
        init,
        payer = employer,
        space = EscrowContract::SPACE,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
    #[account(
        init,
        payer = employer,
        space = EscrowVault::SPACE,
        seeds = [b"vault", contract_id.as_bytes()],
        bump,
    )]
    pub vault: Account<'info, EscrowVault>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct AcceptContract<'info> {
    #[account(mut)]
    pub worker: Signer<'info>,
    #[account(
        mut,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        has_one = worker @ ReputationError::UnauthorizedWorker,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct ReleaseAndReview<'info> {
    #[account(mut)]
    pub employer: Signer<'info>,
    #[account(
        mut,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        has_one = employer @ ReputationError::UnauthorizedEmployer,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
    #[account(
        mut,
        close = employer,
        seeds = [b"vault", contract_id.as_bytes()],
        bump = escrow_contract.vault_bump,
    )]
    pub vault: Account<'info, EscrowVault>,
    /// CHECK: Recipient of the escrowed SOL; validated against escrow_contract.worker
    #[account(mut)]
    pub worker: UncheckedAccount<'info>,
    #[account(
        mut,
        seeds = [b"worker", worker.key().as_ref()],
        bump = worker_profile.bump,
    )]
    pub worker_profile: Account<'info, WorkerProfile>,
    #[account(
        init,
        payer = employer,
        space = Review::SPACE,
        seeds = [b"review", worker.key().as_ref(), contract_id.as_bytes()],
        bump,
    )]
    pub review: Account<'info, Review>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct CancelContract<'info> {
    #[account(mut)]
    pub employer: Signer<'info>,
    #[account(
        mut,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        has_one = employer @ ReputationError::UnauthorizedEmployer,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
    #[account(
        mut,
        close = employer,
        seeds = [b"vault", contract_id.as_bytes()],
        bump = escrow_contract.vault_bump,
    )]
    pub vault: Account<'info, EscrowVault>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct RaiseDispute<'info> {
    #[account(mut)]
    pub caller: Signer<'info>,
    #[account(
        mut,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
}
