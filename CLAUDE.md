# ClockIn — Project Context for Claude Code

> Forked from [StellarRep](https://github.com/StellarRep/StellarRep) — same core idea (portable, on-chain reputation for gig/freelance workers), retargeted from Stellar/Soroban/Swift to **Solana Mobile**. The two projects are unrelated going forward; don't cross-reference StellarRep's repos as if they're still part of this one.

## What this is

A mobile-first Solana dApp that gives gig and freelance workers a **portable, on-chain reputation record** — job counts and ratings that live on-chain instead of being locked inside one marketplace's private database. Built for **[CLOCK IN](https://solanamobile.radiant.nexus/)**, a Solana Mobile hackathon run by RadiantsDAO (Sept 8 – Oct 8, $135K in prizes) — a mobile-first, Solana-native dApp is the whole point of the event, so this project's shape follows from that: Android target (Solana Mobile Stack requires it), Mobile Wallet Adapter for signing, an Anchor program for the on-chain state.

## Why this concept carries over

StellarRep's actual insight — reputation portability is worth more than any one marketplace's walled-garden rating system — doesn't depend on which chain it's built on. What changes moving to Solana Mobile:
- **Native iOS/SwiftUI → Flutter.** Solana Mobile Stack (Seeker/Saga, the dApp Store, Mobile Wallet Adapter) is Android-first; Swift can't target Android at all. Flutter gets Android (required) with iOS as a side effect (not the point here).
- **Soroban/Rust contract → Anchor/Rust program.** Same language, different runtime and account model — Solana's account-based storage means the contract design isn't a drop-in port, it needed rethinking; see `docs/PROGRAM_SPEC.md` (renamed from `CONTRACT_SPEC.md`, rewritten for Anchor's account model — notably, no on-chain review-index list, since `getProgramAccounts`+`memcmp` replaces what Soroban needed a `ReviewIds` vector for).
- **stellar-ios-mac-sdk → `solana` (Dart) + `solana_mobile_client`.** The latter is specifically Mobile Wallet Adapter — the actual mechanism by which this app gets a signature without ever holding a private key itself, which is the point of building for Solana *Mobile* specifically rather than just Solana.
- **One thing added that StellarRep didn't have: `drift` local persistence.** An offline-first cache of on-chain state (`WorkerProfiles`, `Reviews`, `DraftReviews` — see `app/lib/core/database/app_database.dart`) so the app is usable with a flaky connection, with pending review drafts that sync once back online. Worth deciding early (Phase 1) how aggressively this cache is trusted vs. always re-verified against the chain.

## Why single-repo, unlike StellarRep

StellarRep split into 4 repos (app/contracts/docs/umbrella) for the Stellar Wave Program's longer-horizon review process. This is a 1-month hackathon with a solo-ish pace — one repo judges can clone and run, less overhead to maintain. Don't split it.

## Current status

**Phase 0, 1, 2 — done. Phase 5/6-shaped app-core work landed ahead of schedule (see caveat below).** What actually exists right now:

- `program/` — the Anchor program **exists, builds, and is fully tested**. `program/programs/reputation/src/lib.rs` implements `register_worker` and `submit_review` per `docs/PROGRAM_SPEC.md` (PDA-based `WorkerProfile`/`Review` accounts, no on-chain review-index list). `program/tests/reputation.ts` — 10 cases via `anchor test`, covering every success and failure path (self-review, duplicate review, invalid rating, oversized `job_id`, the `getProgramAccounts`+`memcmp` read path) — **all pass genuinely**, run as `cargo build-sbf --arch v1 --sbf-out-dir target/deploy` followed by `anchor test --skip-build --validator legacy`. That two-step sequence is not optional — see `docs/ARCHITECTURE.md`'s "Known-bad default build" note: `anchor build`'s own default build step silently produces an unexecutable binary in this environment (every instruction fails with a generic, code-unrelated "Program is not deployed" error), so it must be bypassed with an explicit pre-build. Program keypair generated (ID `FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9`, `declare_id!` set to it; the keypair file `program/reputation-keypair.json` is gitignored — devnet only, regenerate + update `declare_id!` if lost).
- `app/` — a real Flutter app, not just a scaffold: full core layer (`core/solana/wallet_adapter.dart` — MWA connect/sign, zero key custody; `core/solana/reputation_service.dart` — `getWorkerProfile`/`getWorkerReviews`/`registerWorker`/`submitReview` against devnet; `core/solana/network_config.dart`, `account_decoders.dart`, `program_instructions.dart`; `core/database/` — Drift local cache + `reputation_repository.dart`; `core/providers/app_providers.dart` — Riverpod wiring; `core/theme/` — matches the Stitch design direction) plus all 5 screens from the Stitch design (`ConnectWalletScreen`, `MyProfileScreen`, `LookupWorkerScreen`, `SubmitReviewScreen`, `SettingsScreen`), wired together in `main.dart`'s `AppShell` (4-tab nav, wallet-state-aware). State management is **Riverpod** (`flutter_riverpod`), decided during this build (not left open as the original `APP_SPEC.md` draft had it). Android manifest has the MWA intent-filter queries and `INTERNET` permission needed for real-device testing.
- `flutter analyze` (0 issues) and `flutter build apk --debug` both confirmed passing on the real app — closes out Phase 0's last code-side checklist item.
- **Phase 4 (real on-device MWA round-trip) — done, verified on-chain.** `register_worker` signed via Solflare on a physical Android device (SM A515F), submitted to devnet, and confirmed independently by reading the transaction and the resulting `WorkerProfile` PDA straight off devnet RPC (not just trusting the app's own UI): tx succeeded, account exists, owned by the program, correct data length. See `docs/ARCHITECTURE.md`'s "MWA on-device findings" section for what it took to get here — two real, confirmed findings (wallets not reliably returning focus to the app after an MWA flow; and devnet transactions failing until the wallet app's own *active network setting* — separate from anything the dApp requests via MWA's `authorize(cluster:)` — was manually switched to Devnet) plus a real code fix (`ReputationService._signAndSendWithRetry`, retries once with a fresh blockhash on wallet rejection — helps the blockhash-expiry case, though the actual blocker turned out to be the wallet's network setting, not timing). Not yet re-confirmed against Phantom with its network set correctly, or for `submit_review` — both should now work the same way but haven't been separately verified.
- **Not yet verified:** funded devnet keypair (`GBZqhLZXAjBtfeVkVWMYWFN8DGmxskwKna3UEXGvfh8P` — public faucet has been rate-limited on every attempt so far, retry or use faucet.solana.com); devnet deploy via `anchor deploy` specifically (Phase 3's checklist item — the program's been reachable on devnet all along since `declare_id!` points at a real devnet-deployed program ID, but the formal `anchor deploy` + `program/DEPLOYED.md` record hasn't been done).
- **Caveat on phase-ordering:** the roadmap sequences MWA (Phase 4) and program integration (Phase 5) after devnet deploy (Phase 3). In practice Phase 4/5/6-shaped code and now a verified Phase 4 result landed first — that's fine, the loop is proven working end-to-end, but Phase 3's formal record-keeping (a `DEPLOYED.md` with tx hashes) is still worth doing for the submission.
- All docs (`CLAUDE.md`, `docs/ROADMAP.md`, `docs/ARCHITECTURE.md`, `docs/PROGRAM_SPEC.md`, `docs/APP_SPEC.md`, `docs/STITCH_PROMPT.md`) rewritten for ClockIn/Solana Mobile and kept in sync with what's actually built.
- Toolchain: multiple Solana/Agave releases coexist on this machine and which is active can drift between sessions — don't trust a hardcoded version here, re-check with `solana --version`. See `docs/ARCHITECTURE.md` for the AVM proxy quirk, the `anchor test` (TS) vs. Rust-native testing decision, and the `--arch` build requirement.

The 8-phase plan is in `docs/ROADMAP.md` (Mobile Wallet Adapter pulled forward to Phase 4, ahead of full program integration, since it's the hackathon's actual differentiator). Update this section as those phases actually complete.

## Tech stack

| Layer | Choice | Notes |
|---|---|---|
| On-chain program | Rust + `anchor-lang` 1.2.0 | Scaffolded by hand (no `anchor init`), built with `cargo build-sbf --arch v1` (the explicit `--arch` is required — see `docs/ARCHITECTURE.md`). Anchor CLI 1.2.0 (via `avm`) drives `anchor test`/`anchor deploy` against `program/Anchor.toml`; 10/10 tests pass. Versions are a snapshot — re-resolve at build time; if reinstalling Anchor, note its canonical repo has moved orgs before (`otter-sec/anchor` as of last check, not `coral-xyz`/`solana-foundation`). Full toolchain detail + quirks in `docs/ARCHITECTURE.md`. |
| App | Flutter (Dart) + Riverpod | Targets Android primarily (Solana Mobile Stack requirement); other platforms Flutter scaffolds by default (iOS/macOS/Linux/Windows/web) are incidental, not the goal. State management: `flutter_riverpod`. |
| Solana connectivity | [`solana`](https://pub.dev/packages/solana) (Dart RPC/tx SDK) | |
| Wallet / signing | [`solana_mobile_client`](https://pub.dev/packages/solana_mobile_client) | Mobile Wallet Adapter — the app never holds a private key; it asks an installed wallet app (e.g. Phantom, Solflare) to sign via MWA's intent-based protocol. This is the actual "mobile-native" part of the submission, not incidental. |
| Local persistence | [`drift`](https://pub.dev/packages/drift) / `drift_flutter` | Offline-first cache of on-chain state; see the note above on trust/re-verification. |
| Network target (MVP) | Solana **Devnet** only | No mainnet keys, no mainnet program ID, no real funds anywhere in this repo until a deliberate later decision — same discipline as StellarRep's testnet-only rule. |

## Ground rules

1. **Devnet only until told otherwise.** Never wire in a mainnet keypair or prompt the user for one.
2. **Don't trust hardcoded versions/URLs in these docs.** The Solana/Anchor ecosystem moves fast (Anchor's own canonical repo has moved between orgs already). Resolve current versions and repo locations at build time, not from what's written here.
3. **Small, real, and working beats large and mocked.** Same as StellarRep — hackathon judges look for genuine functionality. A 2-instruction Anchor program that actually deploys and a wallet-signed transaction that actually lands on devnet beats a polished UI with no chain behind it.
4. **Mobile-native is the point, not a checkbox.** This hackathon is specifically about Solana *Mobile* — Mobile Wallet Adapter actually working end-to-end (real signing via an installed wallet app, not a hardcoded keypair in the app) is probably worth more to judges than any other single feature.
5. **This doc set is a starting frame, not gospel.** Where reality contradicts what's written here, follow reality and update the doc to match. Stale docs are worse than no docs — this file was itself stale until this rewrite; don't let it happen again.

## Where things live

```
ClockIn/                        (single repo — no split)
├── CLAUDE.md                   ← you are here
├── docs/
│   ├── ROADMAP.md                ← rewritten — fresh 8-phase plan for Anchor + Flutter + the hackathon deadline
│   ├── ARCHITECTURE.md           ← rewritten — Anchor/Flutter/MWA architecture, data flows, non-goals
│   ├── PROGRAM_SPEC.md           ← rewritten — Anchor program spec (renamed from CONTRACT_SPEC.md)
│   └── APP_SPEC.md               ← rewritten — Flutter app spec (several real decisions, e.g. state management and the review-handoff mechanism, deliberately left open for the phase that reaches them, not pre-decided)
├── app/                         ← Flutter project (see Tech stack above)
│   ├── pubspec.yaml
│   ├── lib/
│   │   └── core/database/app_database.dart   ← Drift schema, already started
│   ├── android/                 ← the platform that actually matters for this hackathon
│   └── test/
└── program/                     ← the Anchor program (hand-scaffolded Cargo workspace, no Anchor.toml yet)
    ├── Cargo.toml               ← workspace root
    ├── reputation-keypair.json  ← gitignored — program keypair, devnet only
    └── programs/reputation/
        ├── Cargo.toml
        └── src/lib.rs           ← register_worker + submit_review
```

## Useful external references

- Hackathon: https://solanamobile.radiant.nexus/
- Solana Mobile Stack docs: https://docs.solanamobile.com/
- Mobile Wallet Adapter spec: https://docs.solanamobile.com/mobile-wallet-adapter/overview
- Anchor docs (installation, current version): https://www.anchor-lang.com/docs/installation
- `solana` Dart package: https://pub.dev/packages/solana
- `solana_mobile_client` Dart package: https://pub.dev/packages/solana_mobile_client
- `drift` (Flutter/Dart persistence): https://drift.simonbinder.eu/
