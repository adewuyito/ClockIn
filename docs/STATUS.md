# What works today, and what is planned

This page separates what ClockIn does now from what is built but switched off and what is only planned. It applies to the code at the commit pinned in [`VERIFICATION.md`](VERIFICATION.md), running on Solana Devnet.

If something is not in the first table, it does not work today.

## Shipped: works today on Devnet

Each item is in the deployed program or the published app, and has tests or a Devnet transaction behind it.

| Area | What works | Where to check |
|---|---|---|
| Wallet sign-in | Connect and sign with Solflare or Phantom through Mobile Wallet Adapter. The app holds no private key. | `app/lib/core/solana/wallet_adapter.dart` |
| Escrow in SOL | Create and fund, accept, release and review, cancel and refund. | Program tests; Devnet transactions in `VERIFICATION.md` |
| Escrow in tokens | The same lifecycle for USDC (Circle's Devnet USDC) and the project's Devnet test $SKR. | Program tests; Devnet transactions |
| Pay and review together | One instruction releases the funds and records the rating on-chain. | `release_and_review`, `release_and_review_token` |
| Disputes between the two parties | Either party can raise a dispute. Outcomes: release to the worker, refund to the client, or a 50/50 split. A split executes only when one party proposes it and the other accepts. | `raise_dispute`, `propose_split`, `cancel_split_proposal`, `resolve_dispute`, `resolve_token_dispute` |
| On-chain reputation | Worker profiles with job count and rating total, one review record per settled contract, and a lookup screen for any wallet. | `register_worker`, `WorkerProfile`, `Review` |
| Encrypted chat | A chat on each contract, end-to-end encrypted between the two wallets, read-only once the contract settles. | `contract_chat_crypto.dart` and its tests |
| Encrypted deliverables | The worker's submission is encrypted on the phone, with the key wrapped for the client only and a hash to detect changes. | `deliverable_encryption_service.dart`, `key_attestation_service.dart` |
| Seeker verification badge | Reads a wallet's real $SKR Guardian stake from Solana Mobile's staking program on mainnet (read-only) and shows a badge at 250 $SKR or more. Detects Seeker hardware. | `skr_staking.dart` and its tests |
| Offline support | Local cache of contracts and profiles, saved drafts, queued chat messages, and a network check before any transaction. | `app/lib/core/database/`, `network_status.dart` |
| QR codes | Scan wallet addresses, Solana Pay codes and contract links; share a reputation pass. | `qr_scanner_sheet.dart` |
| Live SOL price | An indicative USD figure next to SOL amounts, from Jupiter with CoinGecko as fallback. Display only. | `sol_price_service.dart` |

Limits on the shipped features:

- **Devnet only.** No real funds. The $SKR used in escrow is a test token, because there is no official $SKR on Devnet.
- **Storage of review notes and deliverable files is not permanent yet.** They are uploaded through Irys's Devnet node, which does not keep data for good. The rating itself is on-chain.
- **Chat is not dispute evidence.** Messages are encrypted and tamper-evident between the two parties, but are not individually signed.
- **The app has been run on two Samsung phones.** Seeker hardware detection has not been tested on a Seeker.
- **The published APK is signed with a development key.**

## Built but switched off

The code exists and is deployed or shipped, but it is disabled and cannot be used.

| Item | State | Why it is off |
|---|---|---|
| Juror arbitration (three-juror quorum) | The instructions `initialize_dispute_case`, `cast_juror_vote`, `execute_dispute_ruling` and `execute_token_dispute_ruling` are in the program. Opening a juror case (`initialize_dispute_case`) is refused while `JURY_ENABLED = false`; the vote and ruling instructions need an open case, so no new arbitration can start. The app's juror screens are hidden behind `CLOCKIN_ENABLE_JURY`, which is off. | Jurors are currently chosen by the parties to the dispute, which is not a fair way to select them. It stays off until the protocol selects jurors itself. This path has no test coverage beyond the check that a case cannot be opened. The vote and ruling instructions are not individually gated, so a juror case opened before the switch-off on 8 October 2026 could in principle still be acted on while its contract remains disputed; gating all four is a planned fix. |
| Devnet test-$SKR faucet in the app | Present, but reports itself unavailable unless a build-time secret is supplied. Published builds do not include it. | A build that carries the mint authority would let anyone mint the test token. |

## Planned: not built

None of the following exists in the program or the app today. Where a document or slide mentions one of them, it is describing a plan.

| Item | Status | Notes |
|---|---|---|
| Juror selection from $SKR Guardian stakers | Not built | The step that would let juror arbitration be switched on. No selection logic exists. |
| Protocol fee (1–3%) | Not built | There is no fee, treasury or fee setting anywhere in the program. Every settlement today moves the full amount. |
| Milestone payments | Not built | A contract has one amount and one release. Text in the app that says "milestone" refers to steps in a single contract's lifecycle, not to staged payments. |
| Mainnet deployment | Not done | The program is deployed on Devnet only. The app's only mainnet access is the read-only stake lookup. |
| Security audit | Not done | No third-party audit has been carried out. |
| Multisig upgrade authority | Not done | The program's upgrade authority is a single developer wallet, `GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P`. |
| Solana dApp Store listing | Not done | Needs a release signing key and a submission. |
| Permanent storage for review notes and deliverables | Not done | Needs Irys's mainnet node and funded uploads. |
| Reproducible "Verified Build" and `security.txt` | Not done | The explorer shows the program as not verified. `VERIFICATION.md` gives a direct byte comparison instead. |
| Per-message signatures in chat | Not built | Would make chat usable as dispute evidence. |
| Push notifications for chat messages | Not built | Push exists for contract events only. |
| Paid reputation lookups for third parties | Not built | An idea in the business model, with no code. |
| Weighting reviews against self-dealing | Not built | A review is backed by a settled payment, but nothing yet stops a person paying their own second wallet. |

## How to confirm the split yourself

- **No fee:** search `program/programs/reputation/src/lib.rs` for `fee` or `treasury`; there are no matches.
- **No milestones:** the `EscrowContract` account has a single `amount` and no schedule.
- **Jury off:** `JURY_ENABLED` is `false` at the top of the program, and `initialize_dispute_case` returns `JuryNotEnabled`; the test "opening a juror case is refused while the jury is disabled" covers it.
- **Devnet only:** the program ID in `VERIFICATION.md` exists on Devnet and not on mainnet.
