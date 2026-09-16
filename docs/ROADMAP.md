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

## Phase E2 — App: Contract Service Layer & Drift Schema (Week 2: Sept 22–28)

**Goal:** The Flutter app can create, view, fund, accept, release, and cancel contracts via MWA.

### Drift schema update

- [ ] `EscrowContracts` table: mirrors on-chain fields + `syncedAt` + local-only `localStatus` for optimistic UI
- [ ] `ContractHistory` table: local log of status transitions with timestamps (for the contract detail screen timeline)
- [ ] Migration from existing schema (preserve `WorkerProfiles`, `Reviews`, `DraftReviews`)
- [ ] Run `build_runner` to regenerate Drift code

### New service: `ContractService`

- [ ] `createContract(worker, amount, termsHash, deadline)` — builds + signs `create_contract` instruction via MWA
- [ ] `fundContract(contractId)` — builds + signs `fund_contract` via MWA
- [ ] `acceptContract(contractId)` — builds + signs `accept_contract` via MWA
- [ ] `releaseAndReview(contractId, rating)` — builds + signs `release_and_review` via MWA
- [ ] `cancelContract(contractId)` — builds + signs `cancel_contract` via MWA
- [ ] `getContract(contractId)` — reads EscrowContract PDA from chain
- [ ] `getContractsForUser(pubkey)` — reads all contracts where user is employer or worker (via `getProgramAccounts` + `memcmp`)

### New Riverpod providers

- [ ] `contractListProvider` — watches user's contracts (as employer + as worker)
- [ ] `contractDetailProvider(contractId)` — single contract state
- [ ] `createContractProvider` — form state for contract creation

### ProgramInstructions update

- [ ] Static methods for each new instruction: `createContract()`, `fundContract()`, `acceptContract()`, `releaseAndReview()`, `cancelContract()`, `raiseDispute()`
- [ ] Correct account metas and Borsh-encoded data for each
- [ ] PDA derivation helpers for EscrowContract and Vault PDAs

**Done when:** A full contract lifecycle (create → fund → accept → release) works on a physical device via MWA, confirmed by reading the resulting on-chain state back from devnet.

---

## Phase E3 — App: Contract UI Screens (Week 2–3: Sept 25–Oct 1)

**Goal:** Users can navigate the full contract flow through purpose-built screens.

### New screens

- [ ] **Contract List** — shows all contracts where the connected wallet is employer or worker. Tabs or filters: Active / Completed / Cancelled. Each card shows: counterparty address, amount, status badge, deadline (if set)
- [ ] **Create Contract** — form: worker address (paste or QR scan), amount (SOL), deadline (optional), terms (optional text → hashed client-side). Preview before signing. Clear cost breakdown (amount + rent + tx fee)
- [ ] **Contract Detail** — shows full contract state, status timeline, action buttons depending on role and status:
  - Employer on `Created`: Fund / Cancel
  - Employer on `Funded`: Cancel (if worker hasn't accepted) / Wait
  - Worker on `Funded`: Accept / Decline
  - Employer on `InProgress`: Release & Rate / Raise Dispute
  - Worker on `InProgress`: Raise Dispute
  - Any on `Completed`: View review + payment confirmation
  - Any on `Cancelled`: View refund confirmation
- [ ] **Contract Share** — after creation, show QR code and/or copyable contract ID for sharing with the counterparty

### Navigation updates

- [ ] Bottom nav: add Contracts tab (alongside existing Profile, Look Up, Submit Review, Settings)
- [ ] My Profile: show "X contracts completed" alongside the existing reputation stats
- [ ] Connect Wallet screen: after connection, navigate to Contract List (the new home) instead of My Profile

### UX polish items (from JUDGING_PLAN.md)

- [ ] In-app Devnet network guidance on the connect flow
- [ ] "Switch back to ClockIn" hint after MWA handoff
- [ ] `HapticFeedback.lightImpact()` on star selection and successful actions
- [ ] Replace default Flutter launcher icon
- [ ] Normalize refresh affordance across all screens

**Done when:** A judge can install the app, connect a Phantom wallet, create a contract, share it with a second device, have it accepted and completed, and see the resulting review on both profiles.

---

## Phase E4 — Hardening, Demo, Submission (Week 3: Oct 1–8)

**Goal:** A polished, submission-ready build with a compelling demo.

### Demo preparation

- [ ] Seed devnet with 3–5 completed contracts with realistic-looking data so the app isn't empty for judges
- [ ] Record a demo video showing the full flow: two devices, a deal negotiated "on X" (screenshotted DM), contract created, funded, accepted, completed with rating, review appears on worker's profile. 60–90 seconds
- [ ] Test the full flow cold: fresh install, fresh wallet, connect, create contract, complete it — time the whole thing, note any friction

### Documentation

- [ ] Rewrite `README.md` — lead with the escrow-linked-reputation hook, not generic "portable reputation." Include:
  - One-sentence pitch: "Lock funds. Do the work. Get paid and reviewed — atomically."
  - Architecture diagram (from ARCHITECTURE.md)
  - How to run it (APK install + wallet setup + Devnet config)
  - Known limitations (honestly stated: SOL-only, no automated dispute resolution, devnet-only)
  - What's next (multi-milestone, SPL tokens, arbitration DAO — from ARCHITECTURE.md's Non-goals)
- [ ] Update `PROGRAM_SPEC.md` with the new escrow instructions
- [ ] Update `APP_SPEC.md` with the new screens and service layer
- [ ] Ensure JUDGING_PLAN.md items are addressed or explicitly deferred with reasoning

### Submission

- [ ] Re-check hackathon submission mechanics at https://solanamobile.radiant.nexus/
- [ ] Prepare required assets: demo video, screenshots, description, APK or repo link
- [ ] Final `flutter build apk --release` and test the release build on-device
- [ ] Submit before Oct 8 deadline

### Stretch goals (only if time permits)

- [ ] QR code scanning for worker address input (reduces the manual-paste friction)
- [ ] Basic success animation on contract completion (scale/fade or lightweight confetti)
- [ ] Offline draft contracts (create contract terms while offline, sign when connected)
- [ ] dApp Store readiness (Seeker-specific distribution angle)

**Done when:** Submitted to the hackathon with a working demo video, a release APK, and documentation that honestly represents what's built and what's next.

---

## Risk register

| Risk | Impact | Mitigation |
|---|---|---|
| Anchor program changes break existing `register_worker`/`submit_review` | High — lose verified working code | Add new instructions alongside existing ones, don't modify existing account structs. Deploy and test existing tests still pass before adding new ones |
| MWA signing still broken (the current "wallet authorization declined" issue) | High — can't demo the app | Debug this FIRST in Phase E1 before writing any new program code. It blocks all on-device testing |
| CPI transfer from Vault PDA is complex / buggy | Medium — the atomic release_and_review is the hardest instruction | Write this instruction first, test it most thoroughly. Have a fallback: separate release + review instructions if atomic fails |
| Scope creep on UI polish | Medium — too many screens, not enough time | Contract List + Create + Detail are the minimum. Share screen is stretch. Don't build anything not in this roadmap |
| Devnet instability / rate limiting | Low-Medium | Fund the deployer wallet well ahead of deadline. Use `_signAndSendWithRetry` for blockhash races |
