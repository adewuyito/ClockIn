use anchor_lang::prelude::*;
use anchor_lang::system_program;
use anchor_spl::associated_token::AssociatedToken;
use anchor_spl::token::{self, CloseAccount, Mint, Token, TokenAccount, Transfer};

declare_id!("FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9"); // program keypair at program/reputation-keypair.json (gitignored — devnet only, regenerate + update here if lost)

/// job_id is bounded since it's a PDA seed component — Solana caps total
/// seed bytes per PDA. See docs/PROGRAM_SPEC.md for the full reasoning.
pub const MAX_JOB_ID_LEN: usize = 32;
pub const MAX_CONTRACT_ID_LEN: usize = 32;

/// Juror arbitration is switched off until jurors can be selected by the
/// protocol rather than by a party to the dispute. With it on, whoever opens a
/// case names all three jurors — so a party could name wallets they control.
/// The DisputeCase / vote / ruling code is kept for that future jury; only
/// opening a new case is refused. See docs/ARCHITECTURE.md, "Dispute resolution".
pub const JURY_ENABLED: bool = false;

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
        contract.is_token = false;
        contract.token_mint = Pubkey::default();
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
        contract.is_token = false;
        contract.token_mint = Pubkey::default();

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
        require!(!contract.is_token, ReputationError::TokenContract);
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
        require!(!contract.is_token, ReputationError::TokenContract);
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

    /// Resolves an active dispute on a native SOL escrow contract via mutual or unilateral settlement.
    pub fn resolve_dispute(
        ctx: Context<ResolveDispute>,
        _contract_id: String,
        resolution: DisputeResolution,
    ) -> Result<()> {
        let escrow_key = ctx.accounts.escrow_contract.key();
        let contract = &mut ctx.accounts.escrow_contract;
        require!(contract.status == ContractStatus::Disputed, ReputationError::InvalidContractStatus);
        require!(!contract.is_token, ReputationError::TokenContract);

        let caller = ctx.accounts.caller.key();
        require!(
            caller == contract.employer || caller == contract.worker,
            ReputationError::UnauthorizedParticipant
        );
        require!(contract.employer == ctx.accounts.employer.key(), ReputationError::UnauthorizedEmployer);
        require!(contract.worker == ctx.accounts.worker.key(), ReputationError::WorkerMismatch);

        match resolution {
            DisputeResolution::ReleaseToWorker => {
                require!(caller == contract.employer, ReputationError::UnauthorizedEmployer);
            },
            DisputeResolution::RefundToEmployer => {
                require!(caller == contract.worker, ReputationError::WorkerMismatch);
            },
            DisputeResolution::Split5050 => {
                // A split takes money from both sides, so it needs both: it only
                // executes as the *acceptance* of a proposal the other party made.
                require_counterparty_split_proposal(&ctx.accounts.split_proposal, escrow_key, caller)?;
            },
        }

        let amount = contract.amount;

        match resolution {
            DisputeResolution::ReleaseToWorker => {
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

                contract.status = ContractStatus::Completed;
                contract.completed_at = Clock::get()?.unix_timestamp;
            },
            DisputeResolution::RefundToEmployer => {
                // Entire vault balance (amount + rent) automatically returned to employer via `close = employer` on vault
                contract.status = ContractStatus::Cancelled;
            },
            DisputeResolution::Split5050 => {
                let worker_amount = amount / 2;
                **ctx.accounts.vault.to_account_info().try_borrow_mut_lamports()? = ctx
                    .accounts
                    .vault
                    .to_account_info()
                    .lamports()
                    .checked_sub(worker_amount)
                    .ok_or(ReputationError::Overflow)?;

                **ctx.accounts.worker.to_account_info().try_borrow_mut_lamports()? = ctx
                    .accounts
                    .worker
                    .to_account_info()
                    .lamports()
                    .checked_add(worker_amount)
                    .ok_or(ReputationError::Overflow)?;

                // Remaining vault balance (employer_amount + rent) returned to employer via `close = employer` on vault
                contract.status = ContractStatus::Completed;
                contract.completed_at = Clock::get()?.unix_timestamp;
            },
        }

        settle_split_proposal(&ctx.accounts.split_proposal, &ctx.accounts.employer, &ctx.accounts.worker)?;
        Ok(())
    }

    /// Either party proposes settling a disputed contract 50/50. Nothing moves
    /// yet: the split executes only when the *other* party accepts it by calling
    /// `resolve_dispute` / `resolve_token_dispute` with `Split5050`.
    pub fn propose_split(ctx: Context<ProposeSplit>, _contract_id: String) -> Result<()> {
        let proposal = &mut ctx.accounts.split_proposal;
        proposal.escrow_contract = ctx.accounts.escrow_contract.key();
        proposal.proposer = ctx.accounts.proposer.key();
        proposal.created_at = Clock::get()?.unix_timestamp;
        proposal.bump = ctx.bumps.split_proposal;
        Ok(())
    }

    /// The proposer withdraws an unaccepted split proposal; its rent is refunded
    /// by the `close = proposer` constraint.
    pub fn cancel_split_proposal(_ctx: Context<CancelSplitProposal>, _contract_id: String) -> Result<()> {
        Ok(())
    }

    // =========================================================================
    // SPL TOKEN ($SKR) ESCROW PROTOCOL INSTRUCTIONS
    // =========================================================================

    /// Employer creates and funds an SPL token ($SKR) escrow contract in a single transaction.
    pub fn create_and_fund_token(
        ctx: Context<CreateAndFundTokenContract>,
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
        contract.is_token = true;
        contract.token_mint = ctx.accounts.mint.key();

        let vault = &mut ctx.accounts.vault;
        vault.bump = ctx.bumps.vault;

        // Transfer SPL tokens from employer ATA to vault ATA
        let cpi_accounts = Transfer {
            from: ctx.accounts.employer_token_account.to_account_info(),
            to: ctx.accounts.vault_token_account.to_account_info(),
            authority: ctx.accounts.employer.to_account_info(),
        };
        token::transfer(
            CpiContext::new(ctx.accounts.token_program.key(), cpi_accounts),
            amount,
        )?;
        Ok(())
    }

    /// Employer releases escrow token payment to worker and writes verified on-chain review atomically.
    pub fn release_and_review_token(
        ctx: Context<ReleaseAndReviewToken>,
        contract_id: String,
        rating: u8,
    ) -> Result<()> {
        require!((1..=5).contains(&rating), ReputationError::InvalidRating);

        let contract = &mut ctx.accounts.escrow_contract;
        require!(contract.status == ContractStatus::InProgress, ReputationError::InvalidContractStatus);
        require!(contract.is_token, ReputationError::NotTokenContract);
        require!(contract.worker == ctx.accounts.worker.key(), ReputationError::WorkerMismatch);
        require!(ctx.accounts.worker_profile.worker == ctx.accounts.worker.key(), ReputationError::WorkerMismatch);

        let amount = contract.amount;
        let contract_id_bytes = contract_id.as_bytes();
        let vault_bump = contract.vault_bump;
        let seeds = &[
            b"vault",
            contract_id_bytes,
            &[vault_bump],
        ];
        let signer_seeds = &[&seeds[..]];

        // 1. Transfer SPL tokens from Vault ATA to Worker ATA
        let cpi_accounts = Transfer {
            from: ctx.accounts.vault_token_account.to_account_info(),
            to: ctx.accounts.worker_token_account.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        };
        let cpi_ctx = CpiContext::new_with_signer(
            ctx.accounts.token_program.key(),
            cpi_accounts,
            signer_seeds,
        );
        token::transfer(cpi_ctx, amount)?;

        // 2. Close the Vault ATA, refunding rent lamports to the employer
        let close_accounts = CloseAccount {
            account: ctx.accounts.vault_token_account.to_account_info(),
            destination: ctx.accounts.employer.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        };
        let close_ctx = CpiContext::new_with_signer(
            ctx.accounts.token_program.key(),
            close_accounts,
            signer_seeds,
        );
        token::close_account(close_ctx)?;

        // 3. Initialize the immutable Review PDA
        let review = &mut ctx.accounts.review;
        review.worker = ctx.accounts.worker.key();
        review.reviewer = ctx.accounts.employer.key();
        review.job_id = contract_id;
        review.rating = rating;
        review.timestamp = Clock::get()?.unix_timestamp;
        review.bump = ctx.bumps.review;

        // 4. Update worker profile aggregated reputation
        let profile = &mut ctx.accounts.worker_profile;
        profile.total_jobs = profile
            .total_jobs
            .checked_add(1)
            .ok_or(ReputationError::Overflow)?;
        profile.rating_sum = profile
            .rating_sum
            .checked_add(rating as u64)
            .ok_or(ReputationError::Overflow)?;

        // 5. Update contract status to Completed
        contract.status = ContractStatus::Completed;
        contract.completed_at = Clock::get()?.unix_timestamp;
        contract.rating = rating;
        Ok(())
    }

    /// Employer cancels a funded token contract before worker accepts. Reclaims all vault tokens.
    pub fn cancel_token_contract(ctx: Context<CancelTokenContract>, _contract_id: String) -> Result<()> {
        let contract = &mut ctx.accounts.escrow_contract;
        require!(contract.status == ContractStatus::Funded, ReputationError::InvalidContractStatus);
        require!(contract.is_token, ReputationError::NotTokenContract);

        let amount = contract.amount;
        let contract_id_bytes = _contract_id.as_bytes();
        let vault_bump = contract.vault_bump;
        let seeds = &[
            b"vault",
            contract_id_bytes,
            &[vault_bump],
        ];
        let signer_seeds = &[&seeds[..]];

        // 1. Return all SPL tokens from Vault ATA to employer ATA
        let cpi_accounts = Transfer {
            from: ctx.accounts.vault_token_account.to_account_info(),
            to: ctx.accounts.employer_token_account.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        };
        let cpi_ctx = CpiContext::new_with_signer(
            ctx.accounts.token_program.key(),
            cpi_accounts,
            signer_seeds,
        );
        token::transfer(cpi_ctx, amount)?;

        // 2. Close the Vault ATA, refunding rent lamports to the employer
        let close_accounts = CloseAccount {
            account: ctx.accounts.vault_token_account.to_account_info(),
            destination: ctx.accounts.employer.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        };
        let close_ctx = CpiContext::new_with_signer(
            ctx.accounts.token_program.key(),
            close_accounts,
            signer_seeds,
        );
        token::close_account(close_ctx)?;

        contract.status = ContractStatus::Cancelled;
        Ok(())
    }

    /// Resolves an active dispute on an SPL token ($SKR) escrow contract via mutual or unilateral settlement.
    pub fn resolve_token_dispute(
        ctx: Context<ResolveTokenDispute>,
        _contract_id: String,
        resolution: DisputeResolution,
    ) -> Result<()> {
        let escrow_key = ctx.accounts.escrow_contract.key();
        let contract = &mut ctx.accounts.escrow_contract;
        require!(contract.status == ContractStatus::Disputed, ReputationError::InvalidContractStatus);
        require!(contract.is_token, ReputationError::NotTokenContract);

        let caller = ctx.accounts.caller.key();
        require!(
            caller == contract.employer || caller == contract.worker,
            ReputationError::UnauthorizedParticipant
        );
        require!(contract.employer == ctx.accounts.employer.key(), ReputationError::UnauthorizedEmployer);
        require!(contract.worker == ctx.accounts.worker.key(), ReputationError::WorkerMismatch);

        match resolution {
            DisputeResolution::ReleaseToWorker => {
                require!(caller == contract.employer, ReputationError::UnauthorizedEmployer);
            },
            DisputeResolution::RefundToEmployer => {
                require!(caller == contract.worker, ReputationError::WorkerMismatch);
            },
            DisputeResolution::Split5050 => {
                // A split takes money from both sides, so it needs both: it only
                // executes as the *acceptance* of a proposal the other party made.
                require_counterparty_split_proposal(&ctx.accounts.split_proposal, escrow_key, caller)?;
            },
        }

        let amount = contract.amount;
        let contract_id_bytes = _contract_id.as_bytes();
        let vault_bump = contract.vault_bump;
        let seeds = &[
            b"vault",
            contract_id_bytes,
            &[vault_bump],
        ];
        let signer_seeds = &[&seeds[..]];

        match resolution {
            DisputeResolution::ReleaseToWorker => {
                let cpi_accounts = Transfer {
                    from: ctx.accounts.vault_token_account.to_account_info(),
                    to: ctx.accounts.worker_token_account.to_account_info(),
                    authority: ctx.accounts.vault.to_account_info(),
                };
                token::transfer(
                    CpiContext::new_with_signer(ctx.accounts.token_program.key(), cpi_accounts, signer_seeds),
                    amount,
                )?;
                contract.status = ContractStatus::Completed;
                contract.completed_at = Clock::get()?.unix_timestamp;
            },
            DisputeResolution::RefundToEmployer => {
                let cpi_accounts = Transfer {
                    from: ctx.accounts.vault_token_account.to_account_info(),
                    to: ctx.accounts.employer_token_account.to_account_info(),
                    authority: ctx.accounts.vault.to_account_info(),
                };
                token::transfer(
                    CpiContext::new_with_signer(ctx.accounts.token_program.key(), cpi_accounts, signer_seeds),
                    amount,
                )?;
                contract.status = ContractStatus::Cancelled;
            },
            DisputeResolution::Split5050 => {
                let worker_amount = amount / 2;
                let employer_amount = amount - worker_amount;

                let cpi_worker = Transfer {
                    from: ctx.accounts.vault_token_account.to_account_info(),
                    to: ctx.accounts.worker_token_account.to_account_info(),
                    authority: ctx.accounts.vault.to_account_info(),
                };
                token::transfer(
                    CpiContext::new_with_signer(ctx.accounts.token_program.key(), cpi_worker, signer_seeds),
                    worker_amount,
                )?;

                let cpi_employer = Transfer {
                    from: ctx.accounts.vault_token_account.to_account_info(),
                    to: ctx.accounts.employer_token_account.to_account_info(),
                    authority: ctx.accounts.vault.to_account_info(),
                };
                token::transfer(
                    CpiContext::new_with_signer(ctx.accounts.token_program.key(), cpi_employer, signer_seeds),
                    employer_amount,
                )?;

                contract.status = ContractStatus::Completed;
                contract.completed_at = Clock::get()?.unix_timestamp;
            },
        }

        // Close the Vault ATA, refunding rent lamports to employer
        let close_accounts = CloseAccount {
            account: ctx.accounts.vault_token_account.to_account_info(),
            destination: ctx.accounts.employer.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        };
        token::close_account(CpiContext::new_with_signer(ctx.accounts.token_program.key(), close_accounts, signer_seeds))?;

        settle_split_proposal(&ctx.accounts.split_proposal, &ctx.accounts.employer, &ctx.accounts.worker)?;
        Ok(())
    }

    // =========================================================================
    // PHASE 2: SEEKER GUARDIAN DISPUTE ARBITRATION & JUROR PROTOCOL
    // =========================================================================

    /// Escalate an active disputed escrow contract to a 3-juror Seeker Guardian panel.
    pub fn initialize_dispute_case(
        ctx: Context<InitializeDisputeCase>,
        contract_id: String,
        jurors: [Pubkey; 3],
    ) -> Result<()> {
        require!(JURY_ENABLED, ReputationError::JuryNotEnabled);
        require!(contract_id.len() <= MAX_CONTRACT_ID_LEN, ReputationError::ContractIdTooLong);
        require!(
            jurors[0] != jurors[1] && jurors[1] != jurors[2] && jurors[0] != jurors[2],
            ReputationError::InvalidJurorCount
        );
        let escrow = &ctx.accounts.escrow_contract;
        require!(
            jurors[0] != escrow.employer && jurors[1] != escrow.employer && jurors[2] != escrow.employer,
            ReputationError::UnauthorizedParticipant
        );
        require!(
            jurors[0] != escrow.worker && jurors[1] != escrow.worker && jurors[2] != escrow.worker,
            ReputationError::UnauthorizedParticipant
        );

        let case = &mut ctx.accounts.dispute_case;
        case.contract_id = contract_id;
        case.escrow_contract = ctx.accounts.escrow_contract.key();
        case.jurors = jurors;
        case.votes = [0, 0, 0];
        case.quorum_outcome = 0;
        case.status = DisputeCaseStatus::Voting;
        case.created_at = Clock::get()?.unix_timestamp;
        case.resolved_at = 0;
        case.bump = ctx.bumps.dispute_case;
        Ok(())
    }

    /// Assigned Guardian juror casts a binding verdict on an active dispute case.
    pub fn cast_juror_vote(
        ctx: Context<CastJurorVote>,
        _contract_id: String,
        vote: DisputeVote,
    ) -> Result<()> {
        let case = &mut ctx.accounts.dispute_case;
        require!(case.status == DisputeCaseStatus::Voting, ReputationError::DisputeCaseNotVoting);
        require!(vote != DisputeVote::None, ReputationError::InvalidRating);

        let juror_key = ctx.accounts.juror.key();
        let juror_idx = case.jurors.iter().position(|j| *j == juror_key)
            .ok_or(ReputationError::JurorNotAssigned)?;
        require!(case.votes[juror_idx] == 0, ReputationError::JurorAlreadyVoted);

        case.votes[juror_idx] = vote as u8;

        // Tally votes to evaluate 2/3 simple majority quorum
        let mut counts = [0u8; 4];
        for &v in case.votes.iter() {
            if (v as usize) < counts.len() {
                counts[v as usize] += 1;
            }
        }

        for outcome in 1..=3 {
            if counts[outcome] >= 2 {
                case.status = DisputeCaseStatus::QuorumReached;
                case.quorum_outcome = outcome as u8;
                case.resolved_at = Clock::get()?.unix_timestamp;
                break;
            }
        }

        Ok(())
    }

    /// Executes the binding ruling reached by juror quorum on a native SOL escrow.
    pub fn execute_dispute_ruling(
        ctx: Context<ExecuteDisputeRuling>,
        _contract_id: String,
    ) -> Result<()> {
        let case = &mut ctx.accounts.dispute_case;
        require!(case.status == DisputeCaseStatus::QuorumReached, ReputationError::QuorumNotReached);

        let contract = &mut ctx.accounts.escrow_contract;
        let amount = contract.amount;

        match case.quorum_outcome {
            1 => {
                // ReleaseToWorker: full escrow to worker
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

                contract.status = ContractStatus::Completed;
                contract.completed_at = Clock::get()?.unix_timestamp;
            },
            2 => {
                // RefundToEmployer: vault closes to employer, returning all funds + rent
                contract.status = ContractStatus::Cancelled;
            },
            3 => {
                // Split5050: 50% to worker, remainder (50% + rent) to employer via vault close
                let worker_amount = amount / 2;
                **ctx.accounts.vault.to_account_info().try_borrow_mut_lamports()? = ctx
                    .accounts
                    .vault
                    .to_account_info()
                    .lamports()
                    .checked_sub(worker_amount)
                    .ok_or(ReputationError::Overflow)?;

                **ctx.accounts.worker.to_account_info().try_borrow_mut_lamports()? = ctx
                    .accounts
                    .worker
                    .to_account_info()
                    .lamports()
                    .checked_add(worker_amount)
                    .ok_or(ReputationError::Overflow)?;

                contract.status = ContractStatus::Completed;
                contract.completed_at = Clock::get()?.unix_timestamp;
            },
            _ => return Err(ReputationError::QuorumNotReached.into()),
        }

        case.status = DisputeCaseStatus::Executed;
        Ok(())
    }

    /// Executes the binding ruling reached by juror quorum on an SPL token ($SKR) escrow.
    pub fn execute_token_dispute_ruling(
        ctx: Context<ExecuteTokenDisputeRuling>,
        _contract_id: String,
    ) -> Result<()> {
        let case = &mut ctx.accounts.dispute_case;
        require!(case.status == DisputeCaseStatus::QuorumReached, ReputationError::QuorumNotReached);

        let contract = &mut ctx.accounts.escrow_contract;
        let amount = contract.amount;
        let contract_id_bytes = _contract_id.as_bytes();
        let vault_bump = contract.vault_bump;
        let seeds = &[
            b"vault",
            contract_id_bytes,
            &[vault_bump],
        ];
        let signer_seeds = &[&seeds[..]];

        match case.quorum_outcome {
            1 => {
                let cpi_accounts = Transfer {
                    from: ctx.accounts.vault_token_account.to_account_info(),
                    to: ctx.accounts.worker_token_account.to_account_info(),
                    authority: ctx.accounts.vault.to_account_info(),
                };
                token::transfer(
                    CpiContext::new_with_signer(ctx.accounts.token_program.key(), cpi_accounts, signer_seeds),
                    amount,
                )?;
                contract.status = ContractStatus::Completed;
                contract.completed_at = Clock::get()?.unix_timestamp;
            },
            2 => {
                let cpi_accounts = Transfer {
                    from: ctx.accounts.vault_token_account.to_account_info(),
                    to: ctx.accounts.employer_token_account.to_account_info(),
                    authority: ctx.accounts.vault.to_account_info(),
                };
                token::transfer(
                    CpiContext::new_with_signer(ctx.accounts.token_program.key(), cpi_accounts, signer_seeds),
                    amount,
                )?;
                contract.status = ContractStatus::Cancelled;
            },
            3 => {
                let worker_amount = amount / 2;
                let employer_amount = amount - worker_amount;

                let cpi_worker = Transfer {
                    from: ctx.accounts.vault_token_account.to_account_info(),
                    to: ctx.accounts.worker_token_account.to_account_info(),
                    authority: ctx.accounts.vault.to_account_info(),
                };
                token::transfer(
                    CpiContext::new_with_signer(ctx.accounts.token_program.key(), cpi_worker, signer_seeds),
                    worker_amount,
                )?;

                let cpi_employer = Transfer {
                    from: ctx.accounts.vault_token_account.to_account_info(),
                    to: ctx.accounts.employer_token_account.to_account_info(),
                    authority: ctx.accounts.vault.to_account_info(),
                };
                token::transfer(
                    CpiContext::new_with_signer(ctx.accounts.token_program.key(), cpi_employer, signer_seeds),
                    employer_amount,
                )?;

                contract.status = ContractStatus::Completed;
                contract.completed_at = Clock::get()?.unix_timestamp;
            },
            _ => return Err(ReputationError::QuorumNotReached.into()),
        }

        // Close the Vault ATA, refunding rent lamports to employer
        let close_accounts = CloseAccount {
            account: ctx.accounts.vault_token_account.to_account_info(),
            destination: ctx.accounts.employer.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        };
        token::close_account(CpiContext::new_with_signer(ctx.accounts.token_program.key(), close_accounts, signer_seeds))?;

        case.status = DisputeCaseStatus::Executed;
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

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq, Debug)]
pub enum DisputeResolution {
    ReleaseToWorker,
    RefundToEmployer,
    Split5050,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq, Debug)]
