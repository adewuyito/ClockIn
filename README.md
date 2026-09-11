# ClockIn

A mobile-first Solana dApp that gives gig and freelance workers a **portable, on-chain reputation record** — job counts and star ratings that live on a Solana program instead of being locked inside one marketplace's private database. Built for **[CLOCK IN](https://solanamobile.radiant.nexus/)**, a Solana Mobile hackathon run by RadiantsDAO.

Reputation portability is the actual idea: a worker's history should follow them between gig platforms, not reset to zero every time they switch apps.

## How it works

- **Register once, on-chain.** A worker signs a single transaction (via Mobile Wallet Adapter — no private key ever touches this app) to create a `WorkerProfile` account on Solana.
- **Anyone else reviews them.** A client or collaborator submits a signed, 1–5 star rating tied to a specific job reference. The program rejects self-reviews and duplicate reviews for the same job.
- **Reputation is just arithmetic over public accounts.** Average rating = `rating_sum / total_jobs`, both fields read directly off the worker's on-chain account — no backend, no database, no trusted intermediary.

## Status

Devnet-only MVP. The Anchor program is deployed and live (see [`program/DEPLOYED.md`](program/DEPLOYED.md) for the program ID, deploy transaction, and what's been verified on a physical device so far). The Flutter app implements every screen from the project's Stitch design except one (QR/deep-link worker handoff — tracked as [issue #1](https://github.com/adewuyito/ClockIn/issues/1); pasting an address works today).

For the full build log, phase-by-phase status, and every real engineering decision made along the way, see [`CLAUDE.md`](./CLAUDE.md).

## Repo layout

```
program/    Anchor program (Rust) — register_worker, submit_review, on-chain accounts
app/        Flutter app (Android-first) — MWA wallet connect, Riverpod state, Drift offline cache
docs/       ARCHITECTURE.md, PROGRAM_SPEC.md, APP_SPEC.md, ROADMAP.md, STITCH_PROMPT.md
```

## Running it

**Program** (requires the Solana CLI + Anchor CLI):
```
cd program
mkdir -p target/deploy && cp reputation-keypair.json target/deploy/
cargo build-sbf --arch v1 --sbf-out-dir target/deploy   # anchor build's own default step produces a non-executable binary here — see docs/ARCHITECTURE.md
anchor test --skip-build --validator legacy             # 10/10 tests
```

**App** (requires Flutter + an Android device or emulator — Mobile Wallet Adapter has no iOS Simulator equivalent, and needs a real MWA-compatible wallet app like Phantom or Solflare installed):
```
cd app
flutter pub get
flutter test          # 10/10 tests
flutter run           # make sure your wallet app's own network setting is Devnet, not Mainnet — see below
```

> **Before connecting a wallet:** set the wallet app's own active network to **Devnet** in its own settings screen. MWA's `authorize(cluster:)` request is advisory — the wallet's own network setting is what actually governs whether a devnet transaction is accepted. This tripped up testing during this build (see `docs/ARCHITECTURE.md`'s "MWA on-device findings") and will trip up anyone trying this for the first time with a freshly-installed wallet, which defaults to Mainnet.

## What this doesn't do (on purpose, for now)

- **No worker identity (name/photo).** `WorkerProfile` stores a pubkey and numbers, nothing identity-shaped. Staying pseudonymous was a deliberate call, not an oversight — see `docs/ARCHITECTURE.md`'s Non-goals section for the reasoning and the real options if this changes later.
- **No dispute resolution.** A submitted review is permanent; there's no retraction path.
- **Sybil resistance is signature-based, not stake-based.** A review only counts if it's signed by an address distinct from the worker's, tied to a unique job reference — this blocks self-review but not collusion between two real accounts fabricating a fake job. That's a harder problem, explicitly out of scope for this MVP.
- **Devnet only.** No mainnet program ID, no mainnet keys, anywhere in this repo.

See `docs/ARCHITECTURE.md`'s Non-goals section for the complete list and the reasoning behind each.
