# Roadmap

Eight phases, paced for a ~1-month hackathon (CLOCK IN: Sept 8 – Oct 8) rather than StellarRep's longer Wave Program timeline — fewer, denser phases, and Mobile Wallet Adapter gets pulled forward early (Phase 4, before full program integration) because it's the highest-risk, highest-differentiation piece: a submission where MWA doesn't actually work end-to-end on a real device is a much weaker submission than one with a slightly less polished program, for *this specific* hackathon's judging criteria. Each phase still has a goal, a checklist, and a definition of done — don't move on until done is actually true.

---

## Phase 0 — Tooling & Repo Setup

**Goal:** a working dev environment and a correct-but-empty repo skeleton, single-repo (see `CLAUDE.md` on why this differs from StellarRep's 4-repo split).

- [x] Fork StellarRep into this repo, `app/` reset to a fresh Flutter project with `solana`, `solana_mobile_client`, `drift`/`drift_flutter` dependencies already added.
- [x] Drift schema started (`WorkerProfiles`, `Reviews`, `DraftReviews`) with unit tests.
- [ ] Confirm Rust toolchain, then install Solana CLI (`solana --version`) and Anchor via AVM (`avm install latest && avm use latest`, then `anchor --version`) — verify current install commands against https://www.anchor-lang.com/docs/installation rather than trusting a hardcoded command; the canonical Anchor repo has moved between GitHub orgs before.
- [ ] Create a funded devnet keypair for deploying/testing (`solana-keygen new`, `solana airdrop`, confirm on a devnet explorer).
- [ ] Scaffold the Anchor program workspace under `program/` (`anchor init` or manual `Cargo.toml` workspace — check `anchor init --help` first, similar caution to how `stellar contract init` needed checking in StellarRep).
- [ ] Build the empty scaffolded program (`anchor build`) before writing any real logic.
- [ ] Confirm Android build tooling: `flutter doctor` clean (or at least Android-relevant checks passing), an Android emulator or physical device available for later MWA testing (**MWA requires a real device or an emulator with a compatible wallet app installed — the iOS Simulator equivalent doesn't exist for MWA flows**, this is a real constraint to plan around).
- [x] `docs/PROGRAM_SPEC.md` rewritten for Anchor's account model (renamed from `CONTRACT_SPEC.md`). `docs/APP_SPEC.md` still needs a Flutter rewrite — still StellarRep's Swift spec as of this roadmap update.
- [ ] Repo hygiene: `.gitignore` covers Flutter/Dart build artifacts, Anchor's `target/`, `.anchor/`, test-ledger dirs; confirm `CLAUDE.md` + `docs/` are committed and accurate.

**Definition of done:** `anchor build` succeeds on an empty scaffolded program, `flutter build apk --debug` (or equivalent) succeeds on the existing Flutter skeleton, and there's a funded devnet keypair with a confirmable balance.

---

## Phase 1 — Program: Data Model & `register_worker`

- Define the account structures — a worker's reputation account, at minimum. Anchor's account model differs from Soroban's key-value storage: decide the PDA (program-derived address) seed scheme now (e.g. seed off the worker's wallet pubkey) since it shapes every instruction after this.
- Implement `register_worker`, creating the account via Anchor's `init` constraint.
- Unit/integration tests (Anchor's `anchor test` running against a local validator, or `solana-program-test`): registering once succeeds; registering twice fails (Anchor's `init` constraint should already reject a re-init at the same PDA — confirm this is the actual behavior, don't assume).
- `anchor build` succeeds; tests pass.

**Done when:** a fresh test run registers a worker and reads back a correctly-initialized account, with no manual steps.

## Phase 2 — Program: Reviews & Reputation Read Path

- Implement `submit_review` — signed by the reviewer (not the worker), rating bounds checked, self-review blocked (`reviewer.key() != worker`), duplicate job reference blocked (decide the account/PDA scheme for this — e.g. a PDA seeded off worker + job reference, whose existence itself blocks duplicates, similar in spirit to Soroban's `DataKey::Review(worker, job_id)`).
- Reputation is readable directly from the worker's account (Anchor accounts are queryable via RPC without a dedicated "read" instruction) — confirm the client-side fetch pattern works before assuming.
- Reviews: decide whether to store a full on-chain list (costs rent, grows unbounded) or emit events/logs the client indexes off-chain into Drift (cheaper, but means the "source of truth" for review *history* becomes client-reconstructed rather than always chain-queryable) — this is a real design decision the Soroban version didn't have to make the same way (its `ReviewIds` vec approach doesn't map cleanly to Solana's rent model at scale). Document the choice and why once made.
- Tests for every failure path — self-review, duplicate, invalid rating, not-registered.

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