pub enum DisputeCaseStatus {
    Voting,
    QuorumReached,
    Executed,
}

#[derive(AnchorSerialize, AnchorDeserialize, Clone, Copy, PartialEq, Eq, Debug)]
pub enum DisputeVote {
    None,
    ReleaseToWorker,
    RefundToEmployer,
    Split5050,
}

/// PDA seeds: [b"escrow", contract_id.as_bytes()]
#[account]
pub struct EscrowContract {
    pub contract_id: String,       // 4 + MAX_CONTRACT_ID_LEN
    pub employer: Pubkey,          // 32
    pub worker: Pubkey,            // 32
    pub amount: u64,               // 8 (lamports or token base units)
    pub terms_hash: [u8; 32],      // 32 (SHA-256)
    pub status: ContractStatus,    // 1
    pub deadline: i64,             // 8
    pub created_at: i64,           // 8
    pub funded_at: i64,            // 8
    pub completed_at: i64,         // 8
    pub rating: u8,                // 1
    pub bump: u8,                  // 1
    pub vault_bump: u8,            // 1
    pub is_token: bool,            // 1 (false = SOL, true = SPL Token)
    pub token_mint: Pubkey,        // 32 (Pubkey::default() if SOL, mint address if token)
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
        + 1
        + 1
        + 32;
}

