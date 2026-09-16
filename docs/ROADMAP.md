# Roadmap

**Deadline: October 8, 2026 (~3 weeks from Sept 16).** Scope has changed: ClockIn is now a **P2P Work Contract & Escrow Protocol**, not a standalone reputation app. The reputation system (`WorkerProfile` + `Review`) is preserved as the foundation — the escrow layer wraps around it, generating reviews atomically at settlement. Everything already built (10/10 Anchor tests, MWA integration, Drift schema, all 5 screens) is preserved and extended, not thrown away.

Phases are compressed and resequenced for the escrow pivot. Completed phases from the original roadmap are collapsed into a single "Foundation" section.

---

## Foundation — Already Complete ✅

Everything from the original Phases 0–6 that still applies after the pivot. Not re-listing every checkbox — see git history for details.

**Anchor program (deployed to devnet):**
- [x] `register_worker` + `submit_review` implemented, tested (10/10 TS tests), deployed at `FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9`.
- [x] `WorkerProfile` + `Review` PDA model working on-chain.
- [x] Build toolchain figured out (`cargo build-sbf --arch v1`, `anchor test --skip-build --validator legacy`).

**Flutter app (running on physical device):**
- [x] MWA wallet connection working end-to-end (Phantom + Solflare, Samsung Galaxy A51).
- [x] `register_worker` signed via MWA and confirmed on devnet.
- [x] Full UI: Connect Wallet, My Profile, Look Up, Submit Review, Settings screens.
- [x] Riverpod state management, typed error handling (`ReputationException`/`ReputationErrorKind`).
- [x] Drift local cache with background sync and "Synced Xm ago" transparency.
- [x] `ReputationService` + `WalletAdapter` + `ProgramInstructions` wired up.

**Known issues carrying forward:**
- [ ] MWA transaction signing getting "wallet authorization declined" — placeholder signature fix applied but not yet verified on-device.
- [ ] Wallets don't reliably return focus to ClockIn after MWA flows (wallet-side behavior, can't fix from dApp side).
- [ ] No in-app guidance for "set your wallet to Devnet" — highest-priority UX fix.

---

## Phase E1 — Escrow Program: Accounts & Instructions (Week 1: Sept 16–22) ✅ Complete

**Goal:** The Anchor program supports the full escrow contract lifecycle on a local validator and Solana Devnet, with comprehensive tests.

### Accounts to add

- [x] `EscrowContract` PDA — `[b"escrow", contract_id.as_bytes()]`
  - Fields: `contract_id`, `employer`, `worker`, `amount`, `terms_hash`, `status` (enum: Created/Funded/InProgress/Completed/Disputed/Cancelled), `deadline`, `created_at`, `funded_at`, `completed_at`, `rating`, `bump`, `vault_bump`
- [x] Vault PDA — `[b"vault", contract_id.as_bytes()]` — system-owned lamport holder, program-controlled via PDA authority

### Instructions to implement

- [x] `create_contract(contract_id, worker, amount, terms_hash, deadline)` — employer creates the EscrowContract PDA, status = `Created`
- [x] `fund_contract(contract_id)` — employer transfers SOL to Vault PDA, status → `Funded`
- [x] `create_and_fund(contract_id, worker, amount, terms_hash, deadline)` — convenience single-tx creation + funding
- [x] `accept_contract(contract_id)` — worker accepts, status → `InProgress`
- [x] `release_and_review(contract_id, rating)` — **core atomic instruction**: transfers Vault SOL → worker, creates `Review` PDA, updates `WorkerProfile` aggregates, status → `Completed`
- [x] `cancel_contract(contract_id)` — employer reclaims vault SOL, status → `Cancelled`
- [x] `raise_dispute(contract_id)` — either party can raise, status → `Disputed`

### Tests to write

- [x] Happy path: create → fund → accept → release_and_review → verify Review PDA exists + WorkerProfile updated + worker received SOL
- [x] Cancel before acceptance: create → fund → cancel → verify employer got SOL back
- [x] Cancel after acceptance fails: create → fund → accept → cancel should error
- [x] Double-fund fails: fund → fund should error
- [x] Wrong signer tests: non-employer can't fund/cancel/release, non-worker can't accept
- [x] Invalid rating on release (0 and 6)
- [x] Dispute: raise_dispute on InProgress contract succeeds; raise_dispute on non-InProgress fails

### Devnet redeploy & live verification

