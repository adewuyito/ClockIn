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

- `program/` — the Anchor program **exists, builds, and is fully tested**. `program/programs/reputation/src/lib.rs` implements **20 instructions**: `register_worker` + `submit_review`, seven native-SOL escrow instructions, three $SKR SPL-token escrow instructions, and eight dispute instructions — across `WorkerProfile`, `Review`, `EscrowContract`, `EscrowVault`, `SplitProposal`, and `DisputeCase` accounts. Disputes settle between the parties; a 50/50 split needs **both** (`propose_split` → the other party accepts). **Juror arbitration is built but disabled** (`JURY_ENABLED = false` on-chain, `CLOCKIN_ENABLE_JURY` in the app) until jurors are protocol-selected — see `docs/ARCHITECTURE.md`. Full test suite (**39 TS tests** via `anchor test`) passes genuinely. Deployed to Solana Devnet at `FKicZKbepmiwj2rTnPrHNRBPAja3G5gSvi7KFkjHdEt9` (slot 506598660, size 539,632 bytes, verified 2026-10-05).

  **Building the program requires regenerating the IDL** — `cargo build-sbf` does not emit one, and a stale `target/idl/reputation.json` makes TS tests fail on instructions the program actually implements. Also note `anchor test` exits 0 even when tests fail. See `docs/ARCHITECTURE.md`.
- `app/` — a production-grade Flutter app targeting Solana Mobile: full core layer (`core/solana/wallet_adapter.dart` — MWA v2.0 connect/sign, zero key custody; `core/solana/contract_service.dart` + `reputation_service.dart`; `core/database/` — Drift SQLite local cache **v13** with `WorkerProfiles`, `Reviews`, `DraftReviews`, `RecentLookups`, `EscrowContracts`, `DraftContracts`, `SeekerAttestations`, `DisputeCases`, `DeliverableSubmissions`, and `UserEncryptionKeys`; `core/providers/app_providers.dart` — reactive Riverpod streams).
- **All Stitch design screens implemented with high fidelity:** Contracts List, Create Contract, Contract Detail, Contract Share, Release & Review Modal, My Profile, Look Up Worker, Worker Profile, Submit Review, Settings & Network.
- **Camera QR Scanner (ClockIn#1 resolved):** Real-time camera viewfinder (`QrScannerSheet`) powered by `mobile_scanner` that parses raw base58 Solana public keys, Solana Pay URIs (`solana:<addr>?amount=...`), and contract deep links across all inputs.
- **Micro-Interactions & Brand Polish:** Custom branded launcher icon across all densities, tactile `HapticFeedback` on selections and settlements, and celebratory spring scale-up with radial sparkle burst (`CelebrationBadge`) upon atomic settlement.
- **Offline Persistence & Recovery:** Full Drift SQLite offline draft recovery sheets for both contracts and reviews.
- `flutter analyze lib/ test/` (0 issues), `flutter test` (**75/75 passing**), and `flutter build apk --release` (**83.1MB**) all verified on 2026-10-05.

  Two caveats on that: analyze the paths explicitly — a bare `flutter analyze` also walks `build/`, where vendored plugin sources produce ~296 spurious errors. And the release APK falls back to the **debug keystore** unless `app/android/key.properties` exists (see `app/android/key.properties.example`); a debug-signed APK cannot be published to the dApp Store or Play.
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
| Network target (MVP) | Solana **Devnet** only — one read-only exception | No mainnet keys, no real funds, and no mainnet *writes* anywhere in this repo. **Single deliberate exception (decided 2026-10-06):** Seeker attestation *reads* a wallet's $SKR Guardian stake from Solana Mobile's mainnet staking program (`SKRskrmt…94BZ`), because that is where real users stake. It is read-only RPC — no keypair, no signing, no transactions. See `app/lib/core/solana/skr_staking.dart` and the "Seeker attestation" section of `docs/ARCHITECTURE.md`. |

## Ground rules

1. **Devnet only until told otherwise.** Never wire in a mainnet keypair or prompt the user for one. The only mainnet access is the read-only $SKR stake lookup for Seeker attestation (see Tech stack) — don't extend mainnet use beyond reads without a fresh, explicit decision.
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
│   └── APP_SPEC.md               ← rewritten — Flutter app spec (several real decisions, 
│                                      e.g. state management and the review-handoff mechanism, 
│                                      deliberately left open for the phase that reaches them, not pre-decided)
├── app/                          ← Flutter project (see Tech stack above)
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