/// PDA seeds: [b"vault", contract_id.as_bytes()]
#[account]
pub struct EscrowVault {
    pub bump: u8,
}

impl EscrowVault {
    pub const SPACE: usize = 8 + 1;
}

/// PDA seeds: [b"dispute_case", contract_id.as_bytes()]
#[account]
pub struct DisputeCase {
    pub contract_id: String,       // 4 + MAX_CONTRACT_ID_LEN
    pub escrow_contract: Pubkey,   // 32
    pub jurors: [Pubkey; 3],       // 32 * 3 = 96
    pub votes: [u8; 3],            // 3 (0=None, 1=Release, 2=Refund, 3=Split)
    pub quorum_outcome: u8,        // 1 (0=None, 1=Release, 2=Refund, 3=Split)
    pub status: DisputeCaseStatus,  // 1
    pub created_at: i64,           // 8
    pub resolved_at: i64,          // 8
    pub bump: u8,                  // 1
}

impl DisputeCase {
    pub const SPACE: usize = 8
        + (4 + MAX_CONTRACT_ID_LEN)
        + 32
        + 96
        + 3
        + 1
        + 1
        + 8
        + 8
        + 1;
}

// =============================================================================
// ERROR CODES
// =============================================================================

/// PDA seeds: [b"split_proposal", contract_id.as_bytes()]
///
/// An open offer by one party to settle a disputed contract 50/50. At most one
/// exists per contract; it is closed when the dispute is settled any way.
#[account]
pub struct SplitProposal {
    pub escrow_contract: Pubkey, // 32
    pub proposer: Pubkey,        // 32
    pub created_at: i64,         // 8
    pub bump: u8,                // 1
}

