# Roadmap

Eight phases, paced for a ~1-month hackathon (CLOCK IN: Sept 8 – Oct 8) rather than StellarRep's longer Wave Program timeline — fewer, denser phases, and Mobile Wallet Adapter gets pulled forward early (Phase 4, before full program integration) because it's the highest-risk, highest-differentiation piece: a submission where MWA doesn't actually work end-to-end on a real device is a much weaker submission than one with a slightly less polished program, for *this specific* hackathon's judging criteria. Each phase still has a goal, a checklist, and a definition of done — don't move on until done is actually true.

---

## Phase 0 — Tooling & Repo Setup

**Goal:** a working dev environment and a correct-but-empty repo skeleton, single-repo (see `CLAUDE.md` on why this differs from StellarRep's 4-repo split).

- [x] Fork StellarRep into this repo, `app/` reset to a fresh Flutter project with `solana`, `solana_mobile_client`, `drift`/`drift_flutter` dependencies already added.
- [x] Drift schema started (`WorkerProfiles`, `Reviews`, `DraftReviews`) with unit tests.
- [x] Toolchain installed and verified: Solana CLI 4.2.2, `cargo-build-sbf` 4.1.0 / platform-tools v1.54, Anchor CLI 1.2.0 (via `avm`), `anchor-lang` 1.2.0. Quirks (AVM proxy hang, `anchor test` vs Rust-native) documented in `docs/ARCHITECTURE.md`.
- [ ] Create a funded devnet keypair for deploying/testing (`solana-keygen new`, `solana airdrop`, confirm on a devnet explorer).
- [x] Anchor program scaffolded by hand under `program/` (plain Cargo workspace, `anchor-lang` dep, no `anchor init`). `register_worker` + `submit_review` written per `docs/PROGRAM_SPEC.md`; program keypair generated, `declare_id!` set.
- [x] Program builds — `cargo build-sbf` produces a real `target/deploy/reputation.so`. (Note: `anchor build` itself needs an `Anchor.toml`, still to be added — see below.)
- [x] Add an `Anchor.toml` so `anchor build`/`anchor test`/`anchor deploy` have a workspace. This is also the prerequisite for the TS test harness.
- [ ] Confirm Android build tooling: `flutter doctor` clean (or at least Android-relevant checks passing), an Android emulator or physical device available for later MWA testing (**MWA requires a real device or an emulator with a compatible wallet app installed — the iOS Simulator equivalent doesn't exist for MWA flows**, this is a real constraint to plan around).
- [x] `docs/PROGRAM_SPEC.md` and `docs/APP_SPEC.md` rewritten for Anchor/Flutter (PROGRAM_SPEC renamed from `CONTRACT_SPEC.md`).
- [x] Repo hygiene: `.gitignore` covers Flutter/Dart build artifacts, Anchor's `target/`, `.anchor/`, `test-ledger/`, and keypair files; `CLAUDE.md` + `docs/` rewritten and committed.

**Definition of done:** program builds to a deployable `.so` (done, via `cargo build-sbf`), `flutter build apk --debug` (or equivalent) succeeds on the existing Flutter skeleton, and there's a funded devnet keypair with a confirmable balance. Remaining: `Anchor.toml`, the Flutter build check, and the funded devnet keypair.

---

## Phase 1 — Program: Data Model & `register_worker`

The design and the code for this phase are **done** — `docs/PROGRAM_SPEC.md` has the account model (PDA seeds decided, no on-chain review-index list), and `program/programs/reputation/src/lib.rs` implements `register_worker` creating the `WorkerProfile` PDA via `init`. What's left:

- Tests via `anchor test` (TS client + local validator — see `docs/ARCHITECTURE.md` on why not a Rust-native harness): registering once succeeds and the account reads back correctly-initialized; registering twice fails. Confirm the *actual* error Anchor's `init` surfaces on a re-init (likely account-already-in-use, not a custom `AlreadyRegistered`) rather than assuming.
- `Anchor.toml` in place so `anchor test` has a workspace (Phase 0 leftover).

**Done when:** a fresh test run registers a worker and reads back a correctly-initialized account, with no manual steps.

## Phase 2 — Program: Reviews & Reputation Read Path

Also **implemented** — `submit_review` is in `lib.rs` (reviewer-signed, rating bounds, self-review blocked, duplicate blocked structurally via the `review` PDA's `init`). The review-history question is **decided**: no on-chain list; the client uses `getProgramAccounts` + a `memcmp` filter on the `worker` field (see `docs/PROGRAM_SPEC.md`). What's left:

- Tests for every failure path — self-review, duplicate `(worker, job_id)`, invalid rating (0 and 6), not-registered, unsigned reviewer.
- Confirm the client-side read pattern actually works (fetch `WorkerProfile` by PDA; `getProgramAccounts`+`memcmp` for reviews) — verify the `memcmp` offset against the compiled IDL, don't hand-count.

**Done when:** every failure path has a test that actually triggers it, and a full register → review → read-reputation loop passes locally.

## Phase 3 — Devnet Deployment & Manual Verification

- `anchor deploy` to devnet. Record the resulting program ID somewhere durable and non-secret (e.g. `program/DEPLOYED.md`) — never commit a mainnet ID or any secret key.
- Manually invoke register/submit/read against the deployed instance via `anchor run`/a script/`solana program show`; confirm on-chain state actually changes, not just that a CLI command returned success.

**Done when:** a real devnet program ID and a transaction signature for each instruction having been called successfully.

## Phase 4 — App: Mobile Wallet Adapter Integration

**Pulled forward deliberately — see the note at the top of this file.**

- Wire `solana_mobile_client` to request a wallet connection (`authorize`) and confirm it actually round-trips to an installed wallet app on a real device or compatible emulator.
- Request a signature for a trivial transaction (even a no-op/memo instruction) and confirm it lands on devnet — this proves the entire MWA path works before building real feature UI on top of an assumption.
- Handle the realistic failure modes distinctly: no wallet app installed, user rejects the connection, user rejects a specific signature request — these need different UI, not one generic "failed" state.

**Done when:** a real signature, requested via MWA and approved in an actual wallet app, lands as a confirmed transaction on devnet — screenshotted or recorded, since this is worth having proof of for the submission.

## Phase 5 — App: Program Integration

- Wrap the program calls behind a `ReputationService` (same shape as StellarRep's, adapted): `registerWorker`, `submitReview`, `getReputation`, `getReviews`.
- Handle pending/simulating and failed (network vs. program-rejected) states distinctly — same principle as StellarRep's `ContractCallState`, worth porting the pattern even though the underlying SDK differs.
- One real integration test/script: register → submit_review → read reputation, end-to-end against devnet, through this service (not a bypassed raw call).

**Done when:** that end-to-end test passes against live devnet, unattended.

## Phase 6 — Core UI Flows

- Profile screen — look up any address, aggregate rating + job count + review list.
- Submit Review flow — decide the handoff mechanism explicitly (see the note in `docs/ARCHITECTURE.md`'s data-flow section) rather than leaving it vague.
- Wire the Drift local cache in per the trust-model decision made in `docs/ARCHITECTURE.md`.
- Basic empty/error/loading states throughout.

**Done when:** two devices (or a device + emulator with two different wallets) complete a full register → review → view-reputation loop against devnet, with real MWA signing at each write step.

## Phase 7 — Hardening, Docs, Submission

- Real top-level `README.md` — what it is, how to run it, a testnet/devnet-only warning, and (per most hackathon judging norms) a link to a short demo video showing the real MWA-signed flow.
- Seed a small demo dataset on devnet so the app isn't empty on first open for a judge.
- Open well-scoped GitHub issues for the Non-goals in `docs/ARCHITECTURE.md` — mirrors StellarRep's ground rule 4, still worth doing even for a hackathon: it signals the project is thought through past the demo.
- Re-check https://solanamobile.radiant.nexus/ for the actual current submission mechanics (form, required assets, deadline specifics) before the deadline — don't assume the details captured when this roadmap was written are still current.

**Done when:** the repo is submitted per whatever the hackathon's actual submission flow turns out to require.