- [x] Build with `cargo build-sbf --arch v1`, redeploy to devnet at `FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9` (slot 499476909, size 293,736 bytes)
- [x] Verified full on-chain lifecycle cycle on Devnet via automated script (`program/scripts/verify_devnet_lifecycle.ts`):
  - Created & funded contract `ctr-mu4o1bhi` ([tx](https://explorer.solana.com/tx/2tvjD8XQezFBbzQXyD2VtR5vzae2ynLdCs6XLb4hAkyEqRbFGr5PexYtNPoi8xSojktbbLA9rSmdib7DUNSyZ2TT?cluster=devnet))
  - Worker accepted contract ([tx](https://explorer.solana.com/tx/3r7Uy2WgmAqPWE6PebJr8pQGWyrnMpNR7FCSnzqYbeq51CvERCB5WjJEA7WFvGxk6qj4TDiaVZem5yc4h58X4HJo?cluster=devnet))
  - Employer atomic release & 5-star review ([tx](https://explorer.solana.com/tx/3MrtD2X6LNpoinCic5rhcQRuCRnXdjF9FYrVDT7k6ES51zZQTYCymwL79UPF2boqJ7G1sjb525815Uu6kk6TjF7j?cluster=devnet))
  - Verified WorkerProfile and Review PDAs on Solana Devnet explorer

**Done when:** All tests pass locally and full contract lifecycle confirmed on devnet. ✅

---

## Phase E2 — App: Contract Service Layer & Drift Schema (Week 2: Sept 22–28) ✅ Complete

**Goal:** The Flutter app can create, view, fund, accept, release, and cancel contracts via MWA.

### Drift schema update

- [x] `EscrowContracts` table: mirrors on-chain fields + `syncedAt` (Drift schema v3)
- [x] Preserved existing tables (`WorkerProfiles`, `Reviews`, `DraftReviews`, `RecentLookups`)
- [x] Code generation executed via `drift_dev` / `build_runner`
- [x] 16 in-memory Drift unit and repository tests passing

### Service layer & repositories

- [x] `ContractService` implementing instruction serialization, account meta generation, and RPC deserialization for all 7 escrow instructions
- [x] `ContractRepository` bridging on-chain state and reactive Drift SQLite database
- [x] Riverpod providers: `myContractsProvider`, `contractDetailProvider`, `walletStateProvider`

---

## Phase E3 — App: Contract UI Screens (Week 2–3: Sept 25–Oct 1) ✅ Complete

**Goal:** Users can navigate the full contract flow through purpose-built screens.

### Screens implemented

- [x] **Contract List** (`ContractsListScreen`) — metric cards (Active, Total SOL Locked, Completed) and segmented filtering (*All*, *As Employer*, *As Worker*)
- [x] **Create Contract** (`CreateContractScreen`) — worker address validation, SOL input, client-side SHA-256 terms hashing, deadline picker, fee breakdown, MWA signing
- [x] **Contract Detail** (`ContractDetailScreen`) — interactive state timeline with contextual role actions: Fund, Cancel, Accept, Release & Rate, Raise Dispute
- [x] **Contract Share** (`ContractShareScreen`) — QR code generation (`qr_flutter`) and clipboard copy
- [x] **Release & Review Modal** (`ReleaseAndReviewModal`) — atomic settlement modal with 1–5 star rating and non-reversible confirmation

### Navigation & UX polish

- [x] Bottom `NavigationBar` updated with Contracts as primary home tab
- [x] In-app Devnet network guidance banner & modal (`DevnetSetupSheet`)
- [x] "Switch back to ClockIn" hint during/after MWA handoff
- [x] Tactile `HapticFeedback` on star ratings, release actions, and filter tabs
- [x] Offline draft reviews recovery bottom sheet and form restoration in `SubmitReviewScreen`
- [x] Replaced default Flutter launcher icon with ClockIn brand mark across all Android densities

---

## Phase E4 — Hardening, Demo, Submission (Week 3: Oct 1–8) 🟢 Demo Ready

**Goal:** A polished, submission-ready build with a compelling demo.

### Demo preparation

- [x] Seed devnet with realistic multi-party contracts across all lifecycle states (`program/scripts/seed_devnet_contracts.ts`)
- [x] Verified full on-chain escrow lifecycle on Solana Devnet with transaction explorer signatures
- [x] 60–90 second judging demo walkthrough script prepared in `docs/JUDGING_PLAN.md`
- [x] Full test suite passing: 22 Anchor integration tests + 16 Flutter repository and widget tests
- [x] Production debug APK verified and built (`build/app/outputs/flutter-apk/app-debug.apk`)

### Documentation

- [x] Overhauled `README.md` leading with the P2P Work Contract & Escrow Protocol pitch, architecture diagram, and setup guide
- [x] Updated `PROGRAM_SPEC.md` with the 7 escrow instructions, accounts, and error codes
- [x] Updated `APP_SPEC.md` with the new screens, service layer, and Drift schema
- [x] Updated `JUDGING_PLAN.md` marking Novelty, Stickiness, and UX criteria locked in

### Submission Checklist

- [ ] Record 60–90 second video demo following the walkthrough script
- [ ] Upload final release APK (`flutter build apk --release`)
- [ ] Submit to [CLOCK IN Hackathon portal](https://solanamobile.radiant.nexus/) before Oct 8 deadline

---

## Risk register

| Risk | Impact | Mitigation |
|---|---|---|
| Anchor program changes break existing `register_worker`/`submit_review` | High — lose verified working code | Add new instructions alongside existing ones, don't modify existing account structs. Deploy and test existing tests still pass before adding new ones |
| MWA signing still broken (the current "wallet authorization declined" issue) | High — can't demo the app | Debug this FIRST in Phase E1 before writing any new program code. It blocks all on-device testing |
| CPI transfer from Vault PDA is complex / buggy | Medium — the atomic release_and_review is the hardest instruction | Write this instruction first, test it most thoroughly. Have a fallback: separate release + review instructions if atomic fails |
| Scope creep on UI polish | Medium — too many screens, not enough time | Contract List + Create + Detail are the minimum. Share screen is stretch. Don't build anything not in this roadmap |
| Devnet instability / rate limiting | Low-Medium | Fund the deployer wallet well ahead of deadline. Use `_signAndSendWithRetry` for blockhash races |