impl SplitProposal {
    pub const SPACE: usize = 8 + 32 + 32 + 8 + 1;
}

/// Reads the split proposal at `info` if it exists and belongs to this program.
fn read_split_proposal(info: &AccountInfo) -> Result<Option<SplitProposal>> {
    if *info.owner != crate::ID || info.data_is_empty() {
        return Ok(None);
    }
    let data = info.try_borrow_data()?;
    Ok(Some(SplitProposal::try_deserialize(&mut &data[..])?))
}

/// Allows a 50/50 split only as acceptance of the counterparty's proposal for
/// this exact escrow. The caller's own proposal does not count.
fn require_counterparty_split_proposal(info: &AccountInfo, escrow_key: Pubkey, caller: Pubkey) -> Result<()> {
    match read_split_proposal(info)? {
        Some(p) if p.escrow_contract == escrow_key && p.proposer != caller => Ok(()),
        _ => err!(ReputationError::SplitNeedsCounterpartyConsent),
    }
}

/// Closes an open split proposal, if any, refunding its rent to the proposer.
/// Called whenever a dispute is settled so no proposal is left stranded.
fn settle_split_proposal<'info>(
    info: &AccountInfo<'info>,
    employer: &AccountInfo<'info>,
    worker: &AccountInfo<'info>,
) -> Result<()> {
    let Some(proposal) = read_split_proposal(info)? else {
        return Ok(());
    };
    let destination = if proposal.proposer == employer.key() {
        employer
    } else if proposal.proposer == worker.key() {
        worker
    } else {
        return err!(ReputationError::UnauthorizedParticipant);
    };

    let rent = info.lamports();
    **destination.try_borrow_mut_lamports()? = destination
        .lamports()
        .checked_add(rent)
        .ok_or(ReputationError::Overflow)?;
    **info.try_borrow_mut_lamports()? = 0;
    info.assign(&system_program::ID);
    info.resize(0)?;
    Ok(())
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
    #[msg("Invalid token mint.")]
    MintMismatch,
    #[msg("Contract is not an SPL token escrow.")]
    NotTokenContract,
    #[msg("Contract is an SPL token escrow. Use token instructions.")]
    TokenContract,
    #[msg("Signer is not an assigned juror on this dispute case.")]
    JurorNotAssigned,
    #[msg("This juror has already cast a vote on this dispute case.")]
    JurorAlreadyVoted,
    #[msg("Dispute case is not open for voting.")]
    DisputeCaseNotVoting,
    #[msg("Dispute quorum has not been reached yet.")]
    QuorumNotReached,
    #[msg("Three distinct jurors are required.")]
    InvalidJurorCount,
    #[msg("Escrow contract is not in Disputed status.")]
    ContractNotDisputed,
    #[msg("Dispute case has already been executed.")]
    DisputeAlreadyExecuted,
    #[msg("A 50/50 split needs the other party to have proposed it first.")]
    SplitNeedsCounterpartyConsent,
    #[msg("Juror arbitration is not enabled yet.")]
    JuryNotEnabled,
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

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct ResolveDispute<'info> {
    #[account(mut)]
    pub caller: Signer<'info>,
    #[account(
        mut,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        has_one = employer @ ReputationError::UnauthorizedEmployer,
        has_one = worker @ ReputationError::WorkerMismatch,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
    #[account(
        mut,
        close = employer,
        seeds = [b"vault", contract_id.as_bytes()],
        bump = escrow_contract.vault_bump,
    )]
    pub vault: Account<'info, EscrowVault>,
    /// CHECK: Worker receives payment on Release or Split.
    #[account(mut)]
    pub worker: UncheckedAccount<'info>,
    /// CHECK: Employer receives refund or split.
    #[account(mut)]
    pub employer: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
    /// CHECK: The contract's split-proposal PDA. It usually does not exist; it
    /// is only read when it is owned by this program, and is closed (rent back
    /// to its proposer) whenever the dispute is settled. See
    /// `require_counterparty_split_proposal` and `settle_split_proposal`.
    #[account(mut, seeds = [b"split_proposal", contract_id.as_bytes()], bump)]
    pub split_proposal: UncheckedAccount<'info>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct CreateAndFundTokenContract<'info> {
    #[account(mut)]
    pub employer: Signer<'info>,
    pub mint: Account<'info, Mint>,
    #[account(
        mut,
        constraint = employer_token_account.mint == mint.key() @ ReputationError::MintMismatch,
        constraint = employer_token_account.owner == employer.key() @ ReputationError::UnauthorizedEmployer,
    )]
    pub employer_token_account: Account<'info, TokenAccount>,
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
    #[account(
        init,
        payer = employer,
        associated_token::mint = mint,
        associated_token::authority = vault,
    )]
    pub vault_token_account: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct ReleaseAndReviewToken<'info> {
    #[account(mut)]
    pub employer: Signer<'info>,
    #[account(
        mut,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        has_one = employer @ ReputationError::UnauthorizedEmployer,
        constraint = escrow_contract.is_token @ ReputationError::NotTokenContract,
        constraint = escrow_contract.token_mint == mint.key() @ ReputationError::MintMismatch,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
    pub mint: Account<'info, Mint>,
    #[account(
        mut,
        close = employer,
        seeds = [b"vault", contract_id.as_bytes()],
        bump = escrow_contract.vault_bump,
    )]
    pub vault: Account<'info, EscrowVault>,
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = vault,
    )]
    pub vault_token_account: Account<'info, TokenAccount>,
    /// CHECK: Recipient of the escrowed tokens and subject of review; validated against escrow_contract.worker
    #[account(mut)]
    pub worker: UncheckedAccount<'info>,
    #[account(
        mut,
        constraint = worker_token_account.mint == mint.key() @ ReputationError::MintMismatch,
        constraint = worker_token_account.owner == worker.key() @ ReputationError::WorkerMismatch,
    )]
    pub worker_token_account: Account<'info, TokenAccount>,
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
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct CancelTokenContract<'info> {
    #[account(mut)]
    pub employer: Signer<'info>,
    #[account(
        mut,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        has_one = employer @ ReputationError::UnauthorizedEmployer,
        constraint = escrow_contract.is_token @ ReputationError::NotTokenContract,
        constraint = escrow_contract.token_mint == mint.key() @ ReputationError::MintMismatch,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
    pub mint: Account<'info, Mint>,
    #[account(
        mut,
        close = employer,
        seeds = [b"vault", contract_id.as_bytes()],
        bump = escrow_contract.vault_bump,
    )]
    pub vault: Account<'info, EscrowVault>,
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = vault,
    )]
    pub vault_token_account: Account<'info, TokenAccount>,
    #[account(
        mut,
        constraint = employer_token_account.mint == mint.key() @ ReputationError::MintMismatch,
        constraint = employer_token_account.owner == employer.key() @ ReputationError::UnauthorizedEmployer,
    )]
    pub employer_token_account: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct ResolveTokenDispute<'info> {
    #[account(mut)]
    pub caller: Signer<'info>,
    #[account(
        mut,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        has_one = employer @ ReputationError::UnauthorizedEmployer,
        has_one = worker @ ReputationError::WorkerMismatch,
        constraint = escrow_contract.is_token @ ReputationError::NotTokenContract,
        constraint = escrow_contract.token_mint == mint.key() @ ReputationError::MintMismatch,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
    pub mint: Account<'info, Mint>,
    #[account(
        mut,
        close = employer,
        seeds = [b"vault", contract_id.as_bytes()],
        bump = escrow_contract.vault_bump,
    )]
    pub vault: Account<'info, EscrowVault>,
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = vault,
    )]
    pub vault_token_account: Account<'info, TokenAccount>,
    /// CHECK: Worker receives tokens on Release or Split. Validated by has_one.
    #[account(mut)]
    pub worker: UncheckedAccount<'info>,
    #[account(
        mut,
        constraint = worker_token_account.mint == mint.key() @ ReputationError::MintMismatch,
        constraint = worker_token_account.owner == worker.key() @ ReputationError::WorkerMismatch,
    )]
    pub worker_token_account: Account<'info, TokenAccount>,
    /// CHECK: Employer receives tokens on Refund or Split, and rent refund. Validated by has_one.
    #[account(mut)]
    pub employer: UncheckedAccount<'info>,
    #[account(
        mut,
        constraint = employer_token_account.mint == mint.key() @ ReputationError::MintMismatch,
        constraint = employer_token_account.owner == employer.key() @ ReputationError::UnauthorizedEmployer,
    )]
    pub employer_token_account: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
    /// CHECK: The contract's split-proposal PDA. It usually does not exist; it
    /// is only read when it is owned by this program, and is closed (rent back
    /// to its proposer) whenever the dispute is settled. See
    /// `require_counterparty_split_proposal` and `settle_split_proposal`.
    #[account(mut, seeds = [b"split_proposal", contract_id.as_bytes()], bump)]
    pub split_proposal: UncheckedAccount<'info>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct ProposeSplit<'info> {
    #[account(mut)]
    pub proposer: Signer<'info>,
    #[account(
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        constraint = escrow_contract.status == ContractStatus::Disputed @ ReputationError::ContractNotDisputed,
        constraint = proposer.key() == escrow_contract.employer || proposer.key() == escrow_contract.worker @ ReputationError::UnauthorizedParticipant,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
    #[account(
        init,
        payer = proposer,
        space = SplitProposal::SPACE,
        seeds = [b"split_proposal", contract_id.as_bytes()],
        bump,
    )]
    pub split_proposal: Account<'info, SplitProposal>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct CancelSplitProposal<'info> {
    #[account(mut)]
    pub proposer: Signer<'info>,
    #[account(
        mut,
        seeds = [b"split_proposal", contract_id.as_bytes()],
        bump = split_proposal.bump,
        has_one = proposer @ ReputationError::UnauthorizedParticipant,
        close = proposer,
    )]
    pub split_proposal: Account<'info, SplitProposal>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct InitializeDisputeCase<'info> {
    #[account(mut)]
    pub caller: Signer<'info>,
    #[account(
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        constraint = escrow_contract.status == ContractStatus::Disputed @ ReputationError::ContractNotDisputed,
        constraint = caller.key() == escrow_contract.employer || caller.key() == escrow_contract.worker @ ReputationError::UnauthorizedParticipant,
    )]
    pub escrow_contract: Account<'info, EscrowContract>,
    #[account(
        init,
        payer = caller,
        space = DisputeCase::SPACE,
        seeds = [b"dispute_case", contract_id.as_bytes()],
        bump,
    )]
    pub dispute_case: Account<'info, DisputeCase>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct CastJurorVote<'info> {
    #[account(mut)]
    pub juror: Signer<'info>,
    #[account(
        mut,
        seeds = [b"dispute_case", contract_id.as_bytes()],
        bump = dispute_case.bump,
    )]
    pub dispute_case: Account<'info, DisputeCase>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct ExecuteDisputeRuling<'info> {
    #[account(mut)]
    pub caller: Signer<'info>,
    #[account(
        mut,
        seeds = [b"dispute_case", contract_id.as_bytes()],
        bump = dispute_case.bump,
    )]
    pub dispute_case: Box<Account<'info, DisputeCase>>,
    #[account(
        mut,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        has_one = employer @ ReputationError::UnauthorizedEmployer,
        has_one = worker @ ReputationError::WorkerMismatch,
        constraint = !escrow_contract.is_token @ ReputationError::TokenContract,
        constraint = escrow_contract.status == ContractStatus::Disputed @ ReputationError::InvalidContractStatus,
    )]
    pub escrow_contract: Box<Account<'info, EscrowContract>>,
    #[account(
        mut,
        close = employer,
        seeds = [b"vault", contract_id.as_bytes()],
        bump = escrow_contract.vault_bump,
    )]
    pub vault: Account<'info, EscrowVault>,
    /// CHECK: Worker receives SOL on Release or Split. Validated by has_one on escrow_contract.
    #[account(mut)]
    pub worker: UncheckedAccount<'info>,
    /// CHECK: Employer receives SOL on Refund or Split, and rent refund. Validated by has_one.
    #[account(mut)]
    pub employer: UncheckedAccount<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(contract_id: String)]
pub struct ExecuteTokenDisputeRuling<'info> {
    #[account(mut)]
    pub caller: Signer<'info>,
    #[account(
        mut,
        seeds = [b"dispute_case", contract_id.as_bytes()],
        bump = dispute_case.bump,
    )]
    pub dispute_case: Box<Account<'info, DisputeCase>>,
    #[account(
        mut,
        seeds = [b"escrow", contract_id.as_bytes()],
        bump = escrow_contract.bump,
        has_one = employer @ ReputationError::UnauthorizedEmployer,
        has_one = worker @ ReputationError::WorkerMismatch,
        constraint = escrow_contract.is_token @ ReputationError::NotTokenContract,
        constraint = escrow_contract.token_mint == mint.key() @ ReputationError::MintMismatch,
        constraint = escrow_contract.status == ContractStatus::Disputed @ ReputationError::InvalidContractStatus,
    )]
    pub escrow_contract: Box<Account<'info, EscrowContract>>,
    pub mint: Account<'info, Mint>,
    #[account(
        mut,
        close = employer,
        seeds = [b"vault", contract_id.as_bytes()],
        bump = escrow_contract.vault_bump,
    )]
    pub vault: Account<'info, EscrowVault>,
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = vault,
    )]
    pub vault_token_account: Box<Account<'info, TokenAccount>>,
    /// CHECK: Worker receives tokens on Release or Split. Validated by has_one.
    #[account(mut)]
    pub worker: UncheckedAccount<'info>,
    #[account(
        mut,
        constraint = worker_token_account.mint == mint.key() @ ReputationError::MintMismatch,
        constraint = worker_token_account.owner == worker.key() @ ReputationError::WorkerMismatch,
    )]
    pub worker_token_account: Box<Account<'info, TokenAccount>>,
    /// CHECK: Employer receives tokens on Refund or Split, and rent refund. Validated by has_one.
    #[account(mut)]
    pub employer: UncheckedAccount<'info>,
    #[account(
        mut,
        constraint = employer_token_account.mint == mint.key() @ ReputationError::MintMismatch,
        constraint = employer_token_account.owner == employer.key() @ ReputationError::UnauthorizedEmployer,
    )]
    pub employer_token_account: Box<Account<'info, TokenAccount>>,
    pub token_program: Program<'info, Token>,
}

